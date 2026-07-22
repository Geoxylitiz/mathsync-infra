output "cluster_role_arn" {
  value = aws_iam_role.eks_cluster.arn
  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy
  ]
}

output "node_role_arn" {
  value = aws_iam_role.node_group.arn
  depends_on = [
    aws_iam_role_policy_attachment.worker_nodes,
    aws_iam_role_policy_attachment.cni,
    aws_iam_role_policy_attachment.ecr
  ]
}