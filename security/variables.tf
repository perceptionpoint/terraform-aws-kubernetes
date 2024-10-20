variable "vpc_id" {}
variable "eks_cluster_security_group_id" { type = string }
variable "eks_cluster_api_allowed_cidr_blocks" { type = map(string) }
variable "eks_node_allowed_cidr_blocks" { type = map(string) }
variable "eks_properties" {}
variable "node_iam_role_name" {}
variable "node_iam_role_extra_policies" {type = map(string)}
variable "describe_eks_endpoints_assuming_account_id" {}
