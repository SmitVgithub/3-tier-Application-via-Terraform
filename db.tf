resource "aws_instance" "database" {
  ami               = "ami-0c2af51e265bd5e0e"  # Update with the latest Amazon Linux 2 AMI ID
  instance_type     = var.db_instance_type
  subnet_id         = aws_subnet.public_b.id
  security_groups   = [aws_security_group.all_in_one_sg.id]
  key_name          = aws_key_pair.my_keypair.key_name

  tags = {
    Name = "${var.vpc_name}-database-instance"
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update
              sudo apt install -y mongodb-org
              sudo systemctl start mongod.service
              sudo systemctl status mongod.service
              sudo sed -i 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/' /etc/mongod.conf
              sudo systemctl restart mongod.service
              EOF
}
