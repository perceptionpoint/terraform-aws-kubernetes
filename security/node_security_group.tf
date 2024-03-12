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

  ingress {
    description        = "Allow node to communicate with each other"
    from_port          = 0
    to_port            = 0
    protocol           = "-1"
    self               = true
  }

  ingress {
    description        = "Allow Kubelets and pods to receive communication from the cluster control plane"
    from_port          = 1025
    to_port            = 65535
    protocol           = "tcp"
    security_groups    = [aws_security_group.eks-cluster-sg.id]
  }

  ingress {
    description        = "Allow Kubelets and pods to receive https communication from the cluster control plane"
    from_port          = 443
    to_port            = 443
    protocol           = "tcp"
    security_groups    = [aws_security_group.eks-cluster-sg.id]
  }

  tags = {
    "Name" = "${var.eks_properties["node_security_group_name"]}"
    "kubernetes.io/cluster/${var.eks_properties["name"]}" = "owned"
  }
}
