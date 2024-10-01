locals {

  default_instance_types_amd64 = [ "m5a", "m5ad","m5d", "r4", "r5", "r5a", "r5ad", "r5b", "r5d", "r5dn", "r5n", "c5a", "c5ad", "c5d", "c5n", "m6a", "m6i", "m6id", "m6idn", "m6in", "r6a", "r6i", "r6id", "r6idn", "r6in", "c6a", "c6i", "c6id", "c6in"]
  default_instance_sizes = ["4xlarge", "8xlarge", "16xlarge"]
  instance_list = flatten([
    for type in try(var.node_group_properties["instance_requirements"]["allowed_instance_types"], local.default_instance_types_amd64):[
      for size in try(var.node_group_properties["instance_requirements"]["allowed_instance_size"], local.default_instance_sizes): "${type}.${size}"
    ]
  ])
}
resource "aws_eks_node_group" "node-group" {
  cluster_name    = var.eks_cluster_name
  node_group_name = var.node_group_properties["name"]
  ami_type = var.node_group_properties["ami_type"]
  version = var.eks_cluster_version
  instance_types = length(local.instance_list)>40 ? slice(local.instance_list,0,40) : local.instance_list
  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  node_role_arn   = var.eks_node_role_arn
  launch_template {
    name = aws_launch_template.launch-template.name
    version = aws_launch_template.launch-template.latest_version
  }
  subnet_ids      = var.node_group_properties["subnet_ids"]
  capacity_type   = var.node_group_properties["capacity_type"]
  labels          = var.node_group_properties["labels"]
  dynamic taint {
    for_each = var.node_group_properties["taints"]
    content {
      key = taint.value["key"]
      value = taint.value["value"]
      effect = taint.value["effect"]
    }
  }

  scaling_config {
    desired_size = var.node_group_properties["min_size"]
    max_size     = (var.node_group_properties["max_size"] < var.node_group_properties["min_size"])? var.node_group_properties["min_size"] : var.node_group_properties["max_size"]
    min_size     = var.node_group_properties["min_size"]
  }
  update_config {
    max_unavailable = 1
  }
  lifecycle {
    ignore_changes = [scaling_config[0]]
  }
}
