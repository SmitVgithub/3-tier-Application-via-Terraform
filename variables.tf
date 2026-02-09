# Project Configuration
variable "project_name" {
  description = "Name of the project, used for resource naming"
  type        = string
  default     = "3tier-app"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

# Common Tags
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project   = "3-tier-application"
    ManagedBy = "Terraform"
  }
}

# Networking Variables
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "Must be a valid CIDR block."
  }
}

variable "availability_zones" {
  description = "List of availability zones. If empty, will auto-detect available AZs."
  type        = list(string)
  default     = []
}

variable "az_count" {
  description = "Number of availability zones to use (when auto-detecting)"
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3
    error_message = "AZ count must be between 2 and 3."
  }
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

# Health Check Configuration
variable "frontend_health_check_path" {
  description = "Health check path for frontend target group"
  type        = string
  default     = "/health"
}

variable "backend_health_check_path" {
  description = "Health check path for backend target group"
  type        = string
  default     = "/api/health"
}

# Database Variables
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Name of the database"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "db_multi_az" {
  description = "Enable Multi-AZ deployment for RDS"
  type        = bool
  default     = false
}

# EC2 Variables
variable "frontend_instance_type" {
  description = "EC2 instance type for frontend"
  type        = string
  default     = "t3.micro"
}

variable "backend_instance_type" {
  description = "EC2 instance type for backend"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
  default     = ""
}

# Auto Scaling Variables
variable "frontend_min_size" {
  description = "Minimum number of frontend instances"
  type        = number
  default     = 1
}

variable "frontend_max_size" {
  description = "Maximum number of frontend instances"
  type        = number
  default     = 3
}

variable "frontend_desired_capacity" {
  description = "Desired number of frontend instances"
  type        = number
  default     = 2
}

variable "backend_min_size" {
  description = "Minimum number of backend instances"
  type        = number
  default     = 1
}

variable "backend_max_size" {
  description = "Maximum number of backend instances"
  type        = number
  default     = 3
}

variable "backend_desired_capacity" {
  description = "Desired number of backend instances"
  type        = number
  default     = 2
}
