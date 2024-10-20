resource "aws_iam_role" "describe_eks_endpoints" {
  count = var.describe_eks_endpoints_assuming_account_id == null? 0 : 1

  assume_role_policy = data.aws_iam_policy_document.describe_eks_endpoints_assume_role[0].json
  description = "allow to describe eks endpoints with assume role"
  name = "DescribeEksEndpoints-${var.eks_properties["name"]}"
  inline_policy {
    name = "describe_eks_cluster"
    policy = data.aws_iam_policy_document.describe_eks_endpoints[0].json
  }
}

data "aws_iam_policy_document" "describe_eks_endpoints_assume_role" {
  count = var.describe_eks_endpoints_assuming_account_id == null? 0 : 1

  statement {
    principals {
      type = "AWS"
      identifiers = ["arn:aws:iam::${var.describe_eks_endpoints_assuming_account_id}:root"]
    }
    actions = ["sts:AssumeRole"]
  }
}



data "aws_iam_policy_document" "describe_eks_endpoints" {
  count = var.describe_eks_endpoints_assuming_account_id == null? 0 : 1

  statement {
    actions = ["eks:DescribeCluster"]
    resources = ["*"]
  }
}
