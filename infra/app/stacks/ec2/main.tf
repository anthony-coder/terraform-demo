# PROVIDER SETS UP OUR CONNECTION TO A CLOUD
provider aws {
  region     = "us-west-1" 
}

# AWS EC2 INSTANCE - VM running Ubuntu in AWS
resource aws_instance example {
  ami           = data.aws_ami.example.id
  instance_type = "t2.micro"

  # PASS SHELL SCRIPT TO CONFIGURE THE VM
  user_data = <<-EOF
    #!/bin/bash
    echo "Terraform Web Service Demo" > index.html
    echo "This is an HTML file being served on a VM" >> index.html
    nohup busybox httpd -f -p ${var.port} &
    EOF

  user_data_replace_on_change = true

  # ASSOCIATE THE SECURITY GROUP RULE WITH THE INSTANCE
  security_groups = [aws_security_group.example.name]

  tags = {
    Name = "web-server"
  }
}

# LOOK UP OS IMAGE (AMI) FOR OUR INSTANCE TO USE
data aws_ami example {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

# SECURITY GROUP RULE TO ALLOW INBOUND TRAFFIC
resource "aws_security_group" "example" {
  name_prefix = "vm-asg-"

  # DEFINES INGRESS RULE
  ingress {
    from_port   = var.port
    to_port     = var.port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # DEFINES EGRESS RULE
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}