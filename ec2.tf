resource "aws_instance" "bastion" {
  ami                         = lookup(var.amis, var.region)
  instance_type               = var.instance_type
  key_name                    = var.ssh_bastion_pubkey_name
  associate_public_ip_address = true
  security_groups             = [aws_security_group.bastion-host.id]
  subnet_id                   = aws_subnet.public-subnet-1.id
  tags = {
    Name = "Bastion"
  }
}