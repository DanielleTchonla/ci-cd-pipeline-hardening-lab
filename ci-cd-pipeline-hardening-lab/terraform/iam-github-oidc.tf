
# # GitHub OIDC Provider (if not already created)
# resource "aws_iam_openid_connect_provider" "github" {
#   url             = "https://token.actions.githubusercontent.com"
#   client_id_list  = ["sts.amazonaws.com"]
#   thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
# }

# # IAM Role for GitHub Actions
# resource "aws_iam_role" "github_actions" {
#   name = "GitHubActionsRole"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Principal = {
#           Federated = "arn:aws:iam::746669235620:oidc-provider/token.actions.githubusercontent.com"
#         }
#         Action = "sts:AssumeRoleWithWebIdentity"
#         Condition = {
#           StringEquals = {
#             "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
#           }
#           StringLike = {
#             "token.actions.githubusercontent.com:sub" = "repo:DanielleTchonla/ci-cd-pipeline-hardening-lab:ref:refs/heads/main"
#           }
#         }
#       }
#     ]
#   })
# }

# # Policy for EKS + ECR
# resource "aws_iam_role_policy" "github_actions_policy" {
#   role = aws_iam_role.github_actions.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       # ECR permissions to pull/push images
#       {
#         Effect   = "Allow"
#         Action   = [
#           "ecr:GetAuthorizationToken",
#           "ecr:BatchCheckLayerAvailability",
#           "ecr:CompleteLayerUpload",
#           "ecr:InitiateLayerUpload",
#           "ecr:PutImage",
#           "ecr:UploadLayerPart"
#         ]
#         Resource = "*"
#       },

#       # EKS permissions to update deployments
#       {
#         Effect   = "Allow"
#         Action   = [
#           "eks:DescribeCluster",
#           "eks:ListClusters",
#           "eks:ListNodegroups",
#           "eks:DescribeNodegroup",
#           "eks:AccessKubernetesApi"
#         ]
#         Resource = "*"
#       },

#       # Optional: CloudWatch logging (to see pod logs via kubectl or CloudWatch)
#       {
#         Effect   = "Allow"
#         Action   = [
#           "logs:DescribeLogStreams",
          
#           "logs:GetLogEvents",
#           "logs:DescribeLogGroups"
#         ]
#         Resource = "*"
#       }
#     ]
#   })
# }



#1️ GitHub OIDC Provider
# This allows GitHub Actions to assume roles in AWS via OIDC

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}


#2 IAM Role for GitHub Actions
# This role will be assumed by GitHub Actions workflow via OIDC

resource "aws_iam_role" "github_actions" {
  name = "GitHubActionsRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            # Only allow this specific repo & branch to assume the role
            "token.actions.githubusercontent.com:sub" = "repo:DanielleTchonla/ci-cd-pipeline-hardening-lab:ref:refs/heads/main"
          }
        }
      }
    ]
  })
}

#3 IAM Role Policy
# Grants permissions required by your pipeline
# - ECR: build/push Docker images
# - EKS: update deployments
# - CloudWatch: optional logging

resource "aws_iam_role_policy" "github_actions_policy" {
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # ECR permissions
      {
        Effect   = "Allow"
        Action   = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ]
        Resource = "*"
      },

      # EKS permissions
      {
        Effect   = "Allow"
        Action   = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:ListNodegroups",
          "eks:DescribeNodegroup",
          "eks:AccessKubernetesApi"
        ]
        Resource = "*"
      },

      # CloudWatch logging (to see pod logs via kubectl or CloudWatch)
      {
        Effect   = "Allow"
        Action   = [
          "logs:DescribeLogStreams",
          "logs:GetLogEvents",
          "logs:DescribeLogGroups"
        ]
        Resource = "*"
      }
    ]
  })
}
