resource "aws_ssm_parameter" "vpc_id" {
  name  = "/cicd/vpc/id"
  type  = "String"
  value = module.vpc.vpc_id
}

resource "aws_ssm_parameter" "private_subnets" {
  name  = "/cicd/vpc/private_subnets"
  type  = "StringList"
  value = join(",", module.vpc.private_subnets)
}

resource "aws_ssm_parameter" "node_role_arn" {
  name  = "/cicd/eks/node_role_arn"
  type  = "String"
  value = aws_iam_role.eks_node_role.arn
}
