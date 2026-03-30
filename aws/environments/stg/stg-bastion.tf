# -----------------------------------------------------------------------------
# Bastion Host (optional — only created if bastion_key_name is set)
# -----------------------------------------------------------------------------

resource "aws_instance" "bastion" {
  count = var.bastion_key_name != "" ? 1 : 0

  ami                    = data.aws_ami.amazon_linux[0].id
  instance_type          = "t3.micro"
  key_name               = var.bastion_key_name
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.bastion.id]

  associate_public_ip_address = true

  metadata_options {
    http_tokens                 = "required"
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 8
    encrypted   = true
  }

  tags = merge(local.tags, {
    Name = "${local.name}-bastion"
  })
}

data "aws_ami" "amazon_linux" {
  count       = var.bastion_key_name != "" ? 1 : 0
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
