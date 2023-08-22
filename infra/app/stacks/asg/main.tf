
# Local Subnet IDs
locals {
  subnet_ids = ["subnet-7613ce2c", "subnet-fb0b8a9d"]
}

# Use the Default VPC in our AWS account
data "aws_vpc" "default" {
  default = true
}

# LOOK UP OS IMAGE FOR OUR INSTANCE
data "aws_ami" "example" {
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
    from_port   = var.port  # defaults to 8080
    to_port     = var.port  # defaults to 8080
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
  name                   = "example-lt"
  image_id               = data.aws_ami.example.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.example_sg.id]
  key_name               = "macbook"

  #user_data = filebase64("${path.module}/example.sh")
  user_data = base64encode(<<-EOF
        #!/bin/bash
        echo '<!DOCTYPE html>
                <html>
                <head>
                    <title>Terraform Demo</title>
                    <style>
                        body {
                            font-family: Arial, sans-serif;
                        }
                        .container {
                            text-align: center;
                            margin-top: 100px;
                        }
                        .title {
                            font-size: 24px;
                            font-weight: bold;
                        }
                        .section {
                             margin: 20px 0; /* Add margin to create space above and below each section */
                        }
                        .instance-id {
                            font-size: 18px;
                        }
                    </style>
                </head>
                <body>
                    <div class="container">
                        <div class="title">Terraform Demo</div>
                        <div class="instance-id">
                            Instance ID is: <span id="instance-id"></span>
                        </div>
                         <div class="availability-zone">
                            Availability Zone: <span id="availability-zone"></span>
                         </div>
                    </div>
                </body>
                </html>' > index.html
        INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
        AVAILABILITY_ZONE=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)

        sed -i "s|<span id=\"instance-id\"></span>|<span id=\"instance-id\">$INSTANCE_ID</span>|g" index.html
        sed -i "s|<span id=\"availability-zone\"></span>|<span id=\"availability-zone\">$AVAILABILITY_ZONE</span>|g" index.html

        nohup busybox httpd -f -p ${var.port} &
        EOF
  )
  # ... other instance configuration ...
}

# Create an Auto Scaling Group
resource "aws_autoscaling_group" "example_asg" {
  name = var.name

  launch_template {
    id      = aws_launch_template.example_lt.id
    version = "$Latest"
  }

  min_size         = var.min
  max_size         = var.max
  desired_capacity = var.desired_capacity

  tag {
    key                 = "Name"
    value               = "demo2"
    propagate_at_launch = true
  }

  target_group_arns   = [aws_lb_target_group.example_tg.arn]
  vpc_zone_identifier = local.subnet_ids

}

# Create a target group to provide configuration for Load Balancer with ASG
resource "aws_lb_target_group" "example_tg" {
  name     = "example-tg"
  port     = var.port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Attach target group to the autoscaling group
resource "aws_autoscaling_attachment" "example_asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.example_asg.name
  lb_target_group_arn    = aws_lb_target_group.example_tg.arn
}


# Create a security group
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Example ALB security group"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an Application Load Balancer
resource "aws_lb" "example_lb" {
  name               = "example-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = local.subnet_ids

  enable_deletion_protection = false
}

# Create an ALB Listener 
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.example_tg.arn
    type             = "forward"
  }
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100
  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.example_tg.arn
  }
}


data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}