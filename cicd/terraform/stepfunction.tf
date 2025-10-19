# State Machine Definition (Amazon States Language - ASL)
# This example uses a simple Pass state, but you would define your workflow here.
locals {
  state_machine_definition = jsonencode({
    Comment = "A simple example state machine"
    StartAt = "InvokeFetcherLambda"
    States = {
      InvokeFetcherLambda = {
        Type = "Task"
        Resource = aws_lambda_function.fetcher_lambda.arn
        Next = "StartProcessDataEmrServerlessJob"
      }
      StartProcessDataEmrServerlessJob = {
        Type = "Task"
        Resource = "arn:aws:states:::emr-serverless:startJobRun.sync" # Use .sync for waiting
        Parameters = {
          ApplicationId = aws_emrserverless_application.rearc_spark_app.id
          ExecutionRoleArn = aws_iam_role.emr_serverless_job_role.arn
          JobDriver = {
            SparkSubmit = {
              EntryPoint = "s3://your-bucket/your-job-script.py"
              SparkSubmitParameters = "--conf spark.executor.instances=2 --conf spark.executor.memory=2G"
            }
          }
          ConfigurationOverrides = {
            ApplicationConfiguration = [
              {
                Classification = "spark-defaults"
                Properties = {
                  "spark.driver.memory" = "4G"
                }
              }
            ]
          }
        }
        End = true
      }
    }
  })
}

# AWS Step Functions State Machine
resource "aws_sfn_state_machine" "daily_fetch_data_state_machine" {
  name       = "DailyFetchDataStepMachine"
  role_arn   = aws_iam_role.step_function_role.arn
  definition = local.state_machine_definition
  type       = "STANDARD"
}