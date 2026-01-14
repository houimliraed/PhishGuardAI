# Application Load Balancer for EKS

resource "aws_lb" "main" {
  name               = "${local.prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  enable_deletion_protection = false
  enable_http2              = true
  enable_cross_zone_load_balancing = true

  tags = {
    Name = "${local.prefix}-alb"
  }
}

# Security group for ALB
resource "aws_security_group" "alb" {
  description = "Security group for Application Load Balancer"
  name        = "${local.prefix}-alb-sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.prefix}-alb-sg"
  }
}

# Target group for backend service
resource "aws_lb_target_group" "backend" {
  name        = "${local.prefix}-backend-tg"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    path                = "/"
    matcher             = "200"
  }

  tags = {
    Name = "${local.prefix}-backend-tg"
  }
}

# ALB Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
}

# Output ALB DNS
output "load_balancer_dns" {
  value       = aws_lb.main.dns_name
  description = "DNS name of the load balancer"
}

output "load_balancer_arn" {
  value       = aws_lb.main.arn
  description = "ARN of the load balancer"
}

output "backend_target_group_arn" {
  value       = aws_lb_target_group.backend.arn
  description = "ARN of the backend target group"
}
