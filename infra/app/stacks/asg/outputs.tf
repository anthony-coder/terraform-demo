# Create an output value for the ALB's DNS name
output "alb_dns_name" {
  value = aws_lb.example_lb.dns_name
}
