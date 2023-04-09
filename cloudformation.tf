resource "aws_cloudformation_stack_set" "iam_role" {
  name             = "${var.project_name}-iam-role"
  description      = "CloudFormation StackSet that deploys the relevant IAM role in each account"
  template_body    = file("./files/iam_role_cf_template.yaml")
  permission_model = "SERVICE_MANAGED"

  capabilities = ["CAPABILITY_NAMED_IAM"]

  auto_deployment {
    enabled                          = true
    retain_stacks_on_account_removal = false
  }

  parameters = {
    AutomationAccountId = data.aws_caller_identity.current.account_id
    RoleName            = var.function_assume_role_name
  }

  operation_preferences {
    failure_tolerance_percentage = 100
    max_concurrent_percentage    = 100
    region_concurrency_type      = "PARALLEL"
  }

  lifecycle {
    ignore_changes = [
      # Ignoring the change of "administration_role_arn" as StackSet with auto_deployment gets administration_role_arn during refresh, resulting in update loop
      # https://github.com/hashicorp/terraform-provider-aws/issues/23464
      administration_role_arn
    ]
  }
}

resource "aws_cloudformation_stack_set_instance" "iam_role" {
  stack_set_name = aws_cloudformation_stack_set.iam_role.name
  region         = var.aws_region

  deployment_targets {
    organizational_unit_ids = var.deploy_to_organization ? [data.aws_organizations_organization.current.roots[0].id] : var.include_organizational_units
  }

  operation_preferences {
    failure_tolerance_percentage = 100
    max_concurrent_percentage    = 100
    region_concurrency_type      = "PARALLEL"
  }
}