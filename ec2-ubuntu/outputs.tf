# Outputs for EC2 Ubuntu Instance

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.ubuntu_ec2.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.ubuntu_ec2.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.ubuntu_ec2.private_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.ubuntu_ec2.public_dns
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.ec2_sg.id
}

output "ami_id" {
  description = "AMI ID used for the instance"
  value       = data.aws_ami.ubuntu.id
}

output "ami_name" {
  description = "Name of the AMI used"
  value       = data.aws_ami.ubuntu.name
}

output "availability_zone" {
  description = "Availability zone of the instance"
  value       = aws_instance.ubuntu_ec2.availability_zone
}
