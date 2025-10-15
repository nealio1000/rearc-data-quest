# Define the AWS provider
provider "aws" {
  region = "us-east-1"
}

# Define the S3 bucket resource
resource "aws_s3_bucket" "rearc_data_bucket" {
  bucket = "rearc-quest-data-bucket"
  acl    = "private"                     

  # Enable versioning for the bucket
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