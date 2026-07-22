# 1. Network Module: Creates VPC and Subnets
module "network" {
  source       = "./modules/network"
  project_name = var.project_name
}

# 2. IAM Module: Creates the roles for EKS and Nodes
module "iam" {
  source       = "./modules/iam"
  project_name = var.project_name
}

# 3. EKS Module: Creates the cluster and node groups
module "eks" {
  source             = "./modules/eks"
  project_name       = var.project_name
  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  cluster_role_arn   = module.iam.cluster_role_arn
  node_role_arn      = module.iam.node_role_arn
}
