# ---------------------------------------------------------
# Application Load Balancer
# ---------------------------------------------------------

resource "aws_lb" "app" {
  name               = "eightbyte-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [
    aws_security_group.alb.id
  ]

  subnets = [
    aws_subnet.public.id,
    aws_subnet.public_2.id
  ]

  tags = {
    Name = "eightbyte-${var.environment}-alb"
  }
}

# ---------------------------------------------------------
# Target Group
# ---------------------------------------------------------

resource "aws_lb_target_group" "app" {
  name        = "eightbyte-${var.environment}-tg"
  port        = 3000
  protocol    = "HTTP"
  target_type = "instance"

  vpc_id = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
  }

  tags = {
    Name = "eightbyte-${var.environment}-target-group"
  }
}

# ---------------------------------------------------------
# Register EC2 instance with Target Group
# ---------------------------------------------------------

resource "aws_lb_target_group_attachment" "app" {
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.app.id
  port             = 3000
}

# ---------------------------------------------------------
# HTTP Listener
# ---------------------------------------------------------

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "forward"

    forward {
      target_group {
        arn = aws_lb_target_group.app.arn
      }
    }
  }
}