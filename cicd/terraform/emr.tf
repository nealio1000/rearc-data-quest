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

    initial_capacity {
        initial_capacity_type = "Executor"
        initial_capacity_config {
            worker_count = 2
            worker_configuration {
                cpu    = "2 vCPU"
                memory = "4 GB"
            }
        }
    }

    auto_start_configuration {
        enabled = true
    }

    auto_stop_configuration {
        enabled = true
        idle_timeout_minutes = 30
    }

    maximum_capacity {
        cpu    = "10 vCPU"
        memory = "20 GB"
    }
}