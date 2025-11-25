provider "aws" {
  region = "ap-northeast-1"
  default_tags {
    tags = {
      Project     = "notree-dev"
      Environment = "dev"
      ManagedBy   = "Terraform"
    }
  }
}
