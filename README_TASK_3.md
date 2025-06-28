# Task 3: K3s Deployment on AWS EC2 Private Instances

This repository contains scripts and Terraform configurations to deploy a K3s Kubernetes cluster on AWS EC2 private instances accessed through a bastion host for **Task 3** of the RS School DevOps course.

## 📋 Task Overview

The objective is to deploy a K3s Kubernetes cluster on private AWS EC2 instances using:
- Automated installation scripts
- Secure bastion host access
- Proper networking configuration
- Infrastructure as Code with Terraform

## 🏗️ Architecture

```
Internet
    |
    v
[Internet Gateway]
    |
    v
[Public Subnet] - [Bastion Host]
    |
    v
[NAT Gateway]
    |
    v
[Private Subnets]
    |
    +-- [K3S-server] (10.0.3.x by default)
    |
    +-- [K3S-worker] (10.0.4.x by default)
```

## 📁 Components

### Infrastructure Files
- `main.tf` - Main Terraform configuration
- `ec2.tf` - EC2 instances with IAM roles
- `networking.tf` - VPC, subnets, routing
- `security_groups.tf` - Security groups with K3s ports
- `variables.tf` - Configuration variables
- `iam_github.tf` - GitHub Actions IAM configuration

### K3s Deployment Scripts
- `install_k3s.sh` - Main installation script (runs on instances)
- `deploy_k3s.sh` - Deployment orchestration script (runs from bastion)

## 🔧 Prerequisites

1. **AWS CLI** configured with appropriate permissions
2. **Terraform** installed and configured
3. **SSH key pair** created in AWS for EC2 access
4. **Bastion host** deployed and accessible

## 🚀 Deployment Steps

### 1. Deploy Infrastructure

```bash
# Apply Terraform configuration
terraform init
terraform plan
terraform apply
```

This will create:
- VPC with public and private subnets
- Bastion host in public subnet
- K3s server and worker instances in private subnets
- Security groups with K3s communication ports
- IAM roles for EC2 instance permissions

### 2. Connect to Bastion Host

```bash
# Add SSH key to agent
ssh-add your-key.pem

# Connect to bastion with agent forwarding
ssh -A ubuntu@<bastion-public-ip>
```

### 3. Copy Scripts to Bastion

From your **local machine**, copy the deployment scripts to the bastion host:

```bash
# Copy scripts to bastion
scp -vri ~/.ssh/your_key.pem k3s_helpers.sh install_k3s.sh deploy_k3s.sh ubuntu@<bastion-public-ip>:~/
```

### 4. Deploy K3s Cluster

From the **bastion host**, run the deployment script:

```bash
# Deploy K3s cluster
./deploy_k3s.sh
```

The deployment script will:
1. Detect private instance IPs automatically
2. Check SSH connectivity to private instances
3. Copy the installation script to both instances
4. Install K3s server on the first instance
5. Retrieve the node token from the server
6. Install K3s worker on the second instance (passing the token)
7. Verify cluster status

## 🔧 Script Features

### install_k3s.sh
- **Automatic Role Detection**: Uses EC2 tags to determine server vs worker role
- **Server Installation**: Installs K3s server with proper configuration
- **Worker Installation**: Accepts node token as argument and joins cluster
- **Error Handling**: Comprehensive error checking and colored output
- **Service Monitoring**: Waits for services to be ready before proceeding

### deploy_k3s.sh
- **Infrastructure Discovery**: Automatically finds instance IPs using AWS CLI
- **SSH Connectivity**: Verifies connection to all instances
- **Orchestrated Deployment**: Deploys server first, then worker with token passing
- **Token Management**: Retrieves node token from server and passes to worker
- **Cluster Verification**: Checks cluster status after deployment

## 🔒 Security Groups

The following ports are opened for K3s communication:
- **6443/tcp**: K3s API Server
- **10250/tcp**: Kubelet API
- **8472/udp**: Flannel VXLAN
- **10254/tcp**: Metrics server
- **All traffic**: Between private subnets (dynamically configured)

## 🌐 Accessing the Cluster

### From the K3s Server Instance

```bash
# SSH to server via bastion (agent forwarding enabled)
ssh ubuntu@<k3s-server-private-ip>

# Use k3s kubectl commands
sudo k3s kubectl get nodes
```

## 🎯 Connection Flow

```
Local Machine
    │
    │ ssh-add key.pem
    │ ssh -A ubuntu@bastion-ip
    │
    ▼
Bastion Host (Agent Forwarding)
    │
    │ ssh ubuntu@private-ip (no key needed)
    │
    ▼
K3s Server/Worker
```

## 📚 References

- [K3s Documentation](https://docs.k3s.io/)
- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)
- [RS School DevOps Course](https://github.com/rolling-scopes-school/devops)

---

**Course**: RS School DevOps from Zero to Hero  
**Task**: Task 3 - K3s Cluster Deployment  
**Author**: Vasilii Perfilev  
**Branch**: `task-3` 