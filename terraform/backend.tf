terraform {
  backend "s3" {
    bucket         = "terraform-backend-terraformbackends3bucket-sl1u6bcxqeji"
    key            = "testing"
    region         = "us-east-1"
    dynamodb_table = "terraform-backend-TerraformBackendDynamoDBTable-C0444K9UM8Q1"
  }
}