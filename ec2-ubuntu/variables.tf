# Variables for EC2 Ubuntu Instance

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-south-1" # Mumbai region
}

variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
  default     = "ubuntu-ec2-server"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "c6a.large"
}

variable "root_volume_size" {
  description = "Size of the root volume in GB"
  type        = number
  default     = 100
}

variable "environment" {
  description = "Environment tag for the resources"
  type        = string
  default     = "development"
}
