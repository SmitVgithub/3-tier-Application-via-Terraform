# GitHub Environments Setup

## Required Environment: `production`

This pipeline uses GitHub Environments for manual approval on sensitive operations.

### Setup Steps:

1. Go to repository **Settings** → **Environments**
2. Click **New environment**
3. Name it: `production`
4. Configure protection rules:
   - ✅ **Required reviewers**: Add yourself or team members
   - ✅ **Wait timer** (optional): Add delay before deployment
   - ✅ **Deployment branches**: Limit to `main` and `deployment` branches

### Environment Secrets

Add these secrets specifically to the `production` environment for extra security:

- `EC2_SSH_PRIVATE_KEY`
- `BACKEND_EC2_HOST`

### How Manual Approval Works

1. When `terraform apply` or `deploy-backend` is triggered
2. GitHub will pause the workflow
3. Configured reviewers receive a notification
4. Reviewer must approve before the job continues
5. Deployment proceeds after approval

### Triggering Deployments

**Via GitHub UI:**
1. Go to **Actions** tab
2. Select "CI/CD Pipeline - Terraform & Backend Deployment"
3. Click **Run workflow**
4. Select action: `plan`, `apply`, or `deploy-backend`
5. Click **Run workflow**

**Automatic triggers:**
- Push to `main`: Runs validation + backend deployment (with approval)
- Push to `deployment`: Runs validation only
- Pull requests: Runs validation and comments results
