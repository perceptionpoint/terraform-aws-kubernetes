resource "aws_security_group" "eks-cluster-sg" {
  name        = "${var.eks_properties["cluster_security_group_name"]}"
  description = "Cluster communication with worker nodes"
  vpc_id      = var.vpc_id

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.eks_properties["cluster_security_group_name"]}"
  }
}

resource "aws_security_group_rule" "eks-cluster-ingress-allowed-https" {
  for_each = var.eks_cluster_api_allowed_cidr_blocks

  description              = "Allow ${each.key} to communicate with the cluster API Server"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks-cluster-sg.id
  cidr_blocks              = [each.value]
  type                     = "ingress"
}

resource "aws_security_group_rule" "eks-cluster-ingress-node-https" {
  description              = "Allow pods to communicate with the cluster API Server"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks-cluster-sg.id
  source_security_group_id = aws_security_group.eks-node-sg.id
  type                     = "ingress"
}
