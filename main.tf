#### VPC & EKS Block
locals {
  cluster_name = "${var.env}-eks-${random_string.suffix.result}"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  name = var.vpc_name

  cidr = var.cidr
  azs  = var.aws_availability_zones

  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = 1
  }
}


module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.16.0"
  cluster_name = "eks-with-secrets"
  cluster_endpoint_public_access = true
  enable_irsa = true
  cluster_version = "1.27"
  subnet_ids      = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id

  eks_managed_node_groups = {
    on_demand_1 = {
      min_size     = 1
      max_size     = 3
      desired_size = 1

      instance_types = ["t3.small"]
      capacity_type = "ON_DEMAND"
    }
  }
}


data "aws_eks_cluster_auth" "default" {
  name = "eks-with-secrets"
}


