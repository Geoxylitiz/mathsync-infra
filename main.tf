module "network" {
  source = "./modules/network"
}

module "eks" {
  source = "./modules/eks"
}

module "iam" {
  source = "./modules/iam"
}

module "ecr" {
  source = "./modules/ecr"
}