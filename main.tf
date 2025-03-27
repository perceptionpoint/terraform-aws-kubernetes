data "aws_caller_identity" "current" {}

resource "aws_eks_cluster" "eks" {
  name     = var.eks_properties["name"]
  version = var.eks_properties["version"]
  role_arn = module.security.cluster_iam_role.arn

  enabled_cluster_log_types = [ "authenticator", ]

  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = false
  }

  vpc_config {
    subnet_ids = var.eks_subnet_ids

    endpoint_private_access = true
    endpoint_public_access = false
  }

  lifecycle {
    ignore_changes = [
      access_config[0].bootstrap_cluster_creator_admin_permissions,
      bootstrap_self_managed_addons,
    ]
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
  count = var.kubeconfig["metadata_output_file"] == null ? 0 : 1

  filename = var.kubeconfig["metadata_output_file"]
  content = yamlencode({
    "cluster_name": var.eks_properties["name"],
    "cluster_region": data.aws_region.current.name,
    "credentials": { "assume_role_arn": module.security.DescribeEksEndpointsRoleArn },
    "aliases": [ for e in var.kubeconfig["cluster_aliases"] : { for k, v in e : k => v if v != null } ],
    "aws_profile": var.kubeconfig["aws_profile"]
  })
}

data "aws_iam_roles" "eks_access_entries_roles" {
  for_each = {for k, v in var.eks_access_policy_associations : k => v if v["principal_type"] == "role" && v["principal_name_pattern"] != null }

  name_regex = each.value["principal_name_pattern"]
}

locals {
  eks_access_policy_associations = {
    karpenter_node_role = {
      policy_name = null
      principal_arn = module.karpenter[0].node_iam_role_arn
      principal_type = "role"
      access_scope_type = null
      principal_name_pattern = null
      access_scope_namespaces = null
      access_entry_type = "EC2_LINUX"
    }
  }
}



resource "aws_eks_access_entry" "eks_access_entry" {
  for_each = merge(local.eks_access_policy_associations, var.eks_access_policy_associations)

  cluster_name      = aws_eks_cluster.eks.name
  principal_arn     = (each.value["principal_type"] == "role" && each.value["principal_name_pattern"] != null)? tolist(data.aws_iam_roles.eks_access_entries_roles[each.key].arns)[0] : each.value["principal_arn"]
  type              = each.value["access_entry_type"]
}

resource "aws_eks_access_policy_association" "eks_access_policy_association" {
  for_each = { for k,v in merge(local.eks_access_policy_associations, var.eks_access_policy_associations) : k => v if v["access_entry_type"] == "STANDARD" }
  depends_on = [ aws_eks_access_entry.eks_access_entry ]

  cluster_name  = aws_eks_cluster.eks.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/${each.value["policy_name"]}"
  principal_arn = (each.value["principal_type"] == "role" && each.value["principal_name_pattern"] != null)? tolist(data.aws_iam_roles.eks_access_entries_roles[each.key].arns)[0] : each.value["principal_arn"]

  access_scope {
    type = each.value["access_scope_type"]
    namespaces = each.value["access_scope_namespaces"]
  }
}
