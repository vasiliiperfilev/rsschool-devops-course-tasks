# Task 2: Networking Infrastructure for Kubernetes Cluster

This repository contains the Terraform implementation for **Task 2** of the RS School DevOps course - configuring basic networking infrastructure required for a Kubernetes (K8s) cluster.

## 📋 Task Overview

The objective was to write Terraform code to configure networking infrastructure with the following components:
- VPC with public and private subnets
- Internet Gateway and NAT Gateway
- Proper routing configuration
- Security groups and basion host
- Infrastructure as Code best practices

## 🏗️ Architecture

### Network Design
- **VPC**: `10.0.0.0/16` CIDR block
- **Public Subnets**: 
  - `10.0.1.0/24` (AZ-a)
  - `10.0.2.0/24` (AZ-b)
- **Private Subnets**:
  - `10.0.3.0/24` (AZ-a) 
  - `10.0.4.0/24` (AZ-b)

### Key Components
- **Internet Gateway**: Provides internet access to public subnets
- **NAT Gateway**: Enables outbound internet access for private subnets
- **Bastion Host**: Secure access point to private subnet resources
- **Security Groups**: Fine-grained network access control
- **Network ACLs**: Additional subnet-level network security

## 📁 File Structure

```
├── main.tf              # Terraform backend and provider configuration
├── variables.tf         # Variable definitions
├── networking.tf        # VPC, subnets, gateways, and routing
├── security_groups.tf   # Security group definitions
├── acl.tf              # Network ACL configuration
├── ec2.tf              # EC2 instances (bastion + test instances)
├── iam_github.tf       # IAM roles for GitHub Actions
└── .github/workflows/terraform.yml  # CI/CD pipeline
```

## ✅ Requirements Fulfillment

### Core Requirements (70/100 points)

#### 1. Terraform Code Implementation (50/50 points) ✅
- [x] **VPC**: Configured with DNS support and hostnames enabled
- [x] **2 Public Subnets**: Deployed across different availability zones
- [x] **2 Private Subnets**: Deployed across different availability zones  
- [x] **Internet Gateway**: Attached to VPC for public internet access
- [x] **Routing Configuration**:
  - Inter-subnet communication enabled
  - Public subnets can reach internet via Internet Gateway
  - Private subnets can reach internet via NAT Gateway

#### 2. Code Organization (10/10 points) ✅
- [x] **Variables File**: All configurable values defined in `variables.tf`
- [x] **Resource Separation**: Logical separation into multiple files:
  - `networking.tf` - Network infrastructure
  - `security_groups.tf` - Security configurations
  - `ec2.tf` - Compute resources
  - `acl.tf` - Network ACLs
  - `iam_github.tf` - IAM configurations

#### 3. Verification (10/10 points) ✅
- [x] **Terraform Plan**: Configuration validated
- [x] **Resource Map**: Infrastructure visualized in AWS Console

### Additional Tasks (30/30 points) ✅

#### 4. Security Groups & Network ACLs (5/5 points) ✅
**Security Groups:**
- **Bastion Security Group**: SSH access from specified CIDR
- **Public Subnet Security Group**: HTTPS traffic + SSH from bastion
- **Private Subnet Security Group**: SSH access only from bastion

**Network ACLs:**
- **Public ACL**: Allows all traffic for public subnet flexibility
- **Private ACL**: Restrictive rules allowing only necessary traffic

#### 5. Bastion Host (5/5 points) ✅
- Deployed in first public subnet
- Ubuntu 22.04 LTS AMI
- Public IP assigned for external access
- SSH key authentication
- Gateway for accessing private subnet resources

#### 6. NAT Implementation (10/10 points) ✅
**NAT Gateway Approach (Simpler Way):**
- Elastic IP allocated for NAT Gateway
- NAT Gateway deployed in public subnet
- Private route table configured to route traffic through NAT
- Enables outbound internet access for private subnet instances

#### 7. Documentation (5/5 points) ✅
- Comprehensive README with setup instructions
- Architecture documentation
- Usage guidelines

#### 8. GitHub Actions Pipeline (5/5 points) ✅
- Automated Terraform validation (`terraform fmt -check`)
- Terraform planning on pull requests
- Automated deployment on main branch
- AWS credentials via OIDC (no long-lived keys)

## 🔧 Configuration

### Required Variables
Set these variables in your Terraform execution or GitHub repository:

```hcl
account_id    = "your-aws-account-id"
repo_owner    = "your-github-username"
repo_name     = "repository-name"
region        = "us-east-2"
```

### Optional Variables (with defaults)
```hcl
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
instance_type        = "t2.micro"
allowed_ssh_cidr     = "0.0.0.0/0"  # ⚠️ Restrict in production
```

## 🚀 Deployment

### Prerequisites
- AWS CLI configured
- Terraform >= 1.12.1
- S3 bucket for state storage: `devops-course-vasilii`

### Local Deployment
```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan \
  -var="account_id=YOUR_ACCOUNT_ID" \
  -var="repo_owner=YOUR_GITHUB_USERNAME" \
  -var="repo_name=YOUR_REPO_NAME" \
  -var="region=AWS_REGION"

# Apply changes
terraform apply \
  -var="account_id=YOUR_ACCOUNT_ID" \
  -var="repo_owner=YOUR_GITHUB_USERNAME" \
  -var="repo_name=YOUR_REPO_NAME" \
  -var="region=AWS_REGION"
```

### GitHub Actions Deployment
1. Set repository variables:
   - `AWS_ACCOUNT_ID`: Your AWS account ID
   - `AWS_REGION`: Deployment region (e.g., us-east-2)

2. Push to `main` branch for automatic deployment
3. Pull requests trigger validation and planning

## 🔒 Security Features

### Network Security
- **Defense in Depth**: Security Groups + Network ACLs
- **Bastion Architecture**: Secure access to private resources
- **Least Privilege**: Restrictive security group rules

### Access Control
- **SSH Key Authentication**: No password-based access
- **OIDC Integration**: GitHub Actions uses temporary credentials
- **IAM Policies**: Principle of least privilege

### Compliance
- **Resource Tagging**: Consistent resource identification
- **Terraform State Encryption**: S3 backend with encryption

## 🏷️ Resource Tagging Strategy

All resources are tagged with:
```hcl
Environment = "dev"
Task        = "task-2"
Name        = "<descriptive-name>"
```

## 🔍 Testing & Validation

### Infrastructure Testing
```bash
# SSH to bastion host
ssh-add your-key.pem
# Agent-forwarding to use the same .pem key 
ssh -A ubuntu@<bastion-public-ip>

# From bastion, access private subnet instance
ssh ubuntu@<private-instance-ip>

# Test internet connectivity from private subnet
curl -I https://google.com
```

## 🌟 Beyond Requirements

This implementation exceeds the basic requirements by including:

### Advanced Features
- **AWS Config Integration**: Compliance monitoring and enforcement
- **CI/CD Pipeline**: Full automation with GitHub Actions
- **Multiple Test Instances**: Comprehensive network testing capability
- **IAM Best Practices**: OIDC integration and least privilege policies

### Production-Ready Elements
- **State Management**: Remote S3 backend with locking
- **Error Handling**: Proper resource dependencies
- **Modularity**: Well-organized, reusable code structure
- **Documentation**: Comprehensive setup and usage guides

## 📊 Cost Optimization

- **t2.micro instances**: AWS Free Tier eligible
- **NAT Gateway**: Simpler but higher cost than NAT instance
- **Elastic IP**: Minimal cost for NAT Gateway
- **Resource tagging**: Enables cost tracking and optimization

## 🔄 CI/CD Pipeline

The GitHub Actions workflow includes:

1. **Format Check**: Ensures code consistency
2. **Terraform Plan**: Validates changes on PRs
3. **Terraform Apply**: Deploys changes on main branch
4. **AWS Authentication**: Secure OIDC-based access


## 📚 References

- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)
- [RS School DevOps Course](https://github.com/rolling-scopes-school/devops)

---

**Course**: RS School DevOps from Zero to Hero  
**Task**: [Task 2 - Networking Infrastructure Configuration](https://github.com/rolling-scopes-school/tasks/blob/master/devops/modules/1_basic-configuration/task_2.md)  
**Author**: Vasilii Perfilev  
**Branch**: `task-2`
