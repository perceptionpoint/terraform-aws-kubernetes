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

output "DescribeEksEndpointsRoleArn" {
  value = var.describe_eks_endpoints_assuming_account_id == null? "" : aws_iam_role.describe_eks_endpoints[0].arn
}
