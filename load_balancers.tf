resource "aws_lb" "frontend_lb" {
  name               = "frontend-lb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.frontend_lb_sg.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  tags = {
    Name = "frontend-lb"
  }
}

resource "aws_lb" "backend_lb" {
  name               = "backend-lb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.backend_lb_sg.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  tags = {
    Name = "backend-lb"
  }
}
