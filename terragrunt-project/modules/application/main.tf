# Application Module - AWS Infrastructure

# Security group for application
resource "aws_security_group" "application" {
  name        = "${var.application_name}-sg"
  description = "Security group for ${var.application_name}"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.application_name}-sg"
    }
  )
}

# Application Load Balancer
resource "aws_lb" "application" {
  count = var.enable_load_balancer ? 1 : 0

  name               = "${var.application_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.application.id]
  subnets            = var.subnet_ids

  enable_deletion_protection = false

  tags = merge(
    var.tags,
    {
      Name = "${var.application_name}-alb"
    }
  )
}

# Target group for ALB
resource "aws_lb_target_group" "application" {
  count = var.enable_load_balancer ? 1 : 0

  name     = "${var.application_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = var.health_check_path
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.application_name}-tg"
    }
  )
}

# ALB Listener
resource "aws_lb_listener" "application" {
  count = var.enable_load_balancer ? 1 : 0

  load_balancer_arn = aws_lb.application[0].arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.application[0].arn
  }
}

# Launch template for application instances
resource "aws_launch_template" "application" {
  name_prefix   = "${var.application_name}-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.application.id]

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    application_name    = var.application_name
    application_version = var.application_version
    database_endpoint   = var.database_endpoint
  }))

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.tags,
      {
        Name = "${var.application_name}-instance"
      }
    )
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.application_name}-lt"
    }
  )
}

# Auto Scaling Group
resource "aws_autoscaling_group" "application" {
  name                = "${var.application_name}-asg"
  vpc_zone_identifier = var.subnet_ids
  target_group_arns   = var.enable_load_balancer ? [aws_lb_target_group.application[0].arn] : []
  health_check_type   = var.enable_load_balancer ? "ELB" : "EC2"
  health_check_grace_period = 300

  min_size         = var.min_instances
  max_size         = var.max_instances
  desired_capacity = var.replica_count

  launch_template {
    id      = aws_launch_template.application.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.application_name}-instance"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}
