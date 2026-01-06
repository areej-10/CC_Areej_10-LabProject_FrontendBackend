# AWS Multi-Tier Architecture: Nginx HA Load Balancer

This project automates the deployment of a high-availability web infrastructure on AWS using **Terraform** for Infrastructure as Code (IaC) and **Ansible Roles** for configuration management.



## 🏗️ Architecture
- **Frontend**: 1 EC2 Instance running Nginx as a Reverse Proxy.
- **Backends**: 3 EC2 Instances running Apache (HTTPD).
- **Load Balancing**: Nginx is configured with an `upstream` block using:
  - 2 Active Primary Servers (Round-Robin).
  - 1 Backup Server (Active only if primaries fail).

## 🚀 Deployment Instructions

### Prerequisites
1. AWS Credentials configured in your environment.
2. SSH Key Pair named `id_ed25519` generated in `~/.ssh/`.
3. Terraform and Ansible installed.

### Steps
1. **Initialize Terraform**:
   ```bash
   terraform init