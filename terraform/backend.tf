terraform {
  backend "s3" {
    bucket         = "terraform-backend-terraformbackends3bucket-wnifhmqbbdxr"
    key            = "testing"
    region         = "us-east-1"
    dynamodb_table = "terraform-backend-TerraformBackendDynamoDBTable-1T3ELA3FNXJKJ"
  }
}