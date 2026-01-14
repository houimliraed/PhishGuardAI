# iam for the deployement user

resource "aws_iam_user" "cd" {
  name = "devops-cd"
}
resource "aws_iam_access_key" "cd" {
  user = aws_iam_user.cd.name
}
# the policy document declaration 

data "aws_iam_policy_document" "tf_backend" {

  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.tf_state_bucket}"]
  }
  statement {
    effect  = "Allow"
    actions = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = [
      "arn:aws:s3:::${var.tf_state_bucket}/tf-state-prod/*",
      "arn:aws:s3:::${var.tf_state_bucket}/tf-state-prod-env/*"
    ]
  }

}

# the actual policy creation

resource "aws_iam_policy" "tf_backend" {
  name        = "${aws_iam_user.cd.name}-tf-s3"
  description = "Allow user to use s3 for terraform backend resource"
  policy      = data.aws_iam_policy_document.tf_backend.json
}

# link the policy to the cd user

resource "aws_iam_user_policy_attachment" "tf_backend" {
  user       = aws_iam_user.cd.name
  policy_arn = aws_iam_policy.tf_backend.arn

}
#### policy for ecr repo

data "aws_iam_policy_document" "ecr" {

  statement {
    effect = "Allow"
    actions = [
      "ecr:CompleteLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:InitiateLayerUpload",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:BatchGetImage"
    ]
    resources = [
      aws_ecr_repository.devopsml_backend.arn,
      aws_ecr_repository.devopsml_frontend.arn
    ]
  }
  statement {
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

}

resource "aws_iam_policy" "ecr" {
  name        = "${aws_iam_user.cd.name}-ecr"
  description = "Allow the cd user for the ecr repos"
  policy      = data.aws_iam_policy_document.ecr.json
}

resource "aws_iam_user_policy_attachment" "ecr" {
  user       = aws_iam_user.cd.name
  policy_arn = aws_iam_policy.ecr.arn
}

# EKS permissions

data "aws_iam_policy_document" "eks" {
  statement {
    effect = "Allow"
    actions = [
      "eks:CreateCluster",
      "eks:DeleteCluster",
      "eks:DescribeCluster",
      "eks:ListClusters",
      "eks:UpdateClusterConfig",
      "eks:CreateNodegroup",
      "eks:DeleteNodegroup",
      "eks:DescribeNodegroup",
      "eks:ListNodegroups",
      "eks:UpdateNodegroupConfig",
      "eks:TagResource",
      "eks:UntagResource",
      "eks:ListTagsForResource"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:GetRole",
      "iam:PassRole",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies",
      "iam:CreateServiceLinkedRole"
    ]
    resources = [
      "arn:aws:iam::*:role/phishguard-*",
      "arn:aws:iam::*:role/aws-service-role/eks.amazonaws.com/AWSServiceRoleForAmazonEKS"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateSecurityGroup",
      "ec2:DeleteSecurityGroup",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeVpcs",
      "ec2:DescribeSubnets",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupEgress",
      "ec2:CreateTags",
      "ec2:DeleteTags",
      "ec2:DescribeTags",
      "ec2:DescribeNetworkInterfaces",
      "ec2:CreateNetworkInterface",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeInstances"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:TagLogGroup",
      "logs:UntagLogGroup"
    ]
    resources = ["arn:aws:logs:*:*:log-group:/aws/eks/phishguard-*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "autoscaling:CreateAutoScalingGroup",
      "autoscaling:DeleteAutoScalingGroup",
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:UpdateAutoScalingGroup",
      "autoscaling:CreateLaunchConfiguration",
      "autoscaling:DeleteLaunchConfiguration",
      "autoscaling:DescribeLaunchConfigurations"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "eks" {
  name        = "${aws_iam_user.cd.name}-eks"
  description = "Allow user to manage EKS clusters and resources"
  policy      = data.aws_iam_policy_document.eks.json
}

resource "aws_iam_user_policy_attachment" "eks" {
  user       = aws_iam_user.cd.name
  policy_arn = aws_iam_policy.eks.arn
}