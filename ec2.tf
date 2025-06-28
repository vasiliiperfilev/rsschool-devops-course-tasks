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

# IAM role for EC2 instances
resource "aws_iam_role" "describe_ec2_role" {
  name = "DescribeEC2Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy for EC2 describe permissions
resource "aws_iam_role_policy" "describe_ec2_policy" {
  name = "DescribeEC2Policy"
  role = aws_iam_role.describe_ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeTags"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM instance profile
resource "aws_iam_instance_profile" "describe_ec2_profile" {
  name = "DescribeEC2Profile"
  role = aws_iam_role.describe_ec2_role.name
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = var.ssh_bastion_pubkey_name
  associate_public_ip_address = true
  security_groups             = [aws_security_group.bastion-host.id]
  subnet_id                   = aws_subnet.public-subnet[0].id
  iam_instance_profile        = aws_iam_instance_profile.describe_ec2_profile.name
  # Require IMDSv2 for metadata service for security
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  tags = {
    Name = "Bastion"
  }
}

resource "aws_instance" "private_subnet_1_instance" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = var.ssh_bastion_pubkey_name
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.private-subnet.id]
  subnet_id                   = aws_subnet.private-subnet[0].id
  iam_instance_profile        = aws_iam_instance_profile.describe_ec2_profile.name
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  tags = {
    Name = "K3S-server"
  }
}

resource "aws_instance" "private_subnet_2_instance" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = var.ssh_bastion_pubkey_name
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.private-subnet.id]
  subnet_id                   = aws_subnet.private-subnet[1].id
  iam_instance_profile        = aws_iam_instance_profile.describe_ec2_profile.name
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  tags = {
    Name = "K3S-worker"
  }
}