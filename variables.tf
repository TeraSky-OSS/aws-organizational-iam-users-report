variable "aws_region" {
  description = "AWS Region to deploy all resources"
  type        = string
  default     = "us-east-1"
}

variable "assume_role_arn" {
  description = "ARN of the IAM Role to assume in the member account"
  type        = string
  default     = null
}

variable "default_tags" {
  description = "Tags to apply across all resources handled by this provider"
  type        = map(string)
  default = {
    Terraform = "True"
  }
}

variable "project_name" {
  description = "Name of the tool/project"
  type        = string
  default     = "organizational-iam-users-report"
}

variable "function_description" {
  description = "Description of the Lambda function"
  type        = string
  default     = "Lambda function to send a report of all IAM users in the organization"
}

variable "function_iam_policies" {
  description = "List of IAM managed policies to attach to the Lambda function"
  type        = list(string)
  default = [
    "arn:aws:iam::aws:policy/AWSOrganizationsReadOnlyAccess",
    "arn:aws:iam::aws:policy/AmazonSESFullAccess"
  ]
}

variable "function_timeout" {
  description = "The amount of time your Lambda Function has to run in seconds"
  type        = number
  default     = 60
}

variable "email_sender" {
  description = "Email address from which the emails will be recieved (the format is: email@example.com <email@example.com>)"
  type        = string
  default     = "daniel@terasky.com <daniel@terasky.com>"
}

variable "email_recipients" {
  description = "Email addresses of recipients (comma separated)"
  type        = string
  default     = "danielvaknin10@gmail.com"
}

variable "event_cron" {
  description = "Cron value for the EventBridge rule"
  type        = string
  default     = "cron(0 10 3 * ? *)"
}

variable "function_assume_role_name" {
  description = "Name of IAM role that will be created in all member accounts, and will be assumed by the Lambda function"
  type        = string
  default     = "OrganizationIAMUsersReportLambda"
}

variable "deploy_to_organization" {
  description = "Whether to deploy the automation to the main OU of the organization (all AWS accounts in the organization)"
  type        = bool
  default     = true
}

variable "include_organizational_units" {
  description = "List of AWS organizational unit IDs to include and deploy the automation to (if `deploy_to_organization` is set to `false`)"
  type        = list(string)
  default     = []
}