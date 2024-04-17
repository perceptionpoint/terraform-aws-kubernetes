locals {
  instance_list = flatten([
    for type in var.node_group_properties["instance_requirements"]["allowed_instance_types"]:[
      for size in var.node_group_properties["instance_requirements"]["allowed_instance_size"]: "${type}.${size}"
    ]
  ])
}
resource "aws_eks_node_group" "node-group" {
  cluster_name    = var.eks_cluster_name
  node_group_name = var.node_group_properties["name"]
  ami_type = can(var.node_group_properties["ami_type"])? var.node_group_properties["ami_type"] : "AL2_x86_64"
  instance_types = length(local.instance_list)>40 ? slice(local.instance_list,0,40) : local.instance_list
  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  node_role_arn   = var.eks_node_role_arn
  launch_template {
    name = aws_launch_template.launch-template.name
    version = "$Latest"
  }
  subnet_ids      = var.node_group_properties["subnet_ids"]
  capacity_type   = var.node_group_properties["capacity_type"]
  tags            = var.node_group_properties["tags"]
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
    desired_size = 0
    max_size     = 1
    min_size     = 0
  }
  update_config {
    max_unavailable = 1
  }
  lifecycle {
    ignore_changes = [scaling_config[0]]
  }
}
