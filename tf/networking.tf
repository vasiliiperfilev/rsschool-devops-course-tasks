data "aws_availability_zones" "available" {
  state = "available"
  filter {
    name   = "region-name"
    values = [var.region]
  }
}

resource "aws_vpc" "main-vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "main-vpc"
  }
}

# Public subnets
resource "aws_subnet" "public-subnet" {
  count = length(var.public_subnet_cidrs)
  tags = {
    Name = "public-subnet-${count.index + 1}"
  }
  cidr_block        = var.public_subnet_cidrs[count.index]
  vpc_id            = aws_vpc.main-vpc.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
}

# Private subnets
resource "aws_subnet" "private-subnet" {
  count             = length(var.private_subnet_cidrs)
  cidr_block        = var.private_subnet_cidrs[count.index]
  vpc_id            = aws_vpc.main-vpc.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "private-subnet-${count.index + 1}"
  }
}

# Internet Gateway for the public subnets
# Connects the public subnet to the internet
# And also exposes the public IP address to the internet
resource "aws_internet_gateway" "main-igw" {
  tags = {
    Name = "igw"
  }
  vpc_id = aws_vpc.main-vpc.id
}

# NAT Gateway for the private subnets
# Translates the private IP addresses to public IP addresses
# And forwards the traffic to the Internet Gateway so private subnets can connect to the internet
# That should also be used for the private subnets to access the public subnets
resource "aws_eip" "eip-nat" {
  domain                    = "vpc"
  associate_with_private_ip = "10.0.0.5"
  depends_on                = [aws_internet_gateway.main-igw]
  tags = {
    Name = "eip-nat"
  }
}

resource "aws_nat_gateway" "main-nat-gateway" {
  allocation_id = aws_eip.eip-nat.id
  subnet_id     = aws_subnet.public-subnet[0].id

  tags = {
    Name = "nat-gateway"
  }
}

# Route tables for the subnets
resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.main-vpc.id
  tags = {
    Name = "public-route-table"
  }
}
resource "aws_route_table" "private-route-table" {
  vpc_id = aws_vpc.main-vpc.id
  tags = {
    Name = "private-route-table"
  }
}

# Route the public subnets traffic through the Internet Gateway
resource "aws_route" "public-internet-igw-route" {
  route_table_id         = aws_route_table.public-route-table.id
  gateway_id             = aws_internet_gateway.main-igw.id
  destination_cidr_block = "0.0.0.0/0"
}

# Route the private subnets traffic through the NAT Gateway
resource "aws_route" "nat-ngw-route" {
  route_table_id         = aws_route_table.private-route-table.id
  nat_gateway_id         = aws_nat_gateway.main-nat-gateway.id
  destination_cidr_block = "0.0.0.0/0"
}

# Associate the newly created route tables to the subnets
resource "aws_route_table_association" "public-route-association" {
  count          = length(var.public_subnet_cidrs)
  route_table_id = aws_route_table.public-route-table.id
  subnet_id      = aws_subnet.public-subnet[count.index].id
}

resource "aws_route_table_association" "private-route-association" {
  count          = length(var.private_subnet_cidrs)
  route_table_id = aws_route_table.private-route-table.id
  subnet_id      = aws_subnet.private-subnet[count.index].id
}

# Note: Subnets are already associated with their specific route tables above
# The main VPC route table will handle local VPC traffic automatically