# 🤖 AI Code Analysis Recommendations

## 📊 Summary
Code analysis complete

## 🔍 Detailed Analysis
# 📊 Code Analysis Report

## Repository: 3-tier-Application-via-Terraform (feature/ec2-ubuntu-mumbai branch)

### 📈 Executive Summary
This Terraform codebase implements a 3-tier architecture on AWS but contains **critical security vulnerabilities** including hardcoded credentials, overly permissive security groups, and missing encryption configurations. The infrastructure lacks proper state management security, monitoring capabilities, and follows several anti-patterns that could lead to security breaches and operational issues.

**Total Issues Found:** 18
- 🔴 Critical: 5
- 🟠 High: 5
- 🟡 Medium: 5
- 🟢 Low: 3

---

## 🔍 Detailed Findings

### 🔴 CRITICAL SEVERITY ISSUES

---

#### Issue 1: Hardcoded Database Credentials in Plain Text

**📁 File:** `db.tf`  
**📍 Lines:** 12-13  
**🏷️ Category:** Security

**Current Code:**
```hcl
username             = "admin"
password             = "admin123"
```

**❌ Problem:**  
Database credentials are hardcoded in plain text, which will be stored in Terraform state files and version control. This is a severe security vulnerability that could lead to unauthorized database access and data breaches.

**✅ Solution:**  
Use AWS Secrets Manager or SSM Parameter Store to manage sensitive credentials, or use Terraform variables with sensitive flag and inject values at runtime.

**📖 Reference:**  
[Terraform Sensitive Variables](https://developer.hashicorp.com/terraform/language/values/variables#suppressing-values-in-cli-output)  
[AWS Secrets Manager with Terraform](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret)

**💡 Fixed Code:**
```hcl
# Option 1: Using AWS Secrets Manager
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name = "${var.project_name}-db-credentials"
  
  tags = var.common_tags
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
  })
}

resource "aws_db_instance" "my_rds" {
  # ... other config ...
  username = var.db_username
  password = random_password.db_password.result
}

# In variables.tf
variable "db_username" {
  description = "Database administrator username"
  type        = string
  sensitive   = true
}
```

**Impact:** Credentials exposed in state files and Git history can be exploited by attackers to gain full database access.

---

#### Issue 2: Database Publicly Accessible

**📁 File:** `db.tf`  
**📍 Line:** 14  
**🏷️ Category:** Security

**Current Code:**
```hcl
publicly_accessible    = true
```

**❌ Problem:**  
The RDS instance is publicly accessible from the internet. In a 3-tier architecture, the database tier should only be accessible from the application tier, never directly from the internet.

**✅ Solution:**  
Set `publicly_accessible = false` and ensure the database is only accessible through private subnets via the application tier.

**📖 Reference:**  
[AWS RDS Security Best Practices](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_BestPractices.Security.html)  
[Terraform aws_db_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance#publicly_accessible)

**💡 Fixed Code:**
```hcl
resource "aws_db_instance" "my_rds" {
  identifier             = "${var.project_name}-rds"
  allocated_storage      = var.db_allocated_storage
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = var.db_instance_class
  db_name                = var.db_name
  username               = var.db_username
  password               = random_password.db_password.result
  
  # Security configurations
  publicly_accessible    = false
  db_subnet_group_name   = aws_db_subnet_group.my_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  
  # Encryption
  storage_encrypted      = true
  kms_key_id            = aws_kms_key.rds_encryption.arn
  
  # Backup and maintenance
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "Mon:04:00-Mon:05:00"
  
  # Protection
  deletion_protection    = true
  skip_final_snapshot    = false
  final_snapshot_identifier = "${var.project_name}-final-snapshot"
  
  tags = merge(var.common_tags, {
    Name = "${var.project_name}-rds"
  })
}
```

**Impact:** Publicly accessible databases are prime targets for SQL injection attacks, brute force attempts, and data exfiltration.

---

#### Issue 3: Overly Permissive Security Group - SSH Open to World

**📁 File:** `networking.tf`  
**📍 Lines:** 70-76  
**🏷️ Category:** Security

**Current Code:**
```hcl
ingress {
  description = "SSH"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
```

**❌ Problem:**  
SSH port 22 is open to the entire internet (0.0.0.0/0). This exposes the instances to brute force attacks, credential stuffing, and potential unauthorized access.

**✅ Solution:**  
Restrict SSH access to specific IP ranges (corporate VPN, bastion host) or use AWS Systems Manager Session Manager for secure shell access without opening SSH ports.

**📖 Reference:**  
[AWS Security Group Best Practices](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-best-practices.html)  
[AWS Systems Manager Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html)

**💡 Fixed Code:**
```hcl
# Option 1: Restrict to specific IPs
variable "allowed_ssh_cidr_blocks" {
  description = "CIDR blocks allowed to SSH"
  type        = list(string)
  default     = []  # Must be explicitly set
}

resource "aws_security_group" "web_sg" {
  name        = "${var.project_name}-web-sg"
  description = "Security group for web tier"
  vpc_id      = aws_vpc.my_vpc.id

  # SSH - Restricted access
  ingress {
    description = "SSH from allowed IPs only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr_blocks
  }

  # HTTP from ALB only
  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-web-sg"
  })
}

# Option 2: Use SSM Session Manager (Recommended)
resource "aws_iam_role" "ssm_role" {
  name = "${var.project_name}-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "${var.project_name}-ssm-profile"
  role = aws_iam_role.ssm_role.name
}
```

**Impact:** Open SSH ports are constantly scanned by automated bots and can lead to server compromise within minutes of deployment.

---

#### Issue 4: Terraform State Not Encrypted and No Locking

**📁 File:** `backend.tf`  
**📍 Lines:** 1-7  
**🏷️ Category:** Security/DevOps

**Current Code:**
```hcl
terraform {
  backend "s3" {
    bucket = "my-terraform-state-bucket-3tier"
    key    = "terraform.tfstate"
    region = "ap-south-1"
  }
}
```

**❌ Problem:**  
The S3 backend configuration lacks encryption, DynamoDB state locking, and versioning. This can lead to state file corruption during concurrent operations and exposes sensitive data in state files.

**✅ Solution:**  
Enable server-side encryption, add DynamoDB table for state locking, and enable versioning on the S3 bucket.

**📖 Reference:**  
[Terraform S3 Backend Configuration](https://developer.hashicorp.com/terraform/language/settings/backends/s3)  
[AWS S3 Encryption](https://docs.aws.amazon.com/AmazonS3/latest/userguide/serv-side-encryption.html)

**💡 Fixed Code:**
```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket-3tier"
    key            = "env/prod/terraform.tfstate"
    region         = "ap-south-1"
    
    # Encryption
    encrypt        = true
    kms_key_id     = "alias/terraform-state-key"
    
    # State locking
    dynamodb_table = "terraform-state-lock"
    
    # Access control
    acl            = "private"
  }
  
  required_version = ">= 1.0.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Create these resources in a separate bootstrap configuration
# bootstrap/main.tf
resource "aws_s3_bucket" "terraform_state" {
  bucket = "my-terraform-state-bucket-3tier"
  
  tags = {
    Name        = "Terraform State Bucket"
    Environment = "shared"
    ManagedBy   = "terraform"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.terraform_state.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_lock" {
  name           = "terraform-state-lock"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform State Lock Table"
    Environment = "shared"
  }
}

resource "aws_kms_key" "terraform_state" {
  description             = "KMS key for Terraform state encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

resource "aws_kms_alias" "terraform_state" {
  name          = "alias/terraform-state-key"
  target_key_id = aws_kms_key.terraform_state.key_id
}
```

**Impact:** Without state locking, concurrent Terraform runs can corrupt state. Without encryption, sensitive data (passwords, keys) in state files are exposed.

---

#### Issue 5: Database Security Group Allows All Traffic from Web Tier

**📁 File:** `networking.tf`  
**📍 Lines:** 106-112  
**🏷️ Category:** Security

**Current Code:**
```hcl
ingress {
  description     = "MySQL from web tier"
  from_port       = 3306
  to_port         = 3306
  protocol        = "tcp"
  security_groups = [aws_security_group.web_sg.id]
}
```

**❌ Problem:**  
While this is better than opening to 0.0.0.0/0, the database should only accept connections from the application tier, not the web tier. In a proper 3-tier architecture, web → app → database.

**✅ Solution:**  
Create a separate security group for the application tier and only allow database connections from that tier.

**📖 Reference:**  
[AWS 3-Tier Architecture Best Practices](https://docs.aws.amazon.com/whitepapers/latest/serverless-multi-tier-architectures-api-gateway-lambda/three-tier-architecture-overview.html)

**💡 Fixed Code:**
```hcl
# Application tier security group
resource "aws_security_group" "app_sg" {
  name        = "${var.project_name}-app-sg"
  description = "Security group for application tier"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    description     = "HTTP from web tier"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-app-sg"
    Tier = "application"
  })
}

# Database security group - only from app tier
resource "aws_security_group" "db_sg" {
  name        = "${var.project_name}-db-sg"
  description = "Security group for database tier"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    description     = "MySQL from application tier only"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  # No egress needed for RDS typically
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-db-sg"
    Tier = "database"
  })
}
```

**Impact:** Improper network segmentation allows potential lateral movement if the web tier is compromised.

---

### 🟠 HIGH SEVERITY ISSUES

---

#### Issue 6: No RDS Encryption at Rest

**📁 File:** `db.tf`  
**📍 Lines:** 1-22  
**🏷️ Category:** Security/Compliance

**Current Code:**
```hcl
resource "aws_db_instance" "my_rds" {
  identifier             = "my-rds"
  allocated_storage      = 20
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  db_name                = "mydb"
  username               = "admin"
  password               = "admin123"
  publicly_accessible    = true
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.my_db_subnet_group.name
  skip_final_snapshot    = true
  # Missing: storage_encrypted, kms_key_id
}
```

**❌ Problem:**  
RDS instance lacks encryption at rest, which is required for compliance with regulations like GDPR, HIPAA, PCI-DSS, and SOC 2.

**✅ Solution:**  
Enable storage encryption using AWS KMS.

**📖 Reference:**  
[AWS RDS Encryption](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Overview.Encryption.html)

**💡 Fixed Code:**
```hcl
resource "aws_kms_key" "rds_encryption" {
  description             = "KMS key for RDS encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  
  tags = merge(var.common_tags, {
    Name = "${var.project_name}-rds-kms"
  })
}

resource "aws_kms_alias" "rds_encryption" {
  name          = "alias/${var.project_name}-rds"
  target_key_id = aws_kms_key.rds_encryption.key_id
}

resource "aws_db_instance" "my_rds" {
  # ... other config ...
  
  # Encryption at rest
  storage_encrypted = true
  kms_key_id       = aws_kms_key.rds_encryption.arn
  
  # Enable Performance Insights with encryption
  performance_insights_enabled    = true
  performance_insights_kms_key_id = aws_kms_key.rds_encryption.arn
}
```

**Impact:** Unencrypted data at rest fails compliance audits and exposes sensitive data if storage media is compromised.

---

#### Issue 7: No HTTPS/TLS Configuration on Load Balancer

**📁 File:** `load_balancers.tf`  
**📍 Lines:** 1-45  
**🏷️ Category:** Security

**Current Code:**
```hcl
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = "80"
  protocol          = "HTTP"
  # Missing HTTPS listener
}
```

**❌ Problem:**  
The load balancer only listens on HTTP (port 80), transmitting all data in plain text. This exposes user data, session tokens, and credentials to man-in-the-middle attacks.

**✅ Solution:**  
Add HTTPS listener with ACM certificate and redirect HTTP to HTTPS.

**📖 Reference:**  
[AWS ALB HTTPS Listener](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html)  
[Terraform aws_lb_listener](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener)

**💡 Fixed Code:**
```hcl
# Request ACM certificate
resource "aws_acm_certificate" "main" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  subject_alternative_names = [
    "*.${var.domain_name}"
  ]

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-cert"
  })
}

# HTTP listener - redirect to HTTPS
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# HTTPS listener
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.main.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

# Update ALB security group
resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP for redirect"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-alb-sg"
  })
}
```

**Impact:** All traffic including passwords and sensitive data transmitted in plain text can be intercepted.

---

#### Issue 8: No Backup Configuration for RDS

**📁 File:** `db.tf`  
**📍 Lines:** 1-22  
**🏷️ Category:** Reliability/Disaster Recovery

**Current Code:**
```hcl
resource "aws_db_instance" "my_rds" {
  # ... config ...
  skip_final_snapshot    = true
  # Missing: backup_retention_period, backup_window
}
```

**❌ Problem:**  
No automated backups configured and final snapshot is skipped. Data loss would be unrecoverable in case of accidental deletion or corruption.

**✅ Solution:**  
Enable automated backups with appropriate retention period and configure backup windows.

**📖 Reference:**  
[AWS RDS Backup and Restore](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_WorkingWithAutomatedBackups.html)

**💡 Fixed Code:**
```hcl
resource "aws_db_instance" "my_rds" {
  # ... other config ...
  
  # Backup configuration
  backup_retention_period = 7                    # Keep backups for 7 days
  backup_window          = "03:00-04:00"        # UTC time
  maintenance_window     = "Mon:04:00-Mon:05:00"
  
  # Snapshot configuration
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.project_name}-final-${formatdate("YYYY-MM-DD", timestamp())}"
  copy_tags_to_snapshot     = true
  
  # Deletion protection
  deletion_protection = true
  
  # Enable enhanced monitoring
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring.arn
  
  # Enable Performance Insights
  performance_insights_enabled          = true
  performance_insights_retention_period = 7
}

# IAM role for enhanced monitoring
resource "aws_iam_role" "rds_monitoring" {
  name = "${var.project_name}-rds-monitoring"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "monitoring.rds.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
```

**Impact:** Without backups, any data corruption or accidental deletion results in permanent data loss.

---

#### Issue 9: Missing Provider Version Constraints

**📁 File:** `providers.tf`  
**📍 Lines:** 1-4  
**🏷️ Category:** DevOps/Reliability

**Current Code:**
```hcl
provider "aws" {
  region = "ap-south-1"
}
```

**❌ Problem:**  
No version constraints on the AWS provider. Provider updates could introduce breaking changes, causing infrastructure drift or deployment failures.

**✅ Solution:**  
Pin provider versions and specify required Terraform version.

**📖 Reference:**  
[Terraform Provider Version Constraints](https://developer.hashicorp.com/terraform/language/providers/requirements)

**💡 Fixed Code:**
```hcl
terraform {
  required_version = ">= 1.5.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Repository  = "3-tier-Application-via-Terraform"
    }
  }
}

# Provider for ACM certificates (must be us-east-1 for CloudFront)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
```

**Impact:** Unpinned versions can cause unexpected infrastructure changes and deployment failures.

---

#### Issue 10: EC2 Instances Without IAM Instance Profile

**📁 File:** `frontend.tf`  
**📍 Lines:** 1-20  
**🏷️ Category:** Security/Operations

**Current Code:**
```hcl
resource "aws_instance" "web" {
  count                  = 2
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = element(aws_subnet.public_subnets[*].id, count.index)
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = var.key_name
  # Missing: iam_instance_profile
}
```

**❌ Problem:**  
EC2 instances lack IAM instance profiles, preventing secure access to AWS services and forcing use of hardcoded credentials or SSH keys.

**✅ Solution:**  
Create IAM roles with least-privilege policies and attach instance profiles.

**📖 Reference:**  
[AWS IAM Roles for EC2](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/iam-roles-for-amazon-ec2.html)

**💡 Fixed Code:**
```hcl
# IAM role for web tier
resource "aws_iam_role" "web_role" {
  name = "${var.project_name}-web-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = var.common_tags
}

# Policy for SSM access (for Session Manager)
resource "aws_iam_role_policy_attachment" "web_ssm" {
  role       = aws_iam_role.web_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Policy for CloudWatch logs
resource "aws_iam_role_policy_attachment" "web_cloudwatch" {
  role       = aws_iam_role.web_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Custom policy for S3 access (if needed)
resource "aws_iam_role_policy" "web_s3_access" {
  name = "${var.project_name}-web-s3-policy"
  role = aws_iam_role.web_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:ListBucket"
      ]
      Resource = [
        "arn:aws:s3:::${var.project_name}-assets",
        "arn:aws:s3:::${var.project_name}-assets/*"
      ]
    }]
  })
}

# Instance profile
resource "aws_iam_instance_profile" "web_profile" {
  name = "${var.project_name}-web-profile"
  role = aws_iam_role.web_role.name
}

# Updated EC2 instance
resource "aws_instance" "web" {
  count                  = var.web_instance_count
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = element(aws_subnet.public_subnets[*].id, count.index)
  vpc_security_group_ids = [aws_security_group.web_sg.id]

## 💡 Recommendations




---

**Generated by AI DevOps Agent**
**Branch:** `feature/ec2-ubuntu-mumbai`
**Date:** 2026-02-17T16:26:20.102Z

## 📝 Next Steps
1. Review these recommendations
2. Implement the suggested changes
3. Test your changes
4. When ready, say "merge to [branch-name]" to merge this PR
