# Application Load Balancer for Frontend
resource "aws_lb" "frontend_alb" {
  name               = "${var.project_name}-frontend-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.public_subnet[*].id

  enable_deletion_protection = false

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-frontend-alb"
  })
}

# Application Load Balancer for Backend
resource "aws_lb" "backend_alb" {
  name               = "${var.project_name}-backend-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.backend_alb_sg.id]
  subnets            = aws_subnet.private_subnet[*].id

  enable_deletion_protection = false

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-backend-alb"
  })
}

# Frontend Target Group with Health Check Configuration
resource "aws_lb_target_group" "frontend_tg" {
  name                 = "${var.project_name}-frontend-tg"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = aws_vpc.main.id
  target_type          = "instance"
  deregistration_delay = 30

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = var.frontend_health_check_path
    port                = "traffic-port"
    protocol            = "HTTP"
    matcher             = "200-299"
  }

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400
    enabled         = false
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-frontend-tg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Backend Target Group with Health Check Configuration
resource "aws_lb_target_group" "backend_tg" {
  name                 = "${var.project_name}-backend-tg"
  port                 = 8080
  protocol             = "HTTP"
  vpc_id               = aws_vpc.main.id
  target_type          = "instance"
  deregistration_delay = 30

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = var.backend_health_check_path
    port                = "traffic-port"
    protocol            = "HTTP"
    matcher             = "200-299"
  }

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400
    enabled         = false
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-backend-tg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Frontend ALB Listener
resource "aws_lb_listener" "frontend_listener" {
  load_balancer_arn = aws_lb.frontend_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-frontend-listener"
  })
}

# Backend ALB Listener
resource "aws_lb_listener" "backend_listener" {
  load_balancer_arn = aws_lb.backend_alb.arn
  port              = 8080
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-backend-listener"
  })
}
