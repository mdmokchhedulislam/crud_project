resource "aws_vpc" "project_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Public Subnets
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.project_vpc.id
  cidr_block              = var.public_subnet_cidr_1
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "${var.project_name}-public-1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.project_vpc.id
  cidr_block              = var.public_subnet_cidr_2
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"

  tags = {
    Name = "${var.project_name}-public-2"
  }
}

# Private Subnets
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.project_vpc.id
  cidr_block        = var.private_subnet_cidr_1
  availability_zone = "us-east-1a"

  tags = {
    Name = "${var.project_name}-private-1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.project_vpc.id
  cidr_block        = var.private_subnet_cidr_2
  availability_zone = "us-east-1b"

  tags = {
    Name = "${var.project_name}-private-2"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "project_gateway" {
  vpc_id = aws_vpc.project_vpc.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# NAT Gateway
resource "aws_eip" "project_nat_eip" {
  depends_on = [aws_internet_gateway.project_gateway]
}

resource "aws_nat_gateway" "project_nat_gateway" {
  allocation_id = aws_eip.project_nat_eip.id
  subnet_id     = aws_subnet.public_subnet_1.id # Put NAT in public subnet 1

  tags = {
    Name = "${var.project_name}-nat"
  }
}

# Route Tables
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.project_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.project_gateway.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.project_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.project_nat_gateway.id
  }

  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

# Route Table Associations
resource "aws_route_table_association" "public_assoc_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_assoc_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "private_assoc_1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_assoc_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_route_table.id
}
