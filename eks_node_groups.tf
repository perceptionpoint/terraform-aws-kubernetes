module "eks_node_group" {
  source = "./eks_node_group"
  for_each = merge(local.core_node_group_properties, var.extra_node_group_properties)

  node_group_properties = each.value
  eks_cluster_name = aws_eks_cluster.eks.name
  eks_node_role_arn = module.security.node_iam_role.arn
  eks_node_sg = module.security.eks_node_sg
  eks_cluster_endpoint = aws_eks_cluster.eks.endpoint
  eks_cluster_ca = aws_eks_cluster.eks.certificate_authority.0.data
  eks_cluster_version = var.eks_properties["version"]
}

locals {
  core_node_group_properties = {
    coredns = {
      name = "coredns"
      subnet_ids = var.core_node_group_properties["coredns"]["subnet_ids"]
      capacity_type = "ON_DEMAND"
      instance_requirements = {
        allowed_instance_types = ["t3"]
        allowed_instance_size = ["medium"]
      }
      min_size = 1
      tags = var.core_node_group_properties["coredns"]["tags"]
      labels = { componentType = "coredns" }
      taints = [{ key = "perception-point.io/coredns" }]
      user_data_suffix = var.core_node_group_properties["coredns"]["user_data_suffix"]
    }
    karpenter-node = {
      name = "karpenter-node"
      subnet_ids = var.core_node_group_properties["karpenter-node"]["subnet_ids"]
      capacity_type = "ON_DEMAND"
      min_size = 1
      tags = var.core_node_group_properties["karpenter-node"]["tags"]
      labels = { componentType = "karpenter-node" }
      taints = [{ key = "perception-point.io/karpenter-node" }]
      user_data_suffix = var.core_node_group_properties["karpenter-node"]["user_data_suffix"]
    }
    system-critical = {
      name = "system-critical"
      subnet_ids = var.core_node_group_properties["system-critical"]["subnet_ids"]
      capacity_type = "ON_DEMAND"
      tags = var.core_node_group_properties["system-critical"]["tags"]
      labels = { componentType = "system-critical" }
      taints = [{ key = "perception-point.io/system-critical" }]
      user_data_suffix = var.core_node_group_properties["system-critical"]["user_data_suffix"]
    }
    nat-worker = {
      name = "nat-worker"
      subnet_ids = var.core_node_group_properties["nat-worker"]["subnet_ids"]
      capacity_type = "SPOT"
      tags = var.core_node_group_properties["nat-worker"]["tags"]
      labels = { componentType = "smtp-worker-karpenter" }
      taints = [{ key = "perception-point.io/nat" }]
      user_data_suffix = var.core_node_group_properties["nat-worker"]["user_data_suffix"]
    }
    gpu-worker = {
      name = "gpu-worker"
      subnet_ids = var.core_node_group_properties["gpu-worker"]["subnet_ids"]
      capacity_type = "SPOT"
      ami_type = "AL2_x86_64_GPU"
      instance_requirements = {
        allowed_instance_types = ["g4dn"]
        allowed_instance_size = ["xlarge"]
      }
      tags = var.core_node_group_properties["gpu-worker"]["tags"]
      labels = { componentType = "gpu-worker" }
      taints = [{ key = "nvidia.com/gpu" }]
      user_data_suffix =<<EOF
${local.gpu_user_data}
${var.core_node_group_properties["gpu-worker"]["user_data_suffix"]}
  EOF
    }
  }
  gpu_user_data =<<EOF
distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
  && curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.repo | sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo

sudo yum-config-manager --disable amzn2-nvidia
sudo yum clean expire-cache
sudo yum install -y nvidia-docker2
sudo yum-config-manager --enable amzn2-nvidia
  EOF
}
