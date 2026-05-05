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