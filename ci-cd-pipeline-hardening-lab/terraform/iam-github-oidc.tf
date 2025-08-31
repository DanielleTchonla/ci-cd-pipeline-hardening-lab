
# #1️ GitHub OIDC Provider
# # This allows GitHub Actions to assume roles in AWS via OIDC
# 1️ GitHub OIDC Provider
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# 2️ IAM Role for GitHub Actions
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
            "token.actions.githubusercontent.com:sub" = "repo:DanielleTchonla/ci-cd-pipeline-hardening-lab:ref:refs/heads/main"
          }
        }
      }
    ]
  })
}
# Attach IAM Policy to the Role

resource "aws_iam_role_policy_attachment" "github_actions_attach" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy" 
}
# resource "aws_iam_role_policy_attachment" "eks_access" {
#   role       = aws_iam_role.github_actions_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
# }

# resource "aws_iam_role_policy_attachment" "eks_service" {
#   role       = aws_iam_role.github_actions_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
# }

# # Attach EKS & ECR policies to GitHub Actions role
# resource "aws_iam_role_policy_attachment" "github_actions_ecr" {
#   role       = aws_iam_role.github_actions_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
# }

# resource "aws_iam_role_policy_attachment" "github_actions_eks" {
#   role       = aws_iam_role.github_actions_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
# }



# 3️ IAM Role Policy for ECR + EKS + CloudWatch
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
      # CloudWatch logging
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



