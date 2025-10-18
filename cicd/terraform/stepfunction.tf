
# IAM Role for the Step Function
resource "aws_iam_role" "step_function_role" {
  name = "my-step-function-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
      },
    ]
  })
}

# IAM Policy for the Step Function (e.g., to invoke a Lambda)
resource "aws_iam_role_policy" "step_function_policy" {
  name = "my-step-function-policy"
  role = aws_iam_role.step_function_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "lambda:InvokeFunction"
        Resource = "arn:aws:lambda:us-east-1:123456789012:function:my-lambda-function" # Replace with your Lambda ARN
      },
      # Add other necessary permissions here
    ]
  })
}

# State Machine Definition (Amazon States Language - ASL)
# This example uses a simple Pass state, but you would define your workflow here.
locals {
  state_machine_definition = jsonencode({
    Comment = "A simple example state machine"
    StartAt = "HelloWorld"
    States = {
      HelloWorld = {
        Type = "Pass"
        Result = "Hello from Step Functions!"
        End = true
      }
    }
  })
}

# AWS Step Functions State Machine
resource "aws_sfn_state_machine" "my_state_machine" {
  name       = "MySimpleStateMachine"
  role_arn   = aws_iam_role.step_function_role.arn
  definition = local.state_machine_definition
  type       = "STANDARD" # Or "EXPRESS"
}

output "state_machine_arn" {
  value = aws_sfn_state_machine.my_state_machine.arn
}