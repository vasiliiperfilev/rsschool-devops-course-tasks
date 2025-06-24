# Network ACL for Public Subnets
resource "aws_network_acl" "public_acl" {
  vpc_id = aws_vpc.main-vpc.id

  tags = {
    Name        = "public-acl"
    Environment = "dev"
    Task        = "task-2"
  }
}

# Network ACL for Private Subnets
resource "aws_network_acl" "private_acl" {
  vpc_id = aws_vpc.main-vpc.id

  tags = {
    Name        = "private-acl"
    Environment = "dev"
    Task        = "task-2"
  }
}

# Public ACL Rules
# Allow all outbound traffic to internet
resource "aws_network_acl_rule" "public_outbound_all" {
  network_acl_id = aws_network_acl.public_acl.id
  rule_number    = 1001
  protocol       = "-1"
  egress         = true
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}

# Allow all inbound traffic from internet
resource "aws_network_acl_rule" "public_inbound_all" {
  network_acl_id = aws_network_acl.public_acl.id
  rule_number    = 1002
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}

# Allow inbound traffic from all VPC subnets (inter-subnet communication)
resource "aws_network_acl_rule" "public_inbound_vpc" {
  network_acl_id = aws_network_acl.public_acl.id
  rule_number    = 1003
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
  from_port      = 0
  to_port        = 0
}


# Private ACL Rules
# Allow all outbound traffic (to internet via NAT and to other subnets)
resource "aws_network_acl_rule" "private_outbound_all" {
  network_acl_id = aws_network_acl.private_acl.id
  rule_number    = 1001
  protocol       = "-1"
  egress         = true
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}

# Allow inbound traffic from all VPC subnets (inter-subnet communication)
resource "aws_network_acl_rule" "private_inbound_vpc" {
  network_acl_id = aws_network_acl.private_acl.id
  rule_number    = 1002
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
  from_port      = 0
  to_port        = 0
}

# Allow inbound ephemeral ports for return traffic from internet
resource "aws_network_acl_rule" "private_inbound_ephemeral" {
  network_acl_id = aws_network_acl.private_acl.id
  rule_number    = 1003
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# Allow inbound SSH (port 22) from the bastion CIDR
resource "aws_network_acl_rule" "private_inbound_ssh" {
  network_acl_id = aws_network_acl.private_acl.id
  rule_number    = 1004
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = local.bastion_cidr
  from_port      = 22
  to_port        = 22
}

# Associate ACLs with subnets
resource "aws_network_acl_association" "public_subnet_acl" {
  count          = length(var.public_subnet_cidrs)
  network_acl_id = aws_network_acl.public_acl.id
  subnet_id      = aws_subnet.public-subnet[count.index].id
}

resource "aws_network_acl_association" "private_subnet_acl" {
  count          = length(var.private_subnet_cidrs)
  network_acl_id = aws_network_acl.private_acl.id
  subnet_id      = aws_subnet.private-subnet[count.index].id
}
