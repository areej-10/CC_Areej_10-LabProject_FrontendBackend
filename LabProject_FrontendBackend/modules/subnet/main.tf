resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "${var.env_prefix}-vpc"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
}

resource "aws_subnet" "this" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.subnet_cidr
  availability_zone       = var.az
  map_public_ip_on_launch = true
}

resource "aws_route_table" "this" {
  vpc_id = aws_vpc.this.id
}

resource "aws_route" "default" {
  route_table_id         = aws_route_table.this.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "assoc" {
  subnet_id      = aws_subnet.this.id
  route_table_id = aws_route_table.this.id
}
resource "local_file" "inventory" {
  content = templatefile("ansible/inventory/hosts.tpl", {
    frontend_ip = module.frontend.public_ip
    backend_ips = [for b in module.backend : b.public_ip]
    private_key = var.private_key_path
  })
  filename = "ansible/inventory/hosts"
}

resource "null_resource" "ansible" {
  depends_on = [module.frontend, module.backend]

  provisioner "local-exec" {
    command = <<EOT
      cd ansible
      ansible-playbook -i inventory/hosts playbooks/site.yaml
    EOT
  }
}
