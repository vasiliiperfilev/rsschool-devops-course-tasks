#!/bin/bash

# K3s Common Helper Functions
# Shared utilities for K3s deployment scripts

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}[DEPLOY]${NC} $1"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        exit 1
    fi
}

# Function to get EC2 metadata using IMDSv2 (security enforced)
get_metadata() {
    local metadata_path="$1"
    
    # Get IMDSv2 token (required by our Terraform configuration)
    local token=""
    token=$(curl -s --max-time 5 -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" 2>/dev/null || echo "")
    
    if [[ -z "$token" ]]; then
        print_error "Failed to get IMDSv2 token. This instance requires IMDSv2."
        print_error "Check that metadata service is enabled and IMDSv2 is supported."
        exit 1
    fi
    
    # Use IMDSv2 token to get metadata
    local result=""
    result=$(curl -s --max-time 10 -H "X-aws-ec2-metadata-token: $token" "http://169.254.169.254/latest/meta-data/${metadata_path}" 2>/dev/null || echo "")
    
    if [[ -z "$result" ]]; then
        print_error "Failed to retrieve metadata: ${metadata_path}"
        exit 1
    fi
    
    echo "$result"
}

# Function to install AWS CLI if not present
install_aws_cli() {
    if ! command -v aws &> /dev/null; then
        print_message "AWS CLI not found. Installing AWS CLI..."
        
        # Detect the OS and install accordingly
        if [[ -f /etc/debian_version ]]; then
            # Debian/Ubuntu
            apt-get update -y
            apt-get install -y awscli curl unzip
            
            # If the package version is too old, install latest version
            if ! aws --version | grep -q "aws-cli/2" 2>/dev/null; then
                print_message "Installing latest AWS CLI v2..."
                curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
                unzip -q awscliv2.zip
                ./aws/install --update
                rm -rf awscliv2.zip aws/
                # Update PATH for current session
                export PATH=/usr/local/bin:$PATH
            fi
        elif [[ -f /etc/redhat-release ]]; then
            # RHEL/CentOS/Amazon Linux
            if command -v yum &> /dev/null; then
                yum install -y awscli curl unzip
            elif command -v dnf &> /dev/null; then
                dnf install -y awscli curl unzip
            fi
        else
            print_warning "Unknown OS. Please install AWS CLI manually."
            print_error "AWS CLI is required for this script to work."
            exit 1
        fi
        
        # Verify installation
        if ! command -v aws &> /dev/null; then
            print_error "Failed to install AWS CLI. Please install it manually."
            exit 1
        fi
        
        print_message "AWS CLI installed successfully: $(aws --version)"
    else
        print_message "AWS CLI is already available: $(aws --version)"
    fi
    
    # Configure AWS CLI to use instance metadata service
    configure_aws_cli
}

# Function to configure AWS CLI for instance metadata
configure_aws_cli() {
    print_message "Configuring AWS CLI to use IMDSv2 metadata service..."
    
    # Get region from metadata service using IMDSv2
    local region=$(get_metadata "placement/region")
    
    # Set AWS CLI environment variables to use instance metadata
    export AWS_DEFAULT_REGION="$region"
    export AWS_REGION="$region"
    export AWS_EC2_METADATA_DISABLED=false
    
    # Create AWS CLI config directory if it doesn't exist
    mkdir -p ~/.aws
    
    # Create/update AWS CLI config to use instance metadata
    cat > ~/.aws/config << EOF
[default]
region = $region
credential_source = Ec2InstanceMetadata
EOF
    
    print_message "AWS CLI configured for region: $region with IMDSv2"
    
    # Debug: Check if IAM role is attached
    local iam_info=$(get_metadata "iam/security-credentials/")
    
    if [[ ! -z "$iam_info" ]]; then
        print_message "IAM role detected: $iam_info"
    else
        print_warning "No IAM role detected on this instance"
    fi
    
    # Test AWS CLI with a simple call
    print_message "Testing AWS CLI credentials..."
    if aws sts get-caller-identity --region "$region" &>/dev/null; then
        print_message "✅ AWS CLI credentials are working with IMDSv2"
    else
        print_warning "AWS CLI credentials test failed, but continuing..."
        print_warning "Make sure the IAM role has the required permissions:"
        print_warning "- ec2:DescribeInstances"
        print_warning "- ec2:DescribeTags"
        
        # Additional debugging
        print_warning "Debug: Trying to get caller identity..."
        aws sts get-caller-identity --region "$region" 2>&1 | head -5 | while read line; do
            print_warning "  $line"
        done
    fi
}

# Function to get current instance metadata
get_current_instance_info() {
    local instance_id=$(get_metadata "instance-id")
    local region=$(get_metadata "placement/region")
    
    if [[ -z "$instance_id" || -z "$region" ]]; then
        print_error "Failed to retrieve instance metadata. This script must run on an EC2 instance."
        print_error "If you're on EC2, check that the metadata service is accessible."
        exit 1
    fi
    
    # Output as space-separated values for easy assignment
    echo "$instance_id $region"
}

# Function to wait for service to be ready
wait_for_service() {
    local service_name="$1"
    local max_attempts="${2:-60}"
    local attempt=0
    
    print_message "Waiting for $service_name to be ready..."
    while [ $attempt -lt $max_attempts ]; do
        if systemctl is-active --quiet "$service_name"; then
            print_message "✅ $service_name is ready"
            return 0
        fi
        sleep 5
        attempt=$((attempt + 1))
    done
    
    print_error "$service_name failed to become ready within timeout"
    return 1
}

# Function to check SSH connectivity
check_ssh_connectivity() {
    local host="$1"
    local timeout="${2:-10}"
    
    if ssh -o ConnectTimeout="$timeout" -o StrictHostKeyChecking=no ubuntu@$host "echo 'Connection OK'" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

print_message "K3s helper functions loaded" >&2 