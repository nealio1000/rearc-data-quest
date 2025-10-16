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

# Attach a policy to the IAM role for basic Lambda execution
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Package the Lambda function code into a zip file
data "archive_file" "fetcher_lambda_zip" {
  type        = "zip"
  source_file = "../../lambdas/rearc_fetcher.py"
  output_path = "fetcher_lambda.zip"
}

# Create the AWS Lambda function
resource "aws_lambda_function" "fetcher_lambda" {
  function_name    = "rearc_fetcher_lambda"
  handler          = "rearc_fetcher.handler"
  runtime          = "python3.9"
  role             = aws_iam_role.lambda_exec_role.arn
  filename         = data.archive_file.fetcher_lambda_zip.output_path
  source_code_hash = data.archive_file.fetcher_lambda_zip.output_base64sha256
}

# Output the Lambda function's ARN
output "lambda_function_arn" {
  value = aws_lambda_function.fetcher_lambda.arn
}