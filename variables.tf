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
variable "node_iam_role_extra_policies" {
  type = map(string)
  default = {}
}
variable "addon_properties" {
  default = {}
  type = map(object({
    addon_version = string
    configuration_values = optional(string)
    service_account_role_arn = optional(string)
    resolve_conflicts_on_create = optional(string, "NONE")
    resolve_conflicts_on_update = optional(string, "NONE")
  }))
}
variable "node_group_properties" {
  default = {}
  type = map(object({
    name = string
    subnet_ids = list(string)
    capacity_type = string
    ami_type = optional(string)
    instance_requirements = object({
      allowed_instance_types = list(string)
      allowed_instance_size = list(string)
    })
    user_data = string
    imdsv2_enabled = optional(bool, true)
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
variable "enable_karpenter_creation" { 
  type = bool
  default = true
}
variable "karpenter_role_name_extension" { 
  type = string
  default = "" 
}
