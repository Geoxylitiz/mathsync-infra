# Read outputs from the 01-cluster layer
data "terraform_remote_state" "cluster" {
  backend = "local"

  config = {
    path = "${path.module}/../cluster/terraform.tfstate"
  }

}

provider "aws" {
  region = data.terraform_remote_state.cluster.outputs.aws_region
}

data "aws_eks_cluster_auth" "cluster" {
  name = data.terraform_remote_state.cluster.outputs.cluster_name
}

provider "kubernetes" {
  host                   = data.terraform_remote_state.cluster.outputs.cluster_endpoint
  cluster_ca_certificate = base64decode(data.terraform_remote_state.cluster.outputs.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
}

provider "helm" {
  kubernetes {
    host                   = data.terraform_remote_state.cluster.outputs.cluster_endpoint
    cluster_ca_certificate = base64decode(data.terraform_remote_state.cluster.outputs.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}
