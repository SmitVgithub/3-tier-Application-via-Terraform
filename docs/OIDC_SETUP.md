# AWS OIDC Setup for GitHub Actions

This document explains how to set up AWS OIDC (OpenID Connect) authentication for GitHub Actions.

## Why OIDC?

- **No static credentials**: No need to store long-lived AWS access keys as secrets
- **Short-lived tokens**: Credentials are automatically rotated
- **Fine-grained permissions**: Control exactly which repositories and branches can assume the role

## Setup Steps

### 1. Create OIDC Identity Provider in AWS

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

### 2. Create IAM Role with Trust Policy

Create a file named `trust-policy.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<AWS_ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:SmitVgithub/3-tier-Application-via-Terraform:*"
        }
      }
    }
  ]
}
```

Create the role:

```bash
aws iam create-role \
  --role-name GitHubActions-Terraform-Role \
  --assume-role-policy-document file://trust-policy.json
```

### 3. Attach Required Permissions

Attach policies based on what your Terraform needs to manage. For a 3-tier application, you might need:

```bash
# Example: Attach necessary policies
aws iam attach-role-policy \
  --role-name GitHubActions-Terraform-Role \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess

aws iam attach-role-policy \
  --role-name GitHubActions-Terraform-Role \
  --policy-arn arn:aws:iam::aws:policy/AmazonRDSFullAccess

aws iam attach-role-policy \
  --role-name GitHubActions-Terraform-Role \
  --policy-arn arn:aws:iam::aws:policy/AmazonVPCFullAccess

aws iam attach-role-policy \
  --role-name GitHubActions-Terraform-Role \
  --policy-arn arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess
```

**Note**: For production, create a custom policy with least-privilege permissions.

### 4. Add Role ARN to GitHub Secrets

1. Go to your repository settings
2. Navigate to **Secrets and variables** → **Actions**
3. Add a new secret:
   - Name: `AWS_ROLE_ARN`
   - Value: `arn:aws:iam::<AWS_ACCOUNT_ID>:role/GitHubActions-Terraform-Role`

### 5. (Optional) Create Production Environment

For the apply step with manual approval:

1. Go to repository **Settings** → **Environments**
2. Create environment named `production`
3. Add required reviewers for manual approval
4. Optionally restrict to `main` branch only

## Terraform Backend Configuration

Ensure your `backend.tf` is configured for S3 state storage:

```hcl
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "3-tier-app/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

## Security Best Practices

1. **Restrict the trust policy** to specific branches if needed:
   ```json
   "token.actions.githubusercontent.com:sub": "repo:SmitVgithub/3-tier-Application-via-Terraform:ref:refs/heads/main"
   ```

2. **Use least-privilege permissions** for the IAM role

3. **Enable CloudTrail** to audit API calls made by the role

4. **Use environment protection rules** for production deployments
