variable "project_name" { type = string }
variable "env" { type = string }
variable "vpc_id" { type = string }
variable "subnet_id" { type = string }
variable "key_name" { type = string }

variable "instance_type" {
  default = "t3.small"
}

variable "k3s_token" {
  type        = string
  description = "Token to join K3s cluster (get from master node)"
  sensitive   = true # ログに表示されないようにする
}
