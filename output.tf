output "k8s_cluster_endpoint" {
  value = aws_eks_cluster.eks.endpoint
}

output "k8s_cluster_ca" {
  value = aws_eks_cluster.eks.certificate_authority.0.data
}

output "eks_node_sg_id" {
  value = module.security.eks_node_sg
}
