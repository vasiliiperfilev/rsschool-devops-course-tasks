# Ubuntu 22.04 latest AMI ID
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu*22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = var.ssh_bastion_pubkey_name
  associate_public_ip_address = true
  security_groups             = [aws_security_group.bastion-host.id]
  subnet_id                   = aws_subnet.public-subnet[0].id
  tags = {
    Name        = "Bastion"
    Environment = "dev"
    Task        = "task-2"
  }
}

resource "aws_instance" "public_subnet_2_instance" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = var.ssh_bastion_pubkey_name
  associate_public_ip_address = true
  security_groups             = [aws_security_group.public-subnet.id]
  subnet_id                   = aws_subnet.public-subnet[1].id
  tags = {
    Name        = "Public Subnet 2 Instance"
    Environment = "dev"
    Task        = "task-2"
  }
}

resource "aws_instance" "private_subnet_1_instance" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = var.ssh_bastion_pubkey_name
  associate_public_ip_address = true
  security_groups             = [aws_security_group.private-subnet.id]
  subnet_id                   = aws_subnet.private-subnet[0].id
  tags = {
    Name        = "Private Subnet 1 Instance"
    Environment = "dev"
    Task        = "task-2"
  }
}

resource "aws_instance" "private_subnet_2_instance" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = var.ssh_bastion_pubkey_name
  associate_public_ip_address = true
  security_groups             = [aws_security_group.private-subnet.id]
  subnet_id                   = aws_subnet.private-subnet[1].id
  tags = {
    Name        = "Private Subnet 2 Instance"
    Environment = "dev"
    Task        = "task-2"
  }
}