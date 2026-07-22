output "aws_region" {
  description = "AWS Region"
  value       = var.aws_region
}

output "cluster_name" {
  description = "EKS Cluster Name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS Cluster Endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "EKS Cluster CA Certificate Data"
  value       = module.eks.cluster_certificate_authority_data
}
