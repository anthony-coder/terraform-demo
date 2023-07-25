module "jupyter-notebook" {
  source    = "garyellis/jupyter-notebook/aws"
  version   = "0.1.1"
  name      = var.notebook_name
  vpc       = var.vpc_id
  subnet_id = var.subnet_id
  # insert the 3 required variables here
}