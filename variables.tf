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
variable "addon_properties" { type = map(string) }
