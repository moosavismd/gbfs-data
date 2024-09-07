region = "us-east-1"

lambda_function_name = "lambda_function_gbfs"

schedule_expression = "rate(2 minutes)"

s3_bucket_name = "lambda-function-gbfs-bucket"

oncall_email = "moosavi.smd@gmail.com"

vehicle_count_alert_threshold = 0

providers_name = [
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