resource "aws_s3_bucket" "rearc_data_bucket" {
  bucket = "rearc-quest-data-bucket"
  acl    = "private"                     

  versioning {
    enabled = true
  }

  tags = {
    Environment = "Development"
    Project     = "RearcDataQuest"
  }
}

output "s3_bucket_arn" {
  value = aws_s3_bucket.rearc_data_bucket.arn
}