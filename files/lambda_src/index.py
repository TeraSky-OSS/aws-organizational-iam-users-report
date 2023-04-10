import json
import logging
import boto3
import os
import csv
import tempfile
from botocore.exceptions import ClientError
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.application import MIMEApplication

logging.basicConfig(format='%(asctime)s %(levelname)-8s %(message)s', datefmt='%Y-%m-%d %H:%M:%S')
logger = logging.getLogger()
logger.setLevel(logging.INFO)

ASSUME_ROLE_NAME = os.environ.get('ASSUME_ROLE_NAME', 'OrganizationIAMUsersReportLambda')
AWS_REGION = os.environ.get('AWS_REGION')
EMAIL_SENDER = os.environ.get('EMAIL_SENDER')
EMAIL_RECIPIENTS = os.environ.get('EMAIL_RECIPIENTS')
GENERATED_FILE_NAME = 'iam_users_report.csv'

org_client = boto3.client('organizations')
sts_client = boto3.client('sts')


def send_email(sender, recipient, subject, body, file_path):
    # The character encoding for the email.
    CHARSET = "utf-8"

    # Create a new SES resource and specify a region.
    client = boto3.client('sesv2', region_name=AWS_REGION)

    # Create a multipart/mixed parent container.
    msg = MIMEMultipart('mixed')

    # Add subject, from and to lines.
    msg['Subject'] = subject
    msg['From'] = sender
    msg['To'] = recipient

    # Create a multipart/alternative child container.
    msg_body = MIMEMultipart('alternative')

    # Encode the text and HTML content and set the character encoding.
    htmlpart = MIMEText(body.encode(CHARSET), 'html', CHARSET)

    # Add the HTML part to the child container.
    msg_body.attach(htmlpart)

    # Define the attachment part and encode it using MIMEApplication.
    att = MIMEApplication(open(file_path, 'rb').read())

    # Add a header to tell the email client to treat this part as an attachment,
    # and to give the attachment a name.
    att.add_header('Content-Disposition', 'attachment', filename=os.path.basename(file_path))

    # Attach the multipart/alternative child container to the multipart/mixed parent container.
    msg.attach(msg_body)

    # Add the attachment to the parent container.
    msg.attach(att)

    try:
        # Provide the contents of the email.
        response = client.send_email(
            FromEmailAddress=sender,
            Destination={'ToAddresses': [recipient]},
            Content={
              'Raw': {
                'Data': msg.as_string()
              }
            },
        )
    # Display an error if something goes wrong.
    except ClientError as e:
        logger.error(e.response['Error']['Message'])
    else:
        logger.info(f'Email sent! Message ID: {response["MessageId"]}')


def lambda_handler(event, context):
    credential_report_headers = "" # Will be defined after getting the first credentials report
    credential_report_content = []

    # Get all accounts in the organization
    logger.info('Getting all AWS accounts in the organization')
    all_accounts = []
    org_list_accounts_paginator = org_client.get_paginator("list_accounts")
    org_list_accounts_iterator = org_list_accounts_paginator.paginate()
    for page in org_list_accounts_iterator:
        all_accounts += [account['Id'] for account in page['Accounts'] if account['Status'] == 'ACTIVE']

    # Loop through all accounts
    for account in all_accounts:
        try:
            logger.info(f'Checking IAM users in account {account}')

            # Assume a role in the member account
            creds = sts_client.assume_role(
                RoleArn=f"arn:aws:iam::{account}:role/{ASSUME_ROLE_NAME}",
                RoleSessionName="cross_acct_lambda"
            )

            access_key = creds['Credentials']['AccessKeyId']
            secret_key = creds['Credentials']['SecretAccessKey']
            session_token = creds['Credentials']['SessionToken']

            # Create a boto3 client in the member account
            iam_client = boto3.client(
                'iam',
                aws_access_key_id=access_key,
                aws_secret_access_key=secret_key,
                aws_session_token=session_token,
            )

            # Generate credentials report
            logger.info('Generating IAM credentials report...')
            iam_client.generate_credential_report()
            credential_report = iam_client.get_credential_report()
            credential_report_headers = credential_report['Content'].decode("utf-8").split("\n")[0]

            # Convert each line to list of strings
            for line in credential_report['Content'].decode("utf-8").split("\n")[1:]:
                credential_report_content.append(line.split(','))

        except Exception as e:
            logger.error(f'Failed to check account {account}. Error: {e}')

    # Create temp dir for CSV
    tempdir = tempfile.mkdtemp()
    path = os.path.join(tempdir)

    # Write data to CSV
    logger.info('Writing data to CSV...')
    with open(path + f'/{GENERATED_FILE_NAME}', 'w', encoding='UTF8', newline='') as f:
        writer = csv.writer(f)

        # write the header
        writer.writerow(credential_report_headers.split(','))

        # write multiple rows
        writer.writerows(credential_report_content)
    
    with open('email_body.html', 'r') as file:
        email_body = file.read()
        email_subject = 'AWS Organization IAM Users Credentials Report'

        for email_recipient in EMAIL_RECIPIENTS.split(','):
            send_email(EMAIL_SENDER, email_recipient, email_subject, email_body, path + f'/{GENERATED_FILE_NAME}')

    return {
        'statusCode': 200,
        'body': json.dumps('Success!')
    }
