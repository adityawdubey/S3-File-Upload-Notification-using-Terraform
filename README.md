# S3 File Upload Notification using Terraform

This project demonstrates the use of Terraform to automate the deployment of an AWS infrastructure that notifies users of file uploads to an S3 bucket. The infrastructure includes an S3 bucket, an SNS topic for notifications, an SQS queue, and a Lambda function that processes S3 events. Dependencies for the Lambda function are managed using a Lambda layer.

To implement the project step by step using the AWS Management Console, you can follow this project design narrative in my blog website: [https://adityadubey.cloud/s3-file-upload-notification-system](https://adityadubey.cloud/s3-file-upload-notification-system).

## Table of Contents

- [Architecture](#architecture)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Setup and Deployment](#setup-and-deployment)
- [Usage](#usage)

## Architecture

![S3 Notification (4)](https://github.com/adityawdubey/S3-File-Upload-Notification-using-AWS-CDK/assets/88245579/d57e9f6b-6900-49a4-97aa-e456cf724e4c)

The architecture consists of the following components:
- **S3 Bucket:** The designated storage location for uploaded files.
- **Lambda Function:** The heart of the system, automatically triggered by S3 events (file uploads), it processes the uploaded file and initiates notifications.
- **Amazon SNS (Simple Notification Service):** Used to send notifications to subscribers via various channels (email, SMS, etc.).
- **Amazon CloudWatch:** Provides logging and monitoring of the Lambda function's execution, ensuring observability and troubleshooting capabilities.
- **Amazon SQS (Simple Queue Service):** Used for decoupling and scaling the processing of uploaded files.

## Prerequisites

- **AWS Account:** An AWS account with appropriate permissions to create the required resources.
- **Terraform:** Terraform installed and configured on your development machine. You can download it from https://developer.hashicorp.com/terraform/install.
- **AWS CLI (Optional):** The AWS CLI can be helpful for interacting with AWS services directly if needed.
- **Python 3.8+:** The Lambda function is written in Python.

## Setup and Deployment

### Clone the Repository

```bash
git clone https://github.com/adityawdubey/S3-File-Upload-Notification-using-Terraform.git
```

### Configure AWS CLI

Ensure your AWS CLI is configured with the necessary permissions.

### Install Terraform

The easiest way to install Terraform on macOS is with Homebrew.

```bash 
brew tap hashicorp/tap
brew install hashicorp/tap/
```

### Initialize Terraform

Initialize Terraform to download the necessary providers:

```bash
terraform init
```

### Plan Terraform Deployment

Before applying the Terraform configuration, it's good practice to review the changes that will be made. Run the following command to generate an execution plan:

```bash
terraform plan
```
This will create a plan file named tfplan which you can review to understand what changes will be applied.

### Apply Terraform Configuration

Apply the Terraform configuration to create the resources:
```bash
terraform apply tfplan
```

## Usage

Any file uploaded to the specified S3 bucket will trigger the Lambda function. The Lambda function processes the file and sends a notification via SNS. 

## Cleanup

To delete all resources created by this project, run:
```bash
terraform destroy
```

## References

- https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- https://docs.aws.amazon.com/lambda/latest/dg/welcome.html
- https://docs.aws.amazon.com/sns/latest/dg/welcome.html 


