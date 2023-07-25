variable "notebook_name" {
  description = "(Optional) A mapping of tags to assign to the bucket."
  type        = string
  default     = "dev"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
  default     = ""
}

variable "subnet_id" {
  description = "subnet id"
  type        = string
  default     = ""
}
