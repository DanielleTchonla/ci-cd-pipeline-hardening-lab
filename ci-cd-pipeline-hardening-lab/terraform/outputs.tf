output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnets" {
  value = module.vpc.public_subnets
}

output "private_subnets" {
  value = module.vpc.private_subnets
}


output "ecr_repo_url" {
  value = aws_ecr_repository.flask_cicd.repository_url
}

output "eks_node_role_arn" {
  value = aws_iam_role.eks_node_role.arn
}

output "github_actions_role_arn" {
  description = "The ARN of the IAM Role for GitHub Actions"
  value       = aws_iam_role.github_actions.arn
}