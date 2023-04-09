data "archive_file" "lambda_function" {
  type        = "zip"
  source_dir  = "${path.module}/files/lambda_src"
  output_path = "${path.module}/files/code.zip"
}

module "lambda_function" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 4.13"

  function_name = var.project_name
  description   = var.function_description
  handler       = "index.lambda_handler"
  runtime       = "python3.9"
  publish       = true
  timeout       = var.function_timeout

  create_package         = false
  local_existing_package = data.archive_file.lambda_function.output_path

  attach_policies    = true
  policies           = var.function_iam_policies
  number_of_policies = length(var.function_iam_policies)

  attach_policy_json = true
  policy_json        = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": ["*"]
        }
    ]
}
EOF

  environment_variables = {
    ASSUME_ROLE_NAME = var.function_assume_role_name
    EMAIL_SENDER     = var.email_sender
    EMAIL_RECIPIENTS = var.email_recipients
  }

  allowed_triggers = {
    WeeklyRule = {
      principal  = "events.amazonaws.com"
      source_arn = aws_cloudwatch_event_rule.weekly.arn
    }
  }
}

resource "aws_cloudwatch_event_rule" "weekly" {
  name                = "${var.project_name}-run-weekly"
  description         = "Generate a report of all IAM users in the organization every week"
  schedule_expression = var.event_cron
}

resource "aws_cloudwatch_event_target" "lambda_function" {
  rule = aws_cloudwatch_event_rule.weekly.name
  arn  = module.lambda_function.lambda_function_arn
}

resource "aws_ses_email_identity" "recipients" {
  for_each = toset(split(",", var.email_recipients))

  email = each.key
}