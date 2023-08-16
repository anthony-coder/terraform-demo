variable "port" {
  description = "Port for server"
  type        = number
  default     = 8080
}

variable "image_id" {
  description = "Image to be used by instance within ASG"
  type        = string
  default     = null
}

variable "name" {
  description = "Name to be given to the instances within an ASG"
  type        = string
  default     = null
}

variable "instance_type" {
  description = "type of instance"
  type        = string
  default     = "t2.micro"
}

variable "min" {
  description = "Min size of ASG"
  type        = number
  default     = 1
}

variable "max" {
  description = "Max size of ASG"
  type        = number
  default     = 1
}

variable "desired_capacity" {
  description = "Desired Capacity of ASG"
  type        = number
  default     = 1
}