data "aws_caller_identity" "current" {}

resource "aws_eks_cluster" "eks" {
  name     = var.eks_properties["name"]
  version = var.eks_properties["version"]
  role_arn = module.security.cluster_iam_role.arn

  enabled_cluster_log_types = [ "authenticator", ]

  vpc_config {
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
  eks_cluster_security_group_id = aws_eks_cluster.eks.vpc_config[0].cluster_security_group_id
  eks_cluster_api_allowed_cidr_blocks = var.eks_cluster_api_allowed_cidr_blocks
  eks_node_allowed_cidr_blocks = var.eks_node_allowed_cidr_blocks
  eks_properties = var.eks_properties
  node_iam_role_name = var.node_iam_role_name
  node_iam_role_extra_policies = var.node_iam_role_extra_policies
  describe_eks_endpoints_assuming_account_id = var.describe_eks_endpoints_assuming_account_id
}

module "eks-addons" {
  source = "./eks_addons"
  depends_on = [
    module.eks_node_group
  ]

  core_addon_properties = var.core_addon_properties
  eks_cluster_name = var.eks_properties["name"]
  oidc_provider = aws_iam_openid_connect_provider.oidc-provider
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

data "aws_region" "current" {}

resource "local_file" "kubeconfig_metadata_output_file" {
  count = var.kubeconfig_metadata_output_file == null ? 0 : 1

  filename = var.kubeconfig_metadata_output_file
  content = yamlencode({
    "cluster_name": var.eks_properties["name"],
    "cluster_region": data.aws_region.current.name,
    "assume_role": module.security.DescribeEksEndpointsRoleArn,
    "aliases": var.kubeconfig_cluster_aliases
  })
}
