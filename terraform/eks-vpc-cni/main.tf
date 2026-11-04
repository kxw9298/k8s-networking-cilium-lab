data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = var.name
  cidr = "10.30.0.0/16"
  azs  = local.azs

  # Pods take IPs straight from these subnets with the AWS VPC CNI.
  private_subnets = ["10.30.0.0/19", "10.30.32.0/19"]
  public_subnets  = ["10.30.100.0/24", "10.30.101.0/24"]

  # One NAT gateway keeps the lab cheap; not for production.
  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.name
  cluster_version = var.kubernetes_version

  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = var.api_allowed_cidrs

  # Gives the identity running terraform cluster-admin access.
  enable_cluster_creator_admin_permissions = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_addons = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni = {
      most_recent    = true
      before_compute = true
      configuration_values = jsonencode({
        env = {
          ENABLE_PREFIX_DELEGATION = tostring(var.enable_prefix_delegation)
        }
      })
    }
  }

  eks_managed_node_groups = {
    default = {
      instance_types = [var.instance_type]
      capacity_type  = var.spot ? "SPOT" : "ON_DEMAND"
      min_size       = 1
      max_size       = 3
      desired_size   = var.node_count
    }
  }
}
