resource "aws_s3_bucket" "raw_data_bucket" {
  bucket = "rearc-quest-raw-data-bucket"
}

resource "aws_s3_bucket" "processed_data_bucket" {
  bucket = "rearc-quest-processed-data-bucket"
}

resource "aws_s3_bucket" "artifacts_bucket" {
  bucket = "rearc-quest-artifacts"
}

resource "aws_s3_bucket_notification" "processed_data_s3_to_sqs_notification" {
  bucket = aws_s3_bucket.processed_data_bucket.id

  queue {
    queue_arn = aws_sqs_queue.processed_data_notification_queue.arn
    events    = ["s3:ObjectCreated:*"]
    filter_suffix = ".json"
  }
}

