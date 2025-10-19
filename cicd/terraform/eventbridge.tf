# EventBridge Scheduler to run Step Function daily
resource "aws_scheduler_schedule" "daily_sfn_schedule" {
  name = "daily-sfn-trigger"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "cron(0 8 * * *)" # Runs daily at 08:00

  target {
    arn      = aws_sfn_state_machine.daily_fetch_data_state_machine.arn
    role_arn = aws_iam_role.eventbridge_scheduler_role.arn
    input    = jsonencode({"message": "Triggered by daily schedule"})
  }
}