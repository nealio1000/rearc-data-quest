variable "path_source_code" {
  default = "lambdas"
}

variable "fetcher_function_name" {
  default = "rearc_fetcher"
}

variable "logger_function_name" {
    default = "rearc_logger"
}

variable "runtime" {
  default = "python3.13"
}

variable "output_path" {
  description = "Path to function's deployment package into local filesystem. eg: /path/lambda_function.zip"
  default = "lambdas.zip"
}

variable "distribution_pkg_folder" {
  description = "Folder name to create distribution files..."
  default = "lambda_dist_pkg"
}

variable "data_bucket" {
  description = "Bucket name for rearc data"
  default = "rearc-quest-data-bucket"
}