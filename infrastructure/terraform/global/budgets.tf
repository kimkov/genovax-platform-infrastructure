resource "aws_budgets_budget" "monthly_limit" {
  name = "monthly-budget-limit"
  budget_type = "COST"
  limit_unit   = "USD"
  limit_amount = "1000"
  time_unit = "MONTHLY"

  # Notification upon reaching 80% of actual costs
  notification {
    comparison_operator = "GREATER_THAN"
    notification_type   = "ACTUAL"
    threshold           = 80
    threshold_type      = "PERCENTAGE"
    subscriber_email_addresses = [var.billing_notification_email]
  }

  # Notification when the forecast exceeds the budget by 100%
  notification {
    comparison_operator = "GREATER_THAN"
    notification_type   = "FORECASTED"
    threshold           = 100
    threshold_type      = "PERCENTAGE"
    subscriber_email_addresses = [var.billing_notification_email]
  }
}

# RDS budget
resource "aws_budgets_budget" "rds_monthly_limit" {
  name = "rds-monthly-budget-limit"
  budget_type = "COST"
  limit_unit   = "USD"
  limit_amount = "200"
  time_unit = "MONTHLY"

  cost_filter {
    name = "Service"
    values = ["Amazon Relational Database Service"]
  }

  notification {
    comparison_operator = "GREATER_THAN"
    notification_type   = "ACTUAL"
    threshold           = 80
    threshold_type      = "PERCENTAGE"
    subscriber_email_addresses = [var.billing_notification_email]
  }
}

# EKS budget
resource "aws_budgets_budget" "eks_monthly_limit" {
  name = "eks-monthly-budget-limit"
  budget_type = "COST"
  limit_unit   = "USD"
  limit_amount = "300"
  time_unit = "MONTHLY"

  cost_filter {
    name = "Service"
    values = ["Amazon Elastic Kubernetes Service"]
  }

  notification {
    comparison_operator = "GREATER_THAN"
    notification_type   = "ACTUAL"
    threshold           = 90
    threshold_type      = "PERCENTAGE"
    subscriber_email_addresses = [var.billing_notification_email]
  }
}