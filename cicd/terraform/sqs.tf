resource "aws_sqs_queue" "processed_data_notification_queue" {
  name                       = "processed-data-notification-queue"
  message_retention_seconds  = 86400 # 1 day
  visibility_timeout_seconds = 500
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.processed_data_notification_dlq.arn
    maxReceiveCount     = 5
  })
}

resource "aws_sqs_queue" "processed_data_notification_dlq" {
  name = "s3-file-notification-dlq"
}

resource "aws_sqs_queue_policy" "processed_data_notification_queue_policy" {
  queue_url = aws_sqs_queue.processed_data_notification_queue.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = { Service = "s3.amazonaws.com" },
        Action    = "SQS:SendMessage",
        Resource  = aws_sqs_queue.processed_data_notification_queue.arn,
        Condition = {
          ArnEquals = { "aws:SourceArn" = aws_s3_bucket.processed_data_bucket.arn }
        }
      }
    ]
  })
}