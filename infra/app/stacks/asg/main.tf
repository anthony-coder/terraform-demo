
#
locals {
  subnet_ids = ["subnet-7613ce2c","subnet-fb0b8a9d"]
}

data "aws_vpc" "default" {
  default = true
}

# LOOK UP OS IMAGE FOR OUR INSTANCE
data aws_ami example {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

# Create a security group
resource "aws_security_group" "example_sg" {
  name        = "example-sg"
  description = "Example security group"

  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = var.port
    to_port     = var.port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# Create a Launch Template
resource "aws_launch_template" "example_lt" {
  name          = "example-lt"
  image_id      = data.aws_ami.example.id
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.example_sg.id]
  key_name               = "macbook"

  user_data = filebase64("${path.module}/example.sh")

  # ... other instance configuration ...
}

# Create an Auto Scaling Group
resource "aws_autoscaling_group" "example_asg" {
  name                 = var.name

  launch_template {
    id      = aws_launch_template.example_lt.id
    version = "$Latest"
  }

  min_size             = var.min
  max_size             = var.max
  desired_capacity     = var.desired_capacity

  tag {
    key                 = "Name"
    value               = "demo2"
    propagate_at_launch = true
  }

  vpc_zone_identifier = local.subnet_ids

}

# Create a target group
resource "aws_lb_target_group" "example_tg" {
  name     = "example-tg"
  port     = var.port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path = "/health.html"
  }
}

# Attach target group to the autoscaling group
resource "aws_autoscaling_attachment" "example_asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.example_asg.name
  lb_target_group_arn    = aws_lb_target_group.example_tg.arn
}


# Create an Application Load Balancer
resource "aws_lb" "example_lb" {
  name               = "example-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups   = [aws_security_group.example_sg.id]
  subnets = local.subnet_ids

  enable_deletion_protection = false
}

resource "aws_lb_listener" "example_listener" {
  load_balancer_arn = aws_lb.example_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.example_tg.arn
    type             = "forward"
  }
}


data "aws_subnets" "default" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}