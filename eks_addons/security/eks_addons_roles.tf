locals {
  eks_vpc_cni = "AWS_EKS_VPC_CNI"
  eks_ebs_csi_driver = "AWS_EKS_EBS_CSI_Driver"
}

resource "aws_iam_role" "eks-vpc-cni-role" {
  name = "${local.eks_vpc_cni}-${var.eks_cluster_name}"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_vpc_cni.json
}

resource "aws_iam_role_policy_attachment" "eks-vpc-cni-policies" {
  role       = aws_iam_role.eks-vpc-cni-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role" "eks-ebs-csi-driver-role" {
  name = "${local.eks_ebs_csi_driver}-${var.eks_cluster_name}"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_ebs_csi.json
}

resource "aws_iam_role_policy_attachment" "eks-ebs-csi-driver-policies" {
  role       = aws_iam_role.eks-ebs-csi-driver-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

data "aws_iam_policy_document" "assume_role_policy_vpc_cni" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type = "Federated"
      identifiers = [var.oidc_provider.arn]
    }

    condition {
      test = "StringEquals"
      variable = "${var.oidc_provider.url}:aud"
      values = ["sts.amazonaws.com"]
    }

    condition {
      test = "StringEquals"
      variable = "${var.oidc_provider.url}:sub"
      values = ["system:serviceaccount:kube-system:aws-node"]
    }

  }
}

data "aws_iam_policy_document" "assume_role_policy_ebs_csi" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type = "Federated"
      identifiers = [var.oidc_provider.arn]
    }

    condition {
      test = "StringEquals"
      variable = "${var.oidc_provider.url}:aud"
      values = ["sts.amazonaws.com"]
    }

    condition {
      test = "StringEquals"
      variable = "${var.oidc_provider.url}:sub"
      values = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

  }
}
