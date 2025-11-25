terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket         = "notree-dev-tfstate-repo"
    key            = "k3s-cluster/dev/terraform.tfstate"
    region         = "ap-northeast-1"
    encrypt        = true
    dynamodb_table = "notree-dev-tfstate-lock"
  }
}
