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
      PROVIDER_1_URL  = var.providers_name[0].url
      PROVIDER_1_NAME = var.providers_name[0].name
      PROVIDER_2_URL  = var.providers_name[1].url
      PROVIDER_2_NAME = var.providers_name[1].name
      PROVIDER_3_URL  = var.providers_name[2].url
      PROVIDER_3_NAME = var.providers_name[2].name
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

resource "aws_sns_topic" "email_sns" {
  name = "AvailableVehiclesAlarmTopic"
}

resource "aws_sns_topic_subscription" "email_sns_subscription" {
  topic_arn = aws_sns_topic.email_sns.arn
  protocol  = "email"
  endpoint  = var.oncall_email
}

resource "aws_cloudwatch_metric_alarm" "available_vehicles" {
  for_each = { for provider in var.providers_name : provider.name => provider }

  alarm_name          = "${each.key}_AvailableVehiclesAlarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "AvailableVehicles"
  namespace           = "GBFSMonitoring"
  period              = "60"
  statistic           = "Average"
  threshold           = var.vehicle_count_alert_threshold
  alarm_description   = "Alarm when AvailableVehicles is below threshold for ${each.key}"
  actions_enabled     = true

  dimensions = {
    ProviderName = each.value.name
  }

  alarm_actions = [aws_sns_topic.email_sns.arn]
}

resource "aws_cloudwatch_metric_alarm" "lambda_error_alarm" {
  alarm_name          = "LambdaErrorAlarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1" 
  alarm_description   = "Alert when Lambda function encounters errors"
  actions_enabled     = true

  dimensions = {
    FunctionName = aws_lambda_function.test_lambda.function_name
  }

  alarm_actions = [aws_sns_topic.email_sns.arn] 
}