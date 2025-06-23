data "aws_availability_zones" "available" {
  state = "available"
  filter {
    name   = "region-name"
    values = [var.region]
  }
}

resource "aws_vpc" "rsschool-vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "rsschool-vpc"
  }
}

# Public subnets
resource "aws_subnet" "public-subnet-1" {
  tags = {
    Name = "public-rsschool-subnet-1"
  }
  cidr_block        = var.public_subnet_1_cidr
  vpc_id            = aws_vpc.rsschool-vpc.id
  availability_zone = data.aws_availability_zones.available.names[0]
}

resource "aws_subnet" "public-subnet-2" {
  tags = {
    Name = "public-rsschool-subnet-2"
  }
  cidr_block        = var.public_subnet_2_cidr
  vpc_id            = aws_vpc.rsschool-vpc.id
  availability_zone = data.aws_availability_zones.available.names[1]
}

# Private subnets
resource "aws_subnet" "private-subnet-1" {
  tags = {
    Name = "private-rsschool-subnet-1"
  }
  cidr_block        = var.private_subnet_1_cidr
  vpc_id            = aws_vpc.rsschool-vpc.id
  availability_zone = data.aws_availability_zones.available.names[0]
}

resource "aws_subnet" "private-subnet-2" {
  tags = {
    Name = "private-rsschool-subnet-2"
  }
  cidr_block        = var.private_subnet_2_cidr
  vpc_id            = aws_vpc.rsschool-vpc.id
  availability_zone = data.aws_availability_zones.available.names[1]
}

# Internet Gateway for the public subnets
# Connects the public subnet to the internet
# And also exposes the public IP address to the internet
resource "aws_internet_gateway" "rsschool-igw" {
  tags = {
    Name = "rsschool-igw"
  }
  vpc_id = aws_vpc.rsschool-vpc.id
}

# NAT Gateway for the private subnets
# Translates the private IP addresses to public IP addresses
# And forwards the traffic to the Internet Gateway so private subnets can connect to the internet
# That should also be used for the private subnets to access the public subnets
resource "aws_eip" "nat_gateway" {
  domain                    = "vpc"
  associate_with_private_ip = "10.0.0.5"
  depends_on                = [aws_internet_gateway.rsschool-igw]
}

resource "aws_nat_gateway" "rsschool-ngw" {
  allocation_id = aws_eip.nat_gateway.id
  subnet_id     = aws_subnet.public-subnet-1.id

  tags = {
    Name = "rsschool-ngw"
  }
  depends_on = [aws_eip.nat_gateway]
}

# Route tables for the subnets
resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.rsschool-vpc.id
  tags = {
    Name = "rsschool-public-route-table"
  }
}
resource "aws_route_table" "private-route-table" {
  vpc_id = aws_vpc.rsschool-vpc.id
  tags = {
    Name = "rsschool-private-route-table"
  }
}

# Route the public subnets traffic through the Internet Gateway
resource "aws_route" "public-internet-igw-route" {
  route_table_id         = aws_route_table.public-route-table.id
  gateway_id             = aws_internet_gateway.rsschool-igw.id
  destination_cidr_block = "0.0.0.0/0"
}

# Route the private subnets traffic through the NAT Gateway
resource "aws_route" "nat-ngw-route" {
  route_table_id         = aws_route_table.private-route-table.id
  nat_gateway_id         = aws_nat_gateway.rsschool-ngw.id
  destination_cidr_block = "0.0.0.0/0"
}

# Associate the newly created route tables to the subnets
resource "aws_route_table_association" "public-route-1-association" {
  route_table_id = aws_route_table.public-route-table.id
  subnet_id      = aws_subnet.public-subnet-1.id
}
resource "aws_route_table_association" "public-route-2-association" {
  route_table_id = aws_route_table.public-route-table.id
  subnet_id      = aws_subnet.public-subnet-2.id
}
resource "aws_route_table_association" "private-route-1-association" {
  route_table_id = aws_route_table.private-route-table.id
  subnet_id      = aws_subnet.private-subnet-1.id
}
resource "aws_route_table_association" "private-route-2-association" {
  route_table_id = aws_route_table.private-route-table.id
  subnet_id      = aws_subnet.private-subnet-2.id
}

# Note: Subnets are already associated with their specific route tables above
# The main VPC route table will handle local VPC traffic automatically