module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = "${var.project_name}-cluster"
  kubernetes_version = "1.32"

  create_iam_role = false
  iam_role_arn = var.cluster_role_arn  
  endpoint_public_access = true

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  enable_cluster_creator_admin_permissions = true

  addons = {
    vpc-cni = {
      before_compute = true
    }
    kube-proxy = {}
    coredns    = {}
  }

  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.small"]
      min_size       = 2
      max_size       = 4
      desired_size   = 2

      create_iam_role = false
      iam_role_arn = var.node_role_arn   
    }
  }
}