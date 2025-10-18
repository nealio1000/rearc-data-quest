resource "aws_emrserverless_application" "rearc_spark_app" {
    name    = "rearc-spark-app"
    release_label = "emr-7.10.0"
    type    = "spark"
    architecture = "ARM64"
    initial_capacity {
    initial_capacity_type = "Driver"
    initial_capacity_config {
      worker_count = 1
      worker_configuration {
        cpu    = "2 vCPU"
        memory = "4 GB"
      }
    }
  }
  maximum_capacity {
    cpu    = "10 vCPU"
    memory = "20 GB"
  }
}