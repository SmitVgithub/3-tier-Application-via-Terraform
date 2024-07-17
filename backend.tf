resource "aws_instance" "backend" {
  ami               = "ami-0c2af51e265bd5e0e"  # Update with the latest Amazon Linux 2 AMI ID
  instance_type     = var.backend_instance_type
  subnet_id         = aws_subnet.public_b.id
  security_groups   = [aws_security_group.all_in_one_sg.id, aws_security_group.backend_lb_sg.id]
  key_name          = aws_key_pair.my_keypair.key_name

  tags = {
    Name = "${var.vpc_name}-backend-instance"
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update
              git clone https://github.com/henokrb/MERN-CRUD.git
              cd MERN-CRUD/server
              sudo apt install -y npm
              sudo npm install pm2 -g
              sed -i 's/YOUR-DB-SERVER-PUBLIC-IP/${aws_instance.database.public_ip}/g' server/db.js
              pm2 start node -- index.js
              EOF
}
