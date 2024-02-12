resource "aws_eks_cluster" "eks" {
  name     = var.eks_properties["name"]
  version = var.eks_properties["version"]
  role_arn = module.security.cluster_iam_role

  enabled_cluster_log_types = [ "authenticator", ]

  vpc_config {
    security_group_ids = [module.security.eks_cluster_sg]
    subnet_ids = var.eks_subnet_ids

    endpoint_private_access = true
    endpoint_public_access = false
  }
}

data "tls_certificate" "thumbprint-list" {
  url = aws_eks_cluster.eks.identity.0.oidc.0.issuer
}

resource "aws_iam_openid_connect_provider" "oidc-provider" {
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.thumbprint-list.certificates.0.sha1_fingerprint]
  url = aws_eks_cluster.eks.identity.0.oidc.0.issuer
}

module "security" {
  source  = "./security"

  vpc_id = var.vpc_id
  eks_cluster_api_allowed_cidr_blocks = var.eks_cluster_api_allowed_cidr_blocks
  eks_properties = var.eks_properties
}

module "aws-eks-addon" {
  source  = "./aws-eks-addon"
  
  eks_properties = var.eks_properties
  addon_properties = var.addon_properties
}