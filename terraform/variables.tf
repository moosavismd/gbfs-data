variable "region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}

variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "lambda_function_gbfs"
}

variable "schedule_expression" {
  description = "The rate at which to trigger the Lambda function. Example: rate(5 minutes)"
  type        = string
  default     = "rate(2 minutes)" # You can modify this value as needed
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for storing lambda function zip file"
  type        = string
  default     = "lambda-function-gbfs-bucket"
}

variable "oncall_email" {
  description = "Email of the on-call to send alert"
  type        = string
  default     = "moosavi.smd@gmail.com"
}