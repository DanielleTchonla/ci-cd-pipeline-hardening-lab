provider "aws" {
  region = "us-east-1"
}
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.67" 
    }
  }

  required_version = ">= 1.3.0"
}

# terraform/main.tf

data "aws_eks_cluster" "existing" {
  name = "cicd-cluster"
}

data "aws_eks_cluster_auth" "existing" {
  name = data.aws_eks_cluster.existing.name
}


module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "4.0.2"

  name = "cicd-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  private_subnet_tags = {
    "kubernetes.io/cluster/cicd-cluster" = "shared"
    "kubernetes.io/role/internal-elb"    = "1"
  }

  tags = {
    Name = "cicd-vpc"
  }
}

module "managed_nodes" {
  source         = "./modules/eks_node_group"
  cluster_name   = "cicd-cluster"
  node_group_name = "eks-managed-nodes"
  instance_types = ["t3.medium"]
  node_role_arn  = "arn:aws:iam::746669235620:role/eks-node-role"
  subnet_ids     = ["subnet-04c78a79fb2cae3a8","subnet-05f21de0eaa13ebc2"]
  desired_size   = 2
  max_size       = 3
  min_size       = 1
  tags           = { Name = "eks-managed-nodes" }
  depends_on     = []
}

