# Package the Lambda function code into a zip file
data "archive_file" "fetcher_lambda_zip" {
  type        = "zip"
  source_file = "../../lambdas/rearc_fetcher.py"
  output_path = "fetcher_lambda.zip"
}

# Create the AWS Lambda function
resource "aws_lambda_function" "fetcher_lambda" {
  function_name    = var.fetcher_function_name
  handler          = "rearc_fetcher.handler"
  runtime          = var.runtime
  role             = aws_iam_role.lambda_exec_role.arn
  memory_size      = 128
  timeout          = 300
  depends_on       = [null_resource.install_python_dependencies]
  source_code_hash = data.archive_file.create_dist_pkg.output_base64sha256
  filename         = data.archive_file.create_dist_pkg.output_path
}

# Output the Lambda function's ARN
output "lambda_function_arn" {
  value = aws_lambda_function.fetcher_lambda.arn
}

resource "null_resource" "install_python_dependencies" {
  provisioner "local-exec" {
    command = "bash ${path.module}/scripts/create_pkg.sh"

    environment = {
      source_code_path = var.path_source_code
      function_name = var.fetcher_function_name
      path_module = path.module
      runtime = var.runtime
      path_cwd = path.cwd
    }
  }
}

data "archive_file" "create_dist_pkg" {
  depends_on = [null_resource.install_python_dependencies]
  source_dir = "${path.cwd}/lambda_dist_pkg/"
  output_path = var.output_path
  type = "zip"
}
