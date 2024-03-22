resource "aws_security_group" "eks-node-sg" {
  name        = "${var.eks_properties["node_security_group_name"]}"
  description = "Security group for all nodes in the cluster"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name" = "${var.eks_properties["node_security_group_name"]}"
    "kubernetes.io/cluster/${var.eks_properties["name"]}" = "owned"
  }
}

#TODO: move all sg-rules inside the sg after solving the dynamic rule that aws-load-balancer-controller creates
resource "aws_security_group_rule" "eks-node-ingress-self" {
  description                   = "Allow nodes to communicate with each other"
  from_port                     = 0
  to_port                       = 0
  protocol                      = "-1"
  security_group_id             = aws_security_group.eks-node-sg.id
  source_security_group_id      = aws_security_group.eks-node-sg.id
  type                          = "ingress"
}

resource "aws_security_group_rule" "eks-node-ingress-cluster-api-high-ports" {
  description                   = "Allow nodes to communicate on high_ports with eks_cluster_api_server"
  from_port                     = 1025
  to_port                       = 65535
  protocol                      = "tcp"
  security_group_id             = aws_security_group.eks-node-sg.id
  source_security_group_id      = aws_security_group.eks-cluster-sg.id
  type                          = "ingress"
}

resource "aws_security_group_rule" "eks-node-ingress-cluster-api-https" {
  description                   = "Allow nodes to communicate on https with eks_cluster_api_server"
  from_port                     = 443
  to_port                       = 443
  protocol                      = "tcp"
  security_group_id             = aws_security_group.eks-node-sg.id
  source_security_group_id      = aws_security_group.eks-cluster-sg.id
  type                          = "ingress"
}

resource "aws_security_group_rule" "eks-node-ingress-allowed-all" {
  for_each = var.eks_node_allowed_cidr_blocks

  description               = "Allow ${each.key} to communicate with eks_cluster_api_server"
  from_port                 = 0
  to_port                   = 0
  protocol                  = "-1"
  security_group_id         = aws_security_group.eks-node-sg.id
  cidr_blocks               = [each.value]
  type                      = "ingress"
}
