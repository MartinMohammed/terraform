# Game Jam Infrastructure

This directory contains the Terraform configuration for deploying and managing the AWS infrastructure for the Game Jam project.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) (v1.7.0 or later)
- AWS CLI configured with appropriate credentials
- GitHub repository with necessary secrets configured

## Required GitHub Secrets

The following secrets need to be configured in your GitHub repository:

- `AWS_ACCESS_KEY_ID`: Your AWS access key ID
- `AWS_SECRET_ACCESS_KEY`: Your AWS secret access key

## Getting Started

1. Configure your AWS credentials locally:

   ```bash
   aws configure
   ```

2. Initialize Terraform:

   ```bash
   terraform init
   ```

3. Create a new workspace (optional):

   ```bash
   terraform workspace new dev
   ```

4. Plan your changes:

   ```bash
   terraform plan
   ```

5. Apply the changes:
   ```bash
   terraform apply
   ```

## CI/CD Pipeline

The GitHub Actions workflow will automatically:

- Run `terraform fmt` to check formatting
- Initialize Terraform
- Validate the configuration
- Plan changes on pull requests
- Apply changes when merging to main

## Directory Structure

```
infrastructure/
├── main.tf          # Main Terraform configuration
├── variables.tf     # Variable definitions
└── .github/
    └── workflows/
        └── terraform.yml  # GitHub Actions workflow
```

## Notes

- The S3 backend configuration in `main.tf` needs to be updated with your specific bucket details
- The default region is set to `us-east-1` but can be changed in `variables.tf`
- Environment is set to `dev` by default
