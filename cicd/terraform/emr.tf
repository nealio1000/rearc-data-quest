resource "aws_emrserverless_application" "rearc_spark_app" {
    name    = "rearc-spark-app"
    release_label = "emr-7.10.0"
    type    = "spark"

    auto_start_configuration {
        enabled = true
    }

    auto_stop_configuration {
        enabled = true
        idle_timeout_minutes = 30
    }
}