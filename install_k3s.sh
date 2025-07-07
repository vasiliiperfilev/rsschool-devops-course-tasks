#!/bin/bash

# K3s Installation Script for AWS EC2 Instances
# This script installs and configures K3s server or worker based on the instance role

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the common helpers
if [[ -f "$SCRIPT_DIR/k3s_helpers.sh" ]]; then
    source "$SCRIPT_DIR/k3s_helpers.sh"
else
    echo "Error: Cannot find k3s_helpers.sh in $SCRIPT_DIR"
    exit 1
fi



# Function to detect instance role based on EC2 tags
detect_instance_role() {
    # Get instance metadata using helper function
    local instance_info=$(get_current_instance_info)
    local instance_id=$(echo $instance_info | cut -d' ' -f1)
    local region=$(echo $instance_info | cut -d' ' -f2)
    
    print_message "Instance ID: $instance_id, Region: $region" >&2
    
    # Try to get the Name tag of the current instance
    local name_tag=$(aws ec2 describe-tags --region "$region" --filters "Name=resource-id,Values=$instance_id" "Name=key,Values=Name" --query 'Tags[0].Value' --output text 2>/dev/null || echo "")
    
    if [[ -z "$name_tag" || "$name_tag" == "None" ]]; then
        print_error "Could not retrieve instance tags. Check IAM permissions for ec2:DescribeTags"
        exit 1
    fi
    
    if [[ "$name_tag" == "K3S-server" ]]; then
        print_message "This instance is a K3S-server" >&2
        echo "K3S-server"
    elif [[ "$name_tag" == "K3S-worker" ]]; then
        print_message "This instance is a K3S-worker" >&2
        echo "K3S-worker"
    else
        print_error "Could not determine instance role from tags. Expected 'K3S-server' or 'K3S-worker', got: '$name_tag'"
        exit 1
    fi
}

# Function to get private IP of K3s server
get_server_ip() {
    local region=$(get_metadata "placement/region")
    
    if [[ -z "$region" ]]; then
        print_error "Could not determine AWS region"
        exit 1
    fi
    
    print_message "Looking for K3S-server instance in region: $region" >&2
    
    # Get the private IP of the instance tagged as K3S-server
    local server_ip=$(aws ec2 describe-instances --region "$region" \
        --filters "Name=tag:Name,Values=K3S-server" "Name=instance-state-name,Values=running" \
        --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text 2>/dev/null || echo "")
    
    if [[ -z "$server_ip" || "$server_ip" == "None" ]]; then
        print_error "Could not find private IP of K3S-server instance"
        print_error "Make sure there is a running instance tagged with Name=K3S-server"
        exit 1
    fi
    
    print_message "Found K3S-server at IP: $server_ip" >&2
    echo "$server_ip"
}

# Function to install K3s server
install_k3s_server() {
    print_message "Installing K3s server..."
    
    # Install K3s server
    curl -sfL https://get.k3s.io | sh -s - server \
        --disable traefik \
        --write-kubeconfig-mode 644
    
    # Wait for K3s to be ready
    if ! wait_for_service "k3s" 60; then
        print_error "K3s server failed to become ready within timeout"
        exit 1
    fi
    
    # Wait for node to be ready
    local max_attempts=60
    local attempt=0
    while [ $attempt -lt $max_attempts ]; do
        if k3s kubectl get nodes | grep -q "Ready"; then
            break
        fi
        sleep 5
        attempt=$((attempt + 1))
    done
    
    if [ $attempt -eq $max_attempts ]; then
        print_error "K3s server failed to become ready within timeout"
        exit 1
    fi
    
    print_message "K3s server installation completed successfully!"
    print_message "Node token is stored in: /var/lib/rancher/k3s/server/node-token"
    print_message "Kubeconfig is stored in: /etc/rancher/k3s/k3s.yaml"
    
    # Display cluster status
    print_message "Current cluster status:"
    k3s kubectl get nodes -o wide
}

# Function to install K3s worker
install_k3s_worker() {
    print_message "Installing K3s worker..."
    
    local server_ip=$(get_server_ip)
    print_message "Detected K3s server IP: $server_ip"
    
    # Check if node token was provided as argument
    if [[ -z "$1" ]]; then
        print_error "Node token not provided. This script should be called with the token as an argument for worker installation."
        print_error "Usage: sudo ./install_k3s.sh <node_token>"
        exit 1
    fi
    
    local node_token="$1"
    print_message "Using provided node token for cluster join"
    
    # Install K3s agent
    curl -sfL https://get.k3s.io | K3S_URL=https://$server_ip:6443 K3S_TOKEN=$node_token sh -
    
    # Wait for agent to be ready
    if ! wait_for_service "k3s-agent" 60; then
        print_error "K3s agent failed to become ready within timeout"
        exit 1
    fi
    
    print_message "K3s worker installation completed successfully!"
    print_message "Worker has joined the cluster at: https://$server_ip:6443"
}

# Main execution
main() {
    print_message "Starting K3s installation script..."
    
    # Check if running as root
    check_root
    
    # Install AWS CLI if needed
    install_aws_cli
    
    # Update system packages and install dependencies
    print_message "Updating system packages and installing dependencies..."
    apt-get update -y
    apt-get install -y curl wget git jq
    
    # Detect instance role
    local role=$(detect_instance_role)
    print_message "Detected instance role: $role"
    
    # Install K3s based on role
    if [[ "$role" == "K3S-server" ]]; then
        install_k3s_server
    elif [[ "$role" == "K3S-worker" ]]; then
        # For worker, expect token as first argument
        install_k3s_worker "$1"
    else
        print_error "Unknown role: $role"
        exit 1
    fi
    
    print_message "K3s installation and configuration completed successfully!"
}

# Execute main function
main "$@" 