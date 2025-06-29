variable "vpc_cidr_block" {
  description = "Kubernetes vpc cidr" 
  type = string
}

variable "vpc_name" {
  description = "VPC name" 
  type = string
}

variable "igw_name" {
  description = "Inernet gateway name" 
  type = string
}

variable "az1" {
  description = "Availability zone 1"
  type = string
}

variable "public_sub1_cidr_block" {
  description = "Public subnet1 cidr block"
  type = string
}

variable "public_sub1_name" {
  description = "Public subnet1 name"
  type = string
}

variable "private_sub1_cidr_block" {
  description = "Private subnet1 cidr block"
  type = string
}

variable "private_sub1_name" {
  description = "Private subnet1 name"
  type = string
}

variable "nat_name" {
  description = "NAT gateway name"
  type = string
}

variable "eks_cluster_role" {
  description = "EKS cluster role name"
  type = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type = string
}

variable "eks_version" {
  description = "EKS version"
  type = string
}

variable "authentication_mode" {
  description = "Authentication mode"
  type = string
}
