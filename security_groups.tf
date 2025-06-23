# Security Group for bastion host
resource "aws_security_group" "bastion-host" {
  name        = "bastion-host-security-group"
  description = "Allows inbound access on port 22 and outbound access to the internet"
  vpc_id      = aws_vpc.rsschool-vpc.id
  tags = {
    Name = "bastion-host-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "bastion_allow_ssh" {
  security_group_id = aws_security_group.bastion-host.id
  cidr_ipv4         = var.allowed_ssh_cidr
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "bastion_allow_all" {
  security_group_id = aws_security_group.bastion-host.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}


# Security Group for public subnets
resource "aws_security_group" "public-subnet" {
  name        = "public-subnet-sg"
  description = "Allow traffic on port 443 and traffic from bastion host on port 22"
  vpc_id      = aws_vpc.rsschool-vpc.id

  tags = {
    Name = "public-subnet-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "public_allow_https" {
  security_group_id = aws_security_group.public-subnet.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "public_allow_ssh_from_bastion" {
  security_group_id            = aws_security_group.public-subnet.id
  from_port                    = 22
  ip_protocol                  = "tcp"
  to_port                      = 22
  referenced_security_group_id = aws_security_group.bastion-host.id
}

resource "aws_vpc_security_group_egress_rule" "public_allow_all" {
  security_group_id = aws_security_group.public-subnet.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# Security Group for private subnets
resource "aws_security_group" "private-subnet" {
  name        = "private-subnet-sg"
  description = "Allow traffic from bastion host on port 22 and outbound traffic"
  vpc_id      = aws_vpc.rsschool-vpc.id

  tags = {
    Name = "private-subnet-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "private_allow_ssh_from_bastion" {
  security_group_id            = aws_security_group.private-subnet.id
  from_port                    = 22
  ip_protocol                  = "tcp"
  to_port                      = 22
  referenced_security_group_id = aws_security_group.bastion-host.id
}

resource "aws_vpc_security_group_egress_rule" "private_allow_all" {
  security_group_id = aws_security_group.private-subnet.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}