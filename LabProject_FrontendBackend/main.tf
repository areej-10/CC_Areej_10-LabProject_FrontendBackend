provider "aws" {
  region = "us-east-1"
}

# 1. SSH Key Pair - Explicitly create this first
resource "aws_key_pair" "deployer" {
  key_name   = var.ssh_key_name
  public_key = file(var.public_key_location)
}

# 2. Network Setup
resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = { Name = "${var.env_prefix}-vpc" }
}

resource "aws_subnet" "myapp-subnet-1" {
  vpc_id                  = aws_vpc.myapp-vpc.id
  cidr_block              = var.subnet_cidr_block
  availability_zone       = var.avail_zone
  map_public_ip_on_launch = true
  tags = { Name = "${var.env_prefix}-subnet-1" }
}

resource "aws_internet_gateway" "myapp-igw" {
  vpc_id = aws_vpc.myapp-vpc.id
  tags = { Name = "${var.env_prefix}-igw" }
}

resource "aws_route_table" "main-rtb" {
  vpc_id = aws_vpc.myapp-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-igw.id
  }
}

resource "aws_main_route_table_association" "a-rtb-vpc" {
  vpc_id         = aws_vpc.myapp-vpc.id
  route_table_id = aws_route_table.main-rtb.id
}

# 3. Security Group
resource "aws_security_group" "myapp-sg" {
  vpc_id = aws_vpc.myapp-vpc.id
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 4. EC2 Instances
resource "aws_instance" "frontend" {
  ami                    = "ami-0453ec754f44f9a4a"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.myapp-subnet-1.id
  vpc_security_group_ids = [aws_security_group.myapp-sg.id]
  key_name               = aws_key_pair.deployer.key_name
  tags                   = { Name = "${var.env_prefix}-frontend" }

  # Wait for SSH to be ready
  provisioner "remote-exec" {
    inline = ["echo 'SSH ready'"]
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.private_key_location)
      host        = self.public_ip
    }
  }
}

resource "aws_instance" "backend" {
  count                  = 3
  ami                    = "ami-0453ec754f44f9a4a"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.myapp-subnet-1.id
  vpc_security_group_ids = [aws_security_group.myapp-sg.id]
  key_name               = aws_key_pair.deployer.key_name
  tags                   = { Name = "${var.env_prefix}-backend-${count.index}" }

  # Wait for SSH to be ready
  provisioner "remote-exec" {
    inline = ["echo 'SSH ready'"]
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.private_key_location)
      host        = self.public_ip
    }
  }
}

# 5. Generate Inventory File
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tftpl", { 
    frontend_ip      = aws_instance.frontend.public_ip,
    backend_ips      = aws_instance.backend[*].public_ip,
    private_key_path = var.private_key_location 
  })
  filename = "${path.module}/ansible/inventory/hosts"

  depends_on = [
    aws_instance.frontend,
    aws_instance.backend
  ]
}

# 6. Run Ansible Automation
resource "null_resource" "run_ansible" {
  triggers = {
    frontend_ip = aws_instance.frontend.public_ip
    backend_ips = join(",", aws_instance.backend[*].public_ip)
  }

  depends_on = [
    local_file.ansible_inventory,
    aws_instance.frontend,
    aws_instance.backend
  ]
  
  provisioner "local-exec" {
    command = <<-EOT
      sleep 60
      cd ${path.module}/ansible
      ANSIBLE_HOST_KEY_CHECKING=False ANSIBLE_ROLES_PATH=./roles ansible-playbook \
        -i inventory/hosts \
        playbooks/site.yaml
    EOT
  }
}