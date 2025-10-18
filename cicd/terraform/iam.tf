# Create an IAM role for the Lambda function
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
    }],
  })
}

data "aws_iam_policy_document" "lambda_policy_doc" {
  statement {
    sid = "AllowInvokingLambdas"
    effect = "Allow"

    resources = [
      "arn:aws:lambda:*:*:function:*"
    ]

    actions = [
      "lambda:InvokeFunction"
    ]
  }

  statement {
    sid = "AllowCreatingLogGroups"
    effect = "Allow"

    resources = [
      "arn:aws:logs:*:*:*"
    ]

    actions = [
      "logs:CreateLogGroup"
    ]
  }

  statement {
    sid = "AllowWritingLogs"
    effect = "Allow"

    resources = [
      "arn:aws:logs:*:*:log-group:/aws/lambda/*:*"
    ]

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
  }

  statement {
    sid = "S3Write"
    effect = "Allow"
    resources = [
      "${aws_s3_bucket.rearc_data_bucket.arn}/population",
      "${aws_s3_bucket.rearc_data_bucket.arn}/population/*",
      "${aws_s3_bucket.rearc_data_bucket.arn}/bls-data",
      "${aws_s3_bucket.rearc_data_bucket.arn}/bls-data/*",
    ]
    actions = [
      "s3:PutObject",
      "s3:ListBucket"
    ]
  }
}

resource "aws_iam_policy" "lambda_iam_policy" {
  name = "lambda_iam_policy"
  policy = data.aws_iam_policy_document.lambda_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  policy_arn = aws_iam_policy.lambda_iam_policy.arn
  role = aws_iam_role.lambda_exec_role.name
}

data "aws_iam_policy_document" "emr_serverless_policy_doc" {
  statement {
    sid = "S3ReadWrite"
    effect = "Allow"
    resources = [
      "${aws_s3_bucket.rearc_data_bucket.arn}/population",
      "${aws_s3_bucket.rearc_data_bucket.arn}/population/*",
      "${aws_s3_bucket.rearc_data_bucket.arn}/bls-data",
      "${aws_s3_bucket.rearc_data_bucket.arn}/bls-data/*",
    ]
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject"
    ]
  }
}

resource "aws_iam_role" "emr_serverless_job_role" {
  name = "emr-serverless-job-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "emr-serverless.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_access" {
  role       = aws_iam_role.emr_serverless_job_role.name
  policy_arn = data.aws_iam_policy_document.emr_serverless_policy_doc.json
}