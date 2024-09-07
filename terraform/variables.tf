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

variable "vehicle_count_alert_threshold" {
  description = "Threshold for number of vehicle to trigger an alert"
  type        = number
  default     = "0"
}

variable "providers_name" {
  description = "List of provider information"
  type = list(object({
    url  = string
    name = string
  }))
  default = [
    {
      url  = "https://api.ridecheck.app/gbfs/v3/almere/vehicle_status.json"
      name = "Almere"
    },
    {
      url  = "https://api.ridecheck.app/gbfs/v3/amersfoort/vehicle_status.json"
      name = "Amersfoort"
    },
    {
      url  = "https://api.ridecheck.app/gbfs/v3/amsterdam/vehicle_status.json"
      name = "Amsterdam"
    }
  ]
}
