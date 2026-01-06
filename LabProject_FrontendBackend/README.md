cat > README.md << 'EOF'
# Lab Project: Nginx Frontend with Backend HTTPD Servers (HA + Auto-Config)

## Project Overview
This project demonstrates a multi-tier AWS architecture using Terraform and Ansible with:
- 1 Nginx frontend (load balancer)
- 3 Apache HTTPD backend servers (2 active + 1 backup)
- Fully automated deployment

## Architecture
```
Internet → Nginx Frontend → Backend Servers (2 active + 1 backup)
```

## Prerequisites
- AWS Account with credentials configured
- Terraform >= 1.5
- Ansible >= 2.9
- SSH key pair

## Quick Start

### 1. Clone Repository
```bash
git clone <your-repo-url>
cd LabProject_FrontendBackend
```

### 2. Configure Variables
```bash
# Edit terraform.tfvars with your SSH public key
# Already configured with default values
```

### 3. Deploy Everything
```bash
terraform init
terraform apply -auto-approve
```

This single command will:
- Create all AWS infrastructure
- Configure all servers automatically
- Set up load balancing

### 4. Access Application
```bash
# Get frontend URL
terraform output access_url

# Visit in browser or curl
curl http://<frontend-ip>
```

## Testing Load Balancing

### Test Normal Operation
```bash
# Multiple requests should alternate between backend-0 and backend-1
for i in {1..10}; do curl http://<frontend-ip>; done
```

### Test Backup Failover
```bash
# Stop primary backends
ssh ec2-user@<backend-0-ip> 'sudo systemctl stop httpd'
ssh ec2-user@<backend-1-ip> 'sudo systemctl stop httpd'

# Should now serve from backup (backend-2)
curl http://<frontend-ip>
```

## Project Structure
```
LabProject_FrontendBackend/
├── main.tf                 # Main infrastructure
├── variables.tf            # Variable definitions
├── outputs.tf              # Output definitions
├── locals.tf               # Local values and data sources
├── terraform.tfvars        # Variable values
├── inventory.tpl           # Ansible inventory template
├── ansible/
│   ├── ansible.cfg
│   ├── inventory/
│   │   └── hosts           # Generated inventory
│   ├── playbooks/
│   │   └── site.yaml       # Main playbook
│   └── roles/
│       ├── backend/        # HTTPD configuration
│       └── frontend/       # Nginx configuration
└── screenshots/            # Evidence screenshots
```

## Assumptions
- **Region**: us-east-1
- **Instance Type**: t2.micro (free tier)
- **AMI**: Latest Amazon Linux 2
- **VPC CIDR**: 10.0.0.0/16
- **Subnet**: 10.0.1.0/24

## Cleanup
```bash
terraform destroy -auto-approve
```

## Author
NAME/REG-NO: AREEJ FATIMA /2023-BSE-010
EOF
