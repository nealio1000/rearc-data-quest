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

resource "aws_s3_bucket_acl" "rearc_data_bucket_acl" {
  bucket = aws_s3_bucket.rearc_data_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "rearc_data_bucket_versioning" {
  bucket = aws_s3_bucket.rearc_data_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}


output "s3_bucket_arn" {
  value = aws_s3_bucket.rearc_data_bucket.arn
}