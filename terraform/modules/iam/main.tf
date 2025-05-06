data "aws_caller_identity" "current" {}

# ------------------------------------------------------------
# SQS Access IAM Role for Service Account (IRSA)
# ------------------------------------------------------------

data "aws_iam_policy_document" "sqs_access" {
  statement {
    effect = "Allow"

    actions = [
      "sqs:SendMessage",
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl"
    ]

    resources = [for url in var.queue_arns : url]
  }
}

locals {
  clean_oidc_provider = replace(var.oidc_provider, "https://", "")
}

resource "aws_iam_policy" "sqs_policy" {
  name        = "${var.cluster_name}-sqs-access"
  description = "Policy allowing access to SQS queues"
  policy      = data.aws_iam_policy_document.sqs_access.json
}

resource "aws_iam_role" "service_account_role" {
  name = "${var.cluster_name}-sqs-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.clean_oidc_provider}"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.clean_oidc_provider}:sub" = "system:serviceaccount:${var.namespace}:${var.service_account_name}"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_sqs_policy" {
  role       = aws_iam_role.service_account_role.name
  policy_arn = aws_iam_policy.sqs_policy.arn
}


resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.service_account_role.name
  policy_arn = aws_iam_policy.sqs_policy.arn
}

# ------------------------------------------------------------
# ALB Controller IAM Role
# ------------------------------------------------------------

resource "aws_iam_policy" "alb_controller_policy" {
  name   = "${var.cluster_name}-alb-controller-policy"
  policy = file("${path.module}/policies/aws-load-balancer-controller.json")
}

resource "aws_iam_role" "alb_controller" {
  name = "${var.cluster_name}-alb-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.clean_oidc_provider}"  # ✅ FIXED
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.clean_oidc_provider}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"  # ✅ FIXED
        }
      }
    }]
  })
}


resource "aws_iam_role_policy_attachment" "alb_controller" {
  role       = aws_iam_role.alb_controller.name
  policy_arn = aws_iam_policy.alb_controller_policy.arn
}

# ------------------------------------------------------------
# GitHub Actions IAM User (for CI/CD to push to ECR)
# ------------------------------------------------------------

resource "aws_iam_user" "github_actions" {
  name = "github-actions-ci"
}

resource "aws_iam_access_key" "github_actions" {
  user = aws_iam_user.github_actions.name
}

resource "aws_iam_user_policy" "github_actions_ecr" {
  name = "GitHubActionsECRPolicy"
  user = aws_iam_user.github_actions.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:GetDownloadUrlForLayer",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = ["sts:GetCallerIdentity"]
        Resource = "*"
      }
    ]
  })
}