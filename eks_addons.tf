resource "aws_eks_addon" "eks_addon" {
  for_each = var.addon_properties

  cluster_name = var.eks_properties["name"]
  addon_name = each.key
  addon_version = each.value["addon_version"]
  configuration_values = each.value["configuration_values"]
  service_account_role_arn = each.value["service_account_role_arn"]
  resolve_conflicts_on_create = each.value["resolve_conflicts_on_create"]
  resolve_conflicts_on_update = each.value["resolve_conflicts_on_update"]

  lifecycle {
    prevent_destroy = true
  }
}
