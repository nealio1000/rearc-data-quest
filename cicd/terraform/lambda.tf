resource "null_resource" "install_python_dependencies" {
  provisioner "local-exec" {
    command = "pip install -r ../../lambdas/requirements.txt -t layer/python/lib/python3.13/site-packages"
  }
  triggers = {
    trigger = timestamp()
  }
}

data "archive_file" "layer_zip" {
  type        = "zip"
  source_dir  = "layer"
  output_path = "layer.zip"
  depends_on  = [null_resource.install_python_dependencies]
}

resource "aws_lambda_layer_version" "lambda_layer" {
  filename            = data.archive_file.layer_zip.output_path
  source_code_hash = data.archive_file.layer_zip.output_base64sha256
  layer_name          = "python-dependencies"
  compatible_runtimes = ["python3.13"]
  depends_on = [
    data.archive_file.layer_zip
  ]  
}

data "archive_file" "lambdas_zip" {
  type        = "zip"
  source_dir  = "../../lambdas/src"
  output_path = "lambdas.zip"
}

# Create the AWS Lambda function
resource "aws_lambda_function" "fetcher_lambda" {
  function_name    = var.fetcher_function_name
  handler          = "rearc_fetcher.lambda_handler"
  runtime          = var.runtime
  role             = aws_iam_role.lambda_exec_role.arn
  memory_size      = 128
  timeout          = 300
  depends_on       = [
    null_resource.install_python_dependencies,
    aws_lambda_layer_version.lambda_layer
  ]
  filename         = data.archive_file.lambdas_zip.output_path
  layers           = [aws_lambda_layer_version.lambda_layer.arn]
  source_code_hash = data.archive_file.lambdas_zip.output_base64sha256
}

# Create the AWS Lambda function
resource "aws_lambda_function" "logger_lambda" {
  function_name    = var.logger_function_name
  handler          = "rearc_logger.lambda_handler"
  runtime          = var.runtime
  role             = aws_iam_role.lambda_exec_role.arn
  memory_size      = 128
  timeout          = 300
  depends_on       = [
    null_resource.install_python_dependencies,
    aws_lambda_layer_version.lambda_layer
  ]
  filename         = data.archive_file.lambdas_zip.output_path
  layers           = [aws_lambda_layer_version.lambda_layer.arn]
  source_code_hash = data.archive_file.lambdas_zip.output_base64sha256
}

resource "aws_lambda_event_source_mapping" "proccesed_data_sqs_trigger" {
  event_source_arn = aws_sqs_queue.proccesed_data_notification_queue.arn
  function_name    = aws_lambda_function.logger_lambda.arn
  batch_size       = 1 # Process one file at a time
  enabled          = true
}

