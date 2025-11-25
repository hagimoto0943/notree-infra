module "network" {
  source = "../../modules/network"

  project_name = "notree"
  env          = "dev"
  vpc_cidr     = "10.0.0.0/16"

  public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  azs                 = ["ap-northeast-1a", "ap-northeast-1c"]
}

module "k3s-cluster" {
  source = "../../modules/k3s-cluster"

  project_name = "notree"
  env          = "dev"

  vpc_id    = module.network.vpc_id
  subnet_id = module.network.public_subnet_ids[0]

  key_name = "notree-key"

  k3s_token = "K10eaa54c658f00007744de25624a3760c35fca7dd577f39f1b864e7135f1c9af2b::server:69dbbc28387b18dbca590d3ef97c2c33"
  s3_bucket_arn = module.s3.bucket_arn
}

output "k3s_master_ip" {
  value = module.k3s-cluster.master_public_ip
}

output "s3_bucket_name" {
  value = module.s3.bucket_name
}