### LAMBDA IAM ###

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
      "${aws_s3_bucket.raw_data_bucket.arn}/*",
      "${aws_s3_bucket.raw_data_bucket.arn}" 
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

resource "aws_iam_role_policy_attachment" "lambda_sqs_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_iam_policy.arn
}

### END LAMBDA IAM ###

### EMR IAM ###

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

data "aws_iam_policy_document" "emr_serverless_policy_doc" {
  statement {
    sid = "S3ReadWrite"
    effect = "Allow"
    resources = [
      "${aws_s3_bucket.raw_data_bucket.arn}/*",
      "${aws_s3_bucket.raw_data_bucket.arn}",
      "${aws_s3_bucket.processed_data_bucket.arn}/*",
      "${aws_s3_bucket.processed_data_bucket.arn}",
      "${aws_s3_bucket.artifacts_bucket.arn}/*",
      "${aws_s3_bucket.artifacts_bucket.arn}"
    ]
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject"
    ]
  }
}

resource "aws_iam_policy" "emr_serverless_iam_policy" {
  name = "emr_serverless_iam_policy"
  policy = data.aws_iam_policy_document.emr_serverless_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "emr_policy_attachment" {
  role       = aws_iam_role.emr_serverless_job_role.name
  policy_arn = aws_iam_policy.emr_serverless_iam_policy.arn
}

### END EMR IAM ###


### STEP FUNCTION IAM

# IAM Role for the Step Function
resource "aws_iam_role" "step_function_role" {
  name = "rearc-quest-step-function-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for the Step Function (e.g., to invoke a Lambda)
resource "aws_iam_role_policy" "step_function_policy" {
  name = "my-step-function-policy"
  role = aws_iam_role.step_function_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "lambda:InvokeFunction"
        Resource = aws_lambda_function.fetcher_lambda.arn
      },
      {
        Action = [
          "emr-serverless:StartJobRun",
          "emr-serverless:GetJobRun",
          "emr-serverless:StopJobRun",
          "emr-serverless:ListJobRuns",
        ]
        Effect   = "Allow"
        Resource = aws_emrserverless_application.rearc_spark_app.arn
      },
      {
        Effect = "Allow"
        Action = [
          "events:PutRule",
          "events:PutTargets",
          "events:DescribeRule"
        ]
        Resource = ["*"]
      },
      {
        Effect: "Allow",
        Action: "iam:PassRole",
        Resource = aws_iam_role.emr_serverless_job_role.arn
      }
    ]
  })
}

## END STEP FUNCTION IAM

## EVENTBRIDGE IAM

# IAM Role for EventBridge Scheduler
resource "aws_iam_role" "eventbridge_scheduler_role" {
  name = "eventbridge-scheduler-sfn-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "scheduler.amazonaws.com"
      }
    }]
  })
}

# Policy to allow EventBridge Scheduler to start Step Functions execution
resource "aws_iam_role_policy" "eventbridge_scheduler_sfn_policy" {
  name = "eventbridge-scheduler-sfn-policy"
  role = aws_iam_role.eventbridge_scheduler_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = "states:StartExecution"
      Effect   = "Allow"
      Resource = aws_sfn_state_machine.daily_fetch_data_state_machine.arn
    }]
  })
}