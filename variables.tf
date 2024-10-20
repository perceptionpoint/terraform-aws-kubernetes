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
variable "core_addon_properties" {
  default = {}
  type = map(object({
    addon_version = optional(string)
    configuration_values = optional(map(any), {})
  }))
}
variable "core_node_group_properties" {
  type = map(object({
    subnet_ids = list(string)
    tags = optional(map(string), {})
    user_data_suffix = optional(string, "")
  }))
}
variable "extra_node_group_properties" {
  # type spec is in the inner module eks_node_group.node_group_properties
  default = {}
}
variable "enable_karpenter_creation" {
  type = bool
  default = true
}
variable "karpenter_role_name_extension" {
  type = string
  default = ""
}
variable "kubeconfig_metadata_output_file" {
  type = string
  default = null
}

variable "kubeconfig_cluster_aliases" {
  type = list(string)
  default = []
}

variable "describe_eks_endpoints_assuming_account_id" {
  type = string
  default = null
}
