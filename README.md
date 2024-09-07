# GBFS Monitoring Project

This project monitors the `vehicle_status` JSON feed from three GBFS providers (Almere, Amersfoort, Amsterdam), tracks the total number of vehicles and available vehicles, and displays the data in a CloudWatch dashboard. It includes a CI/CD pipeline for automating the deployment using GitHub Actions and Terraform.

The project is designed with the following goals:
- **Monitor vehicle data** using the GBFS v3 specification.
- **Trigger CloudWatch alerts** when the number of available vehicles falls below a set threshold.
- **Automate the deployment** using a CI/CD pipeline.
- **Store Lambda code in S3** for scalability and easy updates.
- **Automatically trigger Lambda** every 2 minutes using CloudWatch Events.

## Prerequisites

To deploy and run this project, ensure you have the following:
- **AWS Account**: Set up with necessary permissions.
- **GitHub Actions**: Configured with AWS credentials stored in secrets.
  - Set the following secrets in your GitHub repository settings under `Settings > Secrets > Actions`:
    - `AWS_ACCESS_KEY_ID`: Your AWS Access Key ID.
    - `AWS_SECRET_ACCESS_KEY`: Your AWS Secret Access Key.
- **Terraform**: Installed locally to manage infrastructure as code.

## Instructions to Build and Run

### 1. Set Up the Terraform Backend

Before deploying the infrastructure, run the `deploy.sh` script to create the backend resources (S3 bucket and DynamoDB table) for storing Terraform state.

```bash
sh deploy.sh
```

After running the script, the S3 bucket and DynamoDB table names will be outputted. Update the `terraform/backend.tf` file with these values:

```hcl
backend "s3" {
  bucket         = "your-s3-bucket-name"
  key            = "your/terraform/key"
  region         = "your-region"
  dynamodb_table = "your-dynamodb-table"
}
```

### 2. Override Variables

The project uses variables to make providers, thresholds, and other configurations flexible. If you need to override the default values, edit the `override.tfvars` file. 

For example:

```hcl
region = "us-east-1"
lambda_function_name = "lambda_function_gbfs"
vehicle_count_alert_threshold = 5
providers_name = [
  {
    url  = "https://api.ridecheck.app/gbfs/v3/almare/vehicle_status.json"
    name = "Almare"
  }
]
```

### 3. Deploy with CI/CD

The CI/CD pipeline is already set up using GitHub Actions. Simply push your code to the repository, and the pipeline will handle:
- **Building and packaging the Lambda function**: The `main.py` Lambda code is zipped, and dependencies are installed.
- **Storing the Lambda package in an S3 bucket**: The function code is uploaded to the S3 bucket specified in the `variables.tf` file.
- **Deploying the infrastructure using Terraform**: Lambda, CloudWatch triggers, alerts, and dashboards are deployed.
- **Triggering the Lambda function every 2 minutes**: This is done via a CloudWatch Events rule configured in Terraform.

### 4. Manual Deployment (Optional)

If you wish to manually deploy the infrastructure, navigate to the `terraform/` directory and run:

```bash
terraform init
terraform apply -var-file="override.tfvars"
```

This will apply the configuration and deploy the resources.

## Architecture Overview

- **AWS Lambda**: Fetches data from GBFS providers, processes it, and pushes metrics to CloudWatch.
- **AWS CloudWatch**:
  - **Dashboards**: Displays metrics like `TotalVehicles` and `AvailableVehicles`.
  - **Alarms**: Alerts when the number of available vehicles falls below the threshold.
  - **Events Trigger**: Automatically invokes the Lambda function every 2 minutes.
- **AWS S3**: Stores the Lambda function code (`function.zip`) to be pulled by the Lambda function during deployment.
- **Terraform**: Manages the infrastructure as code, deploying the Lambda function, CloudWatch dashboards, triggers, and alerts.
- **GitHub Actions**: CI/CD pipeline for automating the build and deployment processes.

## Things to Improve with More Time

Given more time, the following improvements would be made:
- **Use AWS modules** for Terraform to better structure and simplify the code.
- **Implement more of the GBFS specification** covering additional feeds like system alerts, station information, and more.
- **Extract more metrics** from the data and define additional dashboards and alerts for better observability.
- **Separate development and production environments** ensuring different configurations for each.
- **Store data in a long-term database** such as DynamoDB to enable historical analysis.
- **Multi-zone deployment** for greater resilience, identifying and eliminating single points of failure.
- **Cloud-agnostic approach** to support deployment across multiple cloud providers.

## Known Limitations

- Only the **`vehicle_status`** feed from the GBFS v3 specification has been implemented.
- **No long-term storage** of vehicle data, limiting historical analysis.
- **No support for cloud-agnostic deployment** (currently supports only AWS).
