data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "lambda_cloudwatch_logs_policy" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket = var.s3_bucket_name 
}

resource "aws_s3_bucket_versioning" "lambda_bucket_versioning" {
  bucket = aws_s3_bucket.lambda_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_iam_role_policy_attachment" "lambda_s3_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  role       = aws_iam_role.iam_for_lambda.name
}

resource "aws_s3_object" "lambda_function" {
  bucket = aws_s3_bucket.lambda_bucket.id
  key    = "function.zip"
  source = "../function.zip"
  etag   = filemd5("../function.zip")
}

resource "aws_lambda_function" "test_lambda" {
  function_name = var.lambda_function_name
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "main.fetch_and_process_data"
  s3_bucket     = aws_s3_bucket.lambda_bucket.id
  s3_key        = aws_s3_object.lambda_function.key
  
  runtime = "python3.12"

  timeout = 30

  environment {
    variables = {
      PROVIDER_1_URL  = "https://api.ridecheck.app/gbfs/v3/almere/vehicle_status.json"
      PROVIDER_1_NAME = "Almere"
      PROVIDER_2_URL  = "https://api.ridecheck.app/gbfs/v3/amersfoort/vehicle_status.json"
      PROVIDER_2_NAME = "Amersfoort"
      PROVIDER_3_URL  = "https://api.ridecheck.app/gbfs/v3/amsterdam/vehicle_status.json"
      PROVIDER_3_NAME = "Amsterdam"
    }
  }

  depends_on = [aws_s3_object.lambda_function]
}

resource "aws_cloudwatch_event_rule" "lambda_trigger" {
  name                = "lambda-trigger-rule"
  description         = "Triggers the Lambda function on a schedule"
  schedule_expression = var.schedule_expression
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.lambda_trigger.name
  target_id = var.lambda_function_name
  arn       = aws_lambda_function.test_lambda.arn

  depends_on = [aws_lambda_function.test_lambda]
}

resource "aws_lambda_permission" "allow_cloudwatch_invoke" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda_trigger.arn

  depends_on = [aws_lambda_function.test_lambda]
}

data "aws_iam_policy_document" "put_metric_data_policy" {
  statement {
    effect = "Allow"

    actions = ["cloudwatch:PutMetricData"]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "put_metric_data_policy" {
  name   = "put_metric_data_policy"
  role   = aws_iam_role.iam_for_lambda.id
  policy = data.aws_iam_policy_document.put_metric_data_policy.json
}

resource "aws_cloudwatch_dashboard" "gbfs_dashboard" {
  dashboard_name = "GBFSMonitoringDashboard"

  dashboard_body = jsonencode(local.gbfs_dashboard_widgets)
}
