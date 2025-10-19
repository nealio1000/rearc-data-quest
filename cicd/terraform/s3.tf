resource "aws_s3_bucket" "raw_data_bucket" {
  bucket = "rearc-quest-raw-data-bucket"
}

resource "aws_s3_bucket" "proccessed_data_bucket" {
  bucket = "rearc-quest-proccessed-data-bucket"
}

resource "aws_s3_bucket" "artifacts_bucket" {
  bucket = "rearc-quest-artifacts"
}

resource "aws_s3_bucket_notification" "proccessed_data_s3_to_sqs_notification" {
  bucket = aws_s3_bucket.proccessed_data_bucket.id

  queue {
    queue_arn = aws_sqs_queue.proccesed_data_notification_queue.arn
    events    = ["s3:ObjectCreated:*"]
    filter_suffix = ".json"
  }
}

