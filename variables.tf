variable "eks_properties" { type = object({
        name = string
        version = number
        node_security_group_name = string
        cluster_security_group_name = string
        cluster_role_name = string
})}
variable "vpc_id" {}
variable "eks_cluster_api_allowed_cidr_blocks" {
        type = map(string)
        default = {}
}
variable "eks_node_allowed_cidr_blocks" {
        type = map(string)
        default = {}
}
variable "eks_subnet_ids" { type = list(string) }
variable "node_iam_role_name" {}
variable "addon_properties" { type = map(string) }
variable "node_group_properties" {
  default = {}
  type = map(object({
    name = string
    subnet_ids = list(string)
    capacity_type = string
    instance_requirements = object({
      allowed_instance_types = list(string)
      min_vcpu_count = optional(number, 1)
      max_vcpu_count = optional(number, null)
    })
    user_data = string
    imdsv2_enabled = optional(bool, false)
    block_device_mappings = optional(map(object({
      device_name = string
      ebs = object({
          iops = number
          throughput = number
          volume_size = number
      })
    })), {})
    tags = map(string)
    labels = map(string)
    taints = list(object({
        key = string
        value = optional(string, "")
        effect = optional(string, "NO_SCHEDULE")
    }))
  }))
}
