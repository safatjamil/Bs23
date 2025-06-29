# Create a VPC
resource "aws_vpc" "eks" {
  cidr_block = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = var.vpc_name
  }
}

# Create an internet gateway
resource "aws_internet_gateway" "eks_igw" {
  vpc_id = aws_vpc.eks.id
  tags = {
    Name = var.igw_name
  }
}

/* Create two subnets in an AZ
It is for the test purpose, in a production environment you must use two AZs
*/
resource "aws_subnet" "public_sub1" {
  vpc_id                  = aws_vpc.eks.id
  cidr_block              = var.public_sub1_cidr_block
  availability_zone       = var.az1
  map_public_ip_on_launch = true
  tags = {
    "Name" = var.public_sub1_name
  }
}

resource "aws_subnet" "private_sub1" {
  vpc_id            = aws_vpc.eks.id
  cidr_block        = var.private_sub1_cidr_block
  availability_zone = var.az1
  tags = {
    "Name" = var.private_sub1_name
  }
}

# Create a nat and an elastic ip for the nat
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags = {
    Name = "eks-nat"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_sub1.id

  tags = {
    Name = var.nat_name
  }
  depends_on = [aws_internet_gateway.eks_igw]
}

# Add routes to the subnets
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.eks.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = {
    Name = "route-sub1-private"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.eks.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks_igw.id
  }
  tags = {
    Name = "route_sub1-public"
  }
}

resource "aws_route_table_association" "private_zone1" {
  subnet_id      = aws_subnet.private_sub1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "public_zone1" {
  subnet_id      = aws_subnet.public_sub1.id
  route_table_id = aws_route_table.public.id
}

# Create the cluster
resource "aws_iam_role" "eks_cluster_role" {
  name = var.eks_cluster_role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_eks_cluster" "eks_cluster" {
  name = var.cluster_name
  access_config {
    authentication_mode = var.authentication_mode
  }

  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = var.eks_version

  vpc_config {
    endpoint_private_access = true
    endpoint_public_access  = true
    subnet_ids = [
      aws_subnet.public_sub1.id,
      aws_subnet.private_sub1.id
    ]
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
  ]
}
