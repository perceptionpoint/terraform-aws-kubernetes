data "aws_caller_identity" "current" {}

locals {
  github_oidc_provider_name = "token.actions.githubusercontent.com"
}

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
  statement {
    principals {
      type = "Federated"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.id}:oidc-provider/${local.github_oidc_provider_name}"]
    }
    condition {
      test = "StringLike"
      variable = "${local.github_oidc_provider_name}:aud"
      values = ["pp-*"]
    }
    condition {
      test = "StringLike"
      variable = "${local.github_oidc_provider_name}:sub"
      values = ["repo:perceptionpoint/*"]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
  }
}



data "aws_iam_policy_document" "describe_eks_endpoints" {
  count = var.describe_eks_endpoints_assuming_account_id == null? 0 : 1

  statement {
    actions = ["eks:DescribeCluster"]
    resources = ["*"]
  }
}
