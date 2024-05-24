data "aws_caller_identity" "current" {}

resource "aws_eks_cluster" "eks" {
  name     = var.eks_properties["name"]
  version = var.eks_properties["version"]
  role_arn = module.security.cluster_iam_role.arn

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
  eks_node_allowed_cidr_blocks = var.eks_node_allowed_cidr_blocks
  eks_properties = var.eks_properties
  node_iam_role_name = var.node_iam_role_name
  node_iam_role_extra_policies = var.node_iam_role_extra_policies
}

module "eks_node_group" {
  source = "./eks_node_group"
  for_each = var.node_group_properties

  node_group_properties = each.value
  eks_cluster_name = aws_eks_cluster.eks.name
  eks_node_role_arn = module.security.node_iam_role.arn
  eks_node_sg = module.security.eks_node_sg
  eks_cluster_endpoint = aws_eks_cluster.eks.endpoint
  eks_cluster_ca = aws_eks_cluster.eks.certificate_authority.0.data
}

module "karpenter" {
  source = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "20.8.5"

  cluster_name = aws_eks_cluster.eks.id
  node_iam_role_name = "KarpenterNodeRoleTF-${var.karpenter_role_name_extension}"
  iam_role_name = "KarpenterControllerTF-${var.karpenter_role_name_extension}"

  # Attach additional IAM policies to the Karpenter node IAM role
  node_iam_role_additional_policies = var.node_iam_role_extra_policies


  irsa_oidc_provider_arn = replace(aws_eks_cluster.eks.identity[0].oidc[0].issuer, "https://", "arn:aws:iam::${data.aws_caller_identity.current.id}:oidc-provider/")

  create_access_entry = false
  create_instance_profile = true
  enable_irsa = true

  count = var.enable_karpenter_creation ? 1 : 0
}