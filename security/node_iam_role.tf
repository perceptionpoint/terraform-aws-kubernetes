resource "aws_iam_role" "eks-node-role" {
  name = var.node_iam_role_name

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

locals {
  eks_node_policies = merge({
    AmazonEKSWorkerNodePolicy = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    AmazonEKS_CNI_Policy = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  }, var.node_iam_role_extra_policies)
}


resource "aws_iam_role_policy_attachment" "eks-node-policies-attachement" {
  for_each = local.eks_node_policies
  policy_arn = each.value
  role       = aws_iam_role.eks-node-role.name
}
