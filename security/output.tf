# eks cluster iam role
output "cluster_iam_role" {
  value = aws_iam_role.eks-cluster-role
}

output "node_iam_role" {
  value = aws_iam_role.eks-node-role
}

output "eks_node_sg" {
  value = aws_security_group.eks-node-sg.id
}
