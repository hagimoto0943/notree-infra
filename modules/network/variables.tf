variable "project_name" { type = string }
variable "env" { type = string }
variable "vpc_cidr" { type = string }

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "List of CIDR blocks for public subnets"
}

variable "azs" {
  type        = list(string)
  description = "List of Availability Zones"
}
