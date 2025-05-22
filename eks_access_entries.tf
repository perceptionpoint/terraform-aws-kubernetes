data "aws_iam_roles" "eks_access_entries_roles" {
  for_each = {for k, v in var.eks_access_policy_associations : k => v if v["principal_type"] == "role" && v["principal_name_pattern"] != null }

  name_regex = each.value["principal_name_pattern"]
}

locals {
  eks_access_policy_associations = {
    karpenter_node_role = {
      policy_names = []
      principal_arn = module.karpenter[0].node_iam_role_arn
      principal_type = "role"
      access_scope_type = null
      principal_name_pattern = null
      access_scope_namespaces = null
      access_entry_type = "EC2_LINUX"
    }
  }
  eks_access_policy_associations_merged = merge(local.eks_access_policy_associations, var.eks_access_policy_associations)
  # only 1 policy per association allowed. to get more than 1 policy, so must explan the list and flatten
  eks_access_policy_associations_flattened = flatten([
    for pol_assoc_key, pol_assoc_val in local.eks_access_policy_associations_merged : [
      for p in pol_assoc_val["policy_names"] : {
        flatten_key = "${pol_assoc_key}/${p}"
        flatten_val = merge(
          { for k, v in pol_assoc_val : k => v if k != "policy_names"},
          { policy_name = p },
          { orig_assoc_key = pol_assoc_key },
        )
      }
    ]
  ])
}

resource "aws_eks_access_entry" "eks_access_entry" {
  for_each = local.eks_access_policy_associations_merged

  cluster_name      = aws_eks_cluster.eks.name
  principal_arn     = (each.value["principal_type"] == "role" && each.value["principal_name_pattern"] != null)? tolist(data.aws_iam_roles.eks_access_entries_roles[each.key].arns)[0] : each.value["principal_arn"]
  type              = each.value["access_entry_type"]
}

resource "aws_eks_access_policy_association" "eks_access_policy_association" {
  for_each = { for f in local.eks_access_policy_associations_flattened : f["flatten_key"] => f["flatten_val"] }
  depends_on = [ aws_eks_access_entry.eks_access_entry ]

  cluster_name  = aws_eks_cluster.eks.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/${each.value["policy_name"]}"
  principal_arn = (each.value["principal_type"] == "role" && each.value["principal_name_pattern"] != null)? tolist(data.aws_iam_roles.eks_access_entries_roles[each.value["orig_assoc_key"]].arns)[0] : each.value["principal_arn"]

  access_scope {
    type = each.value["access_scope_type"]
    namespaces = each.value["access_scope_namespaces"]
  }
}
