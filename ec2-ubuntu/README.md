# AWS EC2 Ubuntu Instance - Terraform Configuration

This Terraform configuration creates an AWS EC2 instance with the following specifications:

## Specifications

| Resource | Configuration |
|----------|---------------|
| **OS** | Ubuntu 24.04 LTS (Noble Numbat) |
| **Instance Type** | c6a.large (2 vCPU, 4 GB RAM) |
| **Region** | ap-south-1 (Mumbai) |
| **VPC** | Default VPC |
| **Storage** | 100 GB GP3 (encrypted) |
| **Security Group** | Ports 22, 80, 443 open to 0.0.0.0/0 |

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- AWS CLI configured with appropriate credentials
- IAM permissions to create EC2, Security Groups, and related resources

## Usage

### 1. Initialize Terraform

```bash
cd ec2-ubuntu
terraform init
```

### 2. Review the execution plan

```bash
terraform plan
```

### 3. Apply the configuration

```bash
terraform apply
```

### 4. Destroy resources (when no longer needed)

```bash
terraform destroy
```

## Customization

You can customize the deployment by creating a `terraform.tfvars` file:

```hcl
aws_region       = "ap-south-1"
instance_name    = "my-ubuntu-server"
instance_type    = "c6a.large"
root_volume_size = 100
environment      = "production"
```

## Outputs

After successful deployment, the following outputs will be displayed:

- `instance_id` - EC2 instance ID
- `instance_public_ip` - Public IP address
- `instance_private_ip` - Private IP address
- `instance_public_dns` - Public DNS name
- `security_group_id` - Security group ID
- `ami_id` - AMI ID used
- `availability_zone` - Availability zone

## SSH Access

To SSH into the instance, you'll need to:

1. Create or specify an existing key pair (add `key_name` to the instance resource)
2. Use the public IP from the outputs:

```bash
ssh -i your-key.pem ubuntu@<instance_public_ip>
```

## Security Considerations

⚠️ **Warning**: This configuration opens ports 22, 80, and 443 to the entire internet (0.0.0.0/0). For production environments, consider:

- Restricting SSH (port 22) to specific IP addresses
- Using AWS Systems Manager Session Manager instead of SSH
- Implementing a bastion host architecture
- Using a VPN for administrative access

## Cost Estimation

- **c6a.large** in ap-south-1: ~$0.0768/hour (~$55/month)
- **100 GB GP3**: ~$8/month
- **Data transfer**: Variable based on usage

*Prices are approximate and may vary. Check [AWS Pricing](https://aws.amazon.com/ec2/pricing/) for current rates.*
