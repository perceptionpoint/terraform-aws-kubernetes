variable "vpc_id" {}
variable "eks_cluster_api_allowed_cidr_blocks" { type = map(string) }
variable "eks_node_allowed_cidr_blocks" { type = map(string) }
variable "eks_properties" {}
