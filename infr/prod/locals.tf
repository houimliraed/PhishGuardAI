locals {
  prefix = "phishguard"
}

data "aws_availability_zones" "available" {
  state = "available"
}
