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
  eks_node_policies = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ]
}

resource "aws_iam_role_policy_attachment" "eks-node-policies-attachement" {
  policy_arn = element(local.eks_node_policies, count.index)
  role       = aws_iam_role.eks-node-role.name
  count = length(local.eks_node_policies)
}
