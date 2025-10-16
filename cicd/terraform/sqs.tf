# Define a standard SQS queue
resource "aws_sqs_queue" "main_queue" {
  name                       = "my-terraform-sqs-queue"
  delay_seconds              = 0
  max_message_size           = 262144 # 256KB
  message_retention_seconds  = 345600 # 4 days
  receive_wait_time_seconds  = 0
  visibility_timeout_seconds = 30

  # Configure the redrive policy to use the dead-letter queue
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter_queue.arn
    maxReceiveCount     = 5 # Number of times a message can be received before moving to DLQ
  })

  tags = {
    Environment = "Development"
    Purpose     = "TerraformExample"
  }
}

# Define the Dead-Letter Queue (DLQ)
resource "aws_sqs_queue" "dead_letter_queue" {
  name = "my-terraform-sqs-dead-letter-queue"

  tags = {
    Environment = "Development"
    Purpose     = "DeadLetterQueue"
  }
}

# Output the ARN and URL of the main queue
output "main_queue_arn" {
  value       = aws_sqs_queue.main_queue.arn
  description = "The ARN of the main SQS queue."
}

output "main_queue_url" {
  value       = aws_sqs_queue.main_queue.id
  description = "The URL of the main SQS queue."
}

# Output the ARN and URL of the dead-letter queue
output "dead_letter_queue_arn" {
  value       = aws_sqs_queue.dead_letter_queue.arn
  description = "The ARN of the dead-letter SQS queue."
}

output "dead_letter_queue_url" {
  value       = aws_sqs_queue.dead_letter_queue.id
  description = "The URL of the dead-letter SQS queue."
}