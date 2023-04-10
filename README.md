# AWS Organizational IAM Users Report

The AWS Organizational IAM Users Report tool will help you generate a report of all IAM users in your AWS organization, including their last activity, password age, and more.

Although the tool is being deployed with Terraform, the Terraform module will also deploy a set of resources with CloudFormation StackSets as there is a limitation with Terraform ("dynamic providers")

The following resources are being created as part of this module:
- Lambda function in the management account
- EventBridge event rule in the management account
- CloudFormation StackSet that deploys the following resources to in each chosen member account:
  - IAM role

## Example Usage

Run the following command to generate the basic `terraform.tfvars` file:

```bash
cat <<EOF > terraform.tfvars
deploy_to_organization = false
include_organizational_units = ["ou-s8qf-092b7iur"]
EOF
```

Then, to deploy the resources, simply run `terraform apply`

The above example will deploy the automation to all accounts under the `ou-s8qf-092b7iur` organizational unit (OU).

You can modify the above command (or the generated `terraform.tfvars` file) to deploy to your specified OUs.

You can also deploy the automation to the entire organization (all accounts) by specifying `deploy_to_organization = true`.

> **Note:** You must configure your console credentials with proper permissions on the management account of your AWS organization

## Known Issues

In some cases, running `terraform destroy` might fail (for example if there is a `suspended` account in the organization). If this happens, You'll need to delete all Stack Instances from the CloudFormation StackSet manually through AWS console. Perform the following:
1. Login to the **management account** of your AWS organization
2. Go to **CloudFormation** service
3. Go to **StackSets**
4. Click on the stuck StackSet (starting with `organizational-events-notifier`)
5. Click on **Actions** and choose **Delete stacks from StackSet**
6. For **AWS OU ID** provide  one of the following:
   - If deployed the automation to the entire organization, provide the ID of your organization (for example: `r-s8qf`)
   - If deployed the automation to specific organizational units (OUs), provide the ID of all OUs
7. For **Specify regions** click on **Add all regions**
8. Under **Deployment options**, use the following values:
   - Maximum concurrent accounts: `Percentage` - `100`
   - Failure tolerance: `Percentage` - `100`
   - Region Concurrency: `Parallel`
9.  Keep all other default values
10. Proceed to delete the StackSet Instances
11. In the StackSet page, go to **Stack Instances** tab and make sure that it's empty
12. Run `terraform destroy` again to delete all other resources

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.59 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | 2.3.0 |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.62.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_lambda_function"></a> [lambda\_function](#module\_lambda\_function) | terraform-aws-modules/lambda/aws | ~> 4.13 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudformation_stack_set.iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudformation_stack_set) | resource |
| [aws_cloudformation_stack_set_instance.iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudformation_stack_set_instance) | resource |
| [aws_cloudwatch_event_rule.weekly](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.lambda_function](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_ses_email_identity.recipients](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ses_email_identity) | resource |
| [archive_file.lambda_function](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_organizations_organization.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_organization) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_assume_role_arn"></a> [assume\_role\_arn](#input\_assume\_role\_arn) | ARN of the IAM Role to assume in the member account | `string` | `null` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS Region to deploy all resources | `string` | `"us-east-1"` | no |
| <a name="input_default_tags"></a> [default\_tags](#input\_default\_tags) | Tags to apply across all resources handled by this provider | `map(string)` | <pre>{<br>  "Terraform": "True"<br>}</pre> | no |
| <a name="input_deploy_to_organization"></a> [deploy\_to\_organization](#input\_deploy\_to\_organization) | Whether to deploy the automation to the main OU of the organization (all AWS accounts in the organization) | `bool` | `true` | no |
| <a name="input_email_recipients"></a> [email\_recipients](#input\_email\_recipients) | Email addresses of recipients (comma separated) | `string` | n/a | yes |
| <a name="input_email_sender"></a> [email\_sender](#input\_email\_sender) | Email address from which the emails will be recieved (the format is: email@example.com <email@example.com>) | `string` | n/a | yes |
| <a name="input_event_cron"></a> [event\_cron](#input\_event\_cron) | Cron value for the EventBridge rule | `string` | `"cron(0 10 * * ? 0)"` | no |
| <a name="input_function_assume_role_name"></a> [function\_assume\_role\_name](#input\_function\_assume\_role\_name) | Name of IAM role that will be created in all member accounts, and will be assumed by the Lambda function | `string` | `"OrganizationIAMUsersReportLambda"` | no |
| <a name="input_function_description"></a> [function\_description](#input\_function\_description) | Description of the Lambda function | `string` | `"Lambda function to send a report of all IAM users in the organization"` | no |
| <a name="input_function_timeout"></a> [function\_timeout](#input\_function\_timeout) | The amount of time your Lambda Function has to run in seconds | `number` | `60` | no |
| <a name="input_include_organizational_units"></a> [include\_organizational\_units](#input\_include\_organizational\_units) | List of AWS organizational unit IDs to include and deploy the automation to (if `deploy_to_organization` is set to `false`) | `list(string)` | `[]` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Name of the tool/project | `string` | `"organizational-iam-users-report"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->