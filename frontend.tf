
resource "aws_instance" "frontend" {
  ami               = "ami-0c2af51e265bd5e0e"  # Update with the latest Amazon Linux 2 AMI ID
  instance_type     = var.frontend_instance_type
  subnet_id         = aws_subnet.public_a.id
  security_groups   = [aws_security_group.all_in_one_sg.id, aws_security_group.frontend_lb_sg.id]
  key_name          = aws_key_pair.my_keypair.key_name

  tags = {
    Name = "${var.vpc_name}-frontend-instance"
  }

  user_data = <<-EOF
              #!/bin/bash
              # Update the package repository
              sudo apt update -y
              git clone https://github.com/henokrb/MERN-CRUD.git
              cd MERN-CRUD/client
              sudo apt install -y npm
              npm install
              npm start
              EOF

}

