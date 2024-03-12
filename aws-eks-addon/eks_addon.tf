resource "aws_eks_addon" "eks_addon" {
    for_each = var.addon_properties
  cluster_name = var.eks_properties["name"]
  addon_name = each.key
  addon_version = each.value
  resolve_conflicts_on_update = "PRESERVE"
}
