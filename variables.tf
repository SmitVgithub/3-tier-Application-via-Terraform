# variables.tf
variable "aws_region" {
  description = "The AWS region to deploy resources in."
  default     = "ap-south-1"
}

variable "vpc_name"{
  default = "cirrops"
}

variable "frontend_instance_type" {
  description = "EC2 instance type for the frontend."
  default     = "t2.micro"
}

variable "backend_instance_type" {
  description = "EC2 instance type for the backend."
  default     = "t2.micro"
}

variable "db_instance_type" {
  description = "EC2 instance type for the MongoDB."
  default     = "t2.micro"
}

