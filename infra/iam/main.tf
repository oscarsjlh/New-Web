terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}
provider "aws" {
  region = var.region
}


resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["a031c46782e6e6c662c2c87c76da9aa62ccabd8e"]
}


data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.id]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.organization}/${var.name}:*"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "github-actions-${var.organization}-${var.name}"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json
}



data "aws_iam_policy_document" "pushtos3" {
  statement {
    actions = [
      "s3:PutObject",
      "s3:ListBucket",
      "s3:DeleteObject",
      "cloudfront:CreateInvalidation",
    ]
    resources = [
      var.cloudfront_arn,
      "arn:aws:s3:::${var.bucket_name}/*",
      "arn:aws:s3:::${var.bucket_name}",
    ]
    sid = "VisualEditor0"
  }
}

resource "aws_iam_policy" "pushtos3" {
  name   = "pushtos3"
  policy = data.aws_iam_policy_document.pushtos3.json
}

resource "aws_iam_role_policy_attachment" "pushtos3" {
  role       = aws_iam_policy.pushtos3.name
  policy_arn = aws_iam_policy.pushtos3.arn

}
