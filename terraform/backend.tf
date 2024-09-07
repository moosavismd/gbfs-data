terraform {
  backend "s3" {
    bucket         = "terraform-backend-terraformbackends3bucket-f0vevtiekieq"
    key            = "testing"
    region         = "us-east-1"
    dynamodb_table = "terraform-backend-TerraformBackendDynamoDBTable-1C2LQUVNQFZPK"
  }
}