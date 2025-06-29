provider "aws" {
  region = "us-east-1"
}

locals {
  config = yamldecode(file("config.yaml"))
}

module "kubernetes" {
  source = "../modules"
  vpc_name = local.config.vpc.name
  vpc_cidr_block = local.config.vpc.cidr_block
  igw_name = local.config.vpc.igw_name
  az1 = local.config.vpc.az1.name
  public_sub1_name = local.config.vpc.az1.public_subnet.sub1.name
  public_sub1_cidr_block = local.config.vpc.az1.public_subnet.sub1.cidr
  private_sub1_name = local.config.vpc.az1.private_subnet.sub1.name
  private_sub1_cidr_block = local.config.vpc.az1.private_subnet.sub1.cidr
  nat_name = local.config.vpc.nat_name

  eks_cluster_role = local.config.cluster.role
  cluster_name = local.config.cluster.name
  eks_version = local.config.cluster.version
  authentication_mode = local.config.cluster.authentication_mode
}
