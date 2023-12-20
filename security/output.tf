# eks cluster iam role arn
output "cluster_iam_role" {
  value = aws_iam_role.eks-cluster-role.arn
}

# eks cluster security gourp id
output "eks_cluster_sg" {
  value = aws_security_group.eks-cluster-sg.id
}

output "eks_node_sg" {
  value = aws_security_group.eks-node-sg.id
}
