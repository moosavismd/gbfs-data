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


resource "aws_lambda_function" "test_lambda" {
  filename      = "../function.zip"
  function_name = "lambda_function_gbfs"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "main.fetch_and_process_data"

  runtime = "python3.12"

  timeout = 30

  environment {
    variables = {
      PROVIDER_1_URL="https://api.ridecheck.app/gbfs/v3/almere/vehicle_status.json"
      PROVIDER_1_NAME="Almere"
      PROVIDER_2_URL="https://api.ridecheck.app/gbfs/v3/amersfoort/vehicle_status.json"
      PROVIDER_2_NAME="Amersfoort"
      PROVIDER_3_URL="https://api.ridecheck.app/gbfs/v3/amsterdam/vehicle_status.json"
      PROVIDER_3_NAME="Amsterdam"
    }
  }
}
