variable "node_group_properties" {
  type = object({
    name = string
    subnet_ids = list(string)
    capacity_type = string
    ami_type = optional(string, "AL2_x86_64")
    instance_requirements = optional(object({
      allowed_instance_types = list(string)
      allowed_instance_size = list(string)
    }))
    user_data_suffix = optional(string, "")
    imdsv2_enabled = optional(bool, true)
    block_device_mappings = optional(map(object({
      device_name = string
      ebs = object({
          iops = number
          throughput = number
          volume_size = number
      })
    })))
    min_size = optional(number, 0)
    max_size = optional(number, 1)
    tags = map(string)
    labels = map(string)
    taints = list(object({
        key = string
        value = optional(string, "")
        effect = optional(string, "NO_SCHEDULE")
    }))
  })
}
variable "eks_cluster_name" {}
variable "eks_node_role_arn" {}
variable "eks_node_sg" {}
variable "eks_cluster_endpoint" {}
variable "eks_cluster_ca" {}
variable "eks_cluster_version" {}
