output "eks_cluster_endpoint" {
  value = aws_eks_cluster.eks.endpoint
}

output "eks_cluster_ca" {
  value = aws_eks_cluster.eks.certificate_authority.0.data
}

output "eks_node_sg_id" {
  value = module.security.eks_node_sg
}
output "karpenter_node_instance_profile_name" {
  value = module.karpenter[0].instance_profile_name
}
output "karpenter_controller_role_arn" {
  value = module.karpenter[0].iam_role_arn
}
output "karpenter_interruption_queue_name" {
  value = module.karpenter[0].queue_name
}