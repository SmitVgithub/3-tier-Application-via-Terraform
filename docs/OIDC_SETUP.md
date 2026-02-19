# AWS OIDC Setup for GitHub Actions

This guide explains how to configure AWS OIDC (OpenID Connect) for secure, keyless authentication from GitHub Actions.

## Why OIDC?

- **No long-lived credentials**: No need to store AWS access keys as secrets
- **Fine-grained permissions**: Control which repos/branches can assume roles
- **Automatic rotation**: Tokens are short-lived and automatically rotated
- **Audit trail**: All role assumptions are logged in CloudTrail

## Setup Steps

### 1. Create OIDC Identity Provider in AWS

```bash
# Using AWS CLI
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

Or via AWS Console:
1. Go to IAM → Identity providers → Add provider
2. Select "OpenID Connect"
3. Provider URL: `https://token.actions.githubusercontent.com`
4. Audience: `sts.amazonaws.com`

### 2. Create IAM Role for GitHub Actions

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
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

### 3. Attach Required Policies

Attach these policies to the role:

**For Terraform operations:**
- Custom policy with required AWS permissions for your infrastructure
- Example permissions needed:
  - `ec2:*` (for EC2 instances)
  - `elasticloadbalancing:*` (for load balancers)
  - `rds:*` (for database)
  - `vpc:*` (for networking)
  - `s3:*` (for Terraform state if using S3 backend)
  - `dynamodb:*` (for state locking if using DynamoDB)

### 4. Configure GitHub Secrets

Add these secrets to your repository:

| Secret Name | Description | Example |
|-------------|-------------|----------|
| `AWS_ROLE_ARN` | ARN of the IAM role | `arn:aws:iam::123456789012:role/github-actions-role` |
| `EC2_SSH_PRIVATE_KEY` | Private SSH key for EC2 access | Contents of your .pem file |
| `EC2_SSH_USER` | SSH username | `ubuntu` or `ec2-user` |
| `BACKEND_EC2_HOST` | Backend EC2 public IP or DNS | `ec2-xx-xx-xx-xx.us-east-2.compute.amazonaws.com` |
| `BACKEND_APP_PATH` | Path to app on EC2 (optional) | `/home/ubuntu/app` |

### 5. Restrict Role to Specific Branches (Optional)

For production, restrict the role to specific branches:

```json
"StringLike": {
  "token.actions.githubusercontent.com:sub": [
    "repo:SmitVgithub/3-tier-Application-via-Terraform:ref:refs/heads/main",
    "repo:SmitVgithub/3-tier-Application-via-Terraform:ref:refs/heads/deployment"
  ]
}
```

## Terraform for OIDC Setup

You can also create the OIDC provider and role using Terraform:

```hcl
# oidc.tf
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

resource "aws_iam_role" "github_actions" {
  name = "github-actions-terraform-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:SmitVgithub/3-tier-Application-via-Terraform:*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions_policy" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"  # Adjust as needed
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions.arn
}
```

## Troubleshooting

### Error: "Not authorized to perform sts:AssumeRoleWithWebIdentity"
- Check the trust policy conditions
- Verify the repository name matches exactly
- Ensure the OIDC provider thumbprint is correct

### Error: "Audience in token doesn't match"
- Ensure `sts.amazonaws.com` is in the client ID list

### Error: "Subject claim doesn't match"
- Check the `sub` condition in the trust policy
- Format: `repo:OWNER/REPO:ref:refs/heads/BRANCH`
