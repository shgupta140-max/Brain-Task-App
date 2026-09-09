resource "aws_vpc" "mindtrack" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "mindtrack-vpc"
  }
}

resource "aws_subnet" "public_01" {
  vpc_id                  = aws_vpc.mindtrack.id
  cidr_block              = var.public_subnet_01_cidr
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name                                            = "mindtrack-pub-sub01"
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "owned" # or "shared"
    "kubernetes.io/role/elb"                        = "1"
  }
}

resource "aws_subnet" "public_02" {
  vpc_id                  = aws_vpc.mindtrack.id
  cidr_block              = var.public_subnet_02_cidr
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true

  tags = {
    Name                                            = "mindtrack-pub-sub02"
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "owned" # or "shared"
    "kubernetes.io/role/elb"                        = "1"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.mindtrack.id

  tags = {
    Name = "mindtrack-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.mindtrack.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "mindtrack-public-rt"
  }
}

resource "aws_route_table_association" "public_01" {
  subnet_id      = aws_subnet.public_01.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_02" {
  subnet_id      = aws_subnet.public_02.id
  route_table_id = aws_route_table.public.id
}
