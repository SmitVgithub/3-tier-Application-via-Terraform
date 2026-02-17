# AWS EC2 Instance - Ubuntu 24.04 in Mumbai Region
# Following official Terraform AWS Provider documentation
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data source to get the latest Ubuntu 24.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical's AWS account ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# Data source to get the default VPC
data "aws_vpc" "default" {
  default = true
}

# Data source to get a subnet from the default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Security Group allowing ports 22, 80, and 443
resource "aws_security_group" "ec2_sg" {
  name        = "${var.instance_name}-sg"
  description = "Security group for ${var.instance_name} - Allow SSH, HTTP, HTTPS"
  vpc_id      = data.aws_vpc.default.id

  # SSH access
  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access
  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound traffic - allow all
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.instance_name}-sg"
  }
}

# EC2 Instance
resource "aws_instance" "ubuntu_ec2" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = data.aws_subnets.default.ids[0]

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  # Root volume - 100GB GP3
  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    iops                  = 3000  # GP3 baseline IOPS
    throughput            = 125   # GP3 baseline throughput (MB/s)
    encrypted             = true
    delete_on_termination = true

    tags = {
      Name = "${var.instance_name}-root-volume"
    }
  }

  # Enable detailed monitoring (optional)
  monitoring = false

  # Metadata options (IMDSv2 recommended for security)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = {
    Name        = var.instance_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
