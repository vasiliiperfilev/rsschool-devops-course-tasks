#!/bin/bash

# K3s Deployment Script for AWS EC2 Instances
# This script deploys K3s from the bastion host to private instances

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



# Function to get private IPs of instances
get_instance_ips() {
    local region=$(get_metadata "placement/region")
    
    if [[ -z "$region" ]]; then
        print_error "Could not determine AWS region from metadata service"
        exit 1
    fi
    
    print_message "Searching for instances in region: $region" >&2
    
    # Get K3s server IP
    print_message "Looking for K3S-server instance..." >&2
    SERVER_IP=$(aws ec2 describe-instances --region "$region" \
        --filters "Name=tag:Name,Values=K3S-server" "Name=instance-state-name,Values=running" \
        --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text 2>/dev/null || echo "")
    
    # Get K3s worker IP
    print_message "Looking for K3S-worker instance..." >&2
    WORKER_IP=$(aws ec2 describe-instances --region "$region" \
        --filters "Name=tag:Name,Values=K3S-worker" "Name=instance-state-name,Values=running" \
        --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text 2>/dev/null || echo "")
    
    if [[ -z "$SERVER_IP" || "$SERVER_IP" == "None" ]]; then
        print_error "Could not find K3S-server instance"
        print_error "Make sure there is a running EC2 instance with Name tag 'K3S-server'"
        exit 1
    fi
    
    if [[ -z "$WORKER_IP" || "$WORKER_IP" == "None" ]]; then
        print_error "Could not find K3S-worker instance"
        print_error "Make sure there is a running EC2 instance with Name tag 'K3S-worker'"
        exit 1
    fi
    
    print_message "✅ Found K3S-server at: $SERVER_IP" >&2
    print_message "✅ Found K3S-worker at: $WORKER_IP" >&2
}

# Function to copy script to instances
copy_script() {
    print_message "Copying K3s installation script to instances..."
    
    if [[ ! -f "install_k3s.sh" ]]; then
        print_error "install_k3s.sh not found in current directory"
        exit 1
    fi
    
    # Copy script to both instances
    scp -o StrictHostKeyChecking=no k3s_helpers.sh install_k3s.sh ubuntu@$SERVER_IP:~/
    scp -o StrictHostKeyChecking=no k3s_helpers.sh install_k3s.sh ubuntu@$WORKER_IP:~/
    
    # Make script executable on both instances
    ssh -o StrictHostKeyChecking=no ubuntu@$SERVER_IP "chmod +x ~/install_k3s.sh"
    ssh -o StrictHostKeyChecking=no ubuntu@$WORKER_IP "chmod +x ~/install_k3s.sh"
    
    print_message "Script copied and made executable on both instances"
}

# Function to install K3s on server
install_server() {
    print_header "Installing K3s SERVER on $SERVER_IP"
    
    # Execute installation script on server
    ssh -o StrictHostKeyChecking=no ubuntu@$SERVER_IP "sudo ./install_k3s.sh" || {
        print_error "Failed to install K3s server"
        return 1
    }
    
    print_message "K3s server installation completed successfully"
}

# Function to install K3s on worker
install_worker() {
    print_header "Installing K3s WORKER on $WORKER_IP"
    
    # Get node token from server
    print_message "Retrieving node token from K3s server..."
    local max_attempts=30
    local attempt=0
    local node_token=""
    
    while [ $attempt -lt $max_attempts ]; do
        if node_token=$(ssh -o StrictHostKeyChecking=no ubuntu@$SERVER_IP "sudo cat /var/lib/rancher/k3s/server/node-token 2>/dev/null" 2>/dev/null); then
            if [[ ! -z "$node_token" ]]; then
                break
            fi
        fi
        
        print_message "Attempt $((attempt + 1))/$max_attempts: Waiting for server to generate token..."
        sleep 10
        attempt=$((attempt + 1))
    done
    
    if [[ -z "$node_token" ]]; then
        print_error "Failed to retrieve node token from K3s server after $max_attempts attempts"
        print_error "Please ensure the K3s server is running and accessible"
        return 1
    fi
    
    print_message "Successfully retrieved node token from server"
    
    # Execute installation script on worker with token
    ssh -o StrictHostKeyChecking=no ubuntu@$WORKER_IP "sudo ./install_k3s.sh '$node_token'" || {
        print_error "Failed to install K3s worker"
        return 1
    }
    
    print_message "K3s worker installation completed successfully"
}

# Function to verify cluster status
verify_cluster() {
    print_header "Verifying K3s cluster status"
    
    print_message "Cluster nodes:"
    ssh -o StrictHostKeyChecking=no ubuntu@$SERVER_IP "sudo k3s kubectl get nodes -o wide" || {
        print_warning "Could not retrieve cluster status"
        return 1
    }
    
    print_message "Cluster services:"
    ssh -o StrictHostKeyChecking=no ubuntu@$SERVER_IP "sudo k3s kubectl get svc -A" || {
        print_warning "Could not retrieve service status"
    }
}

# Main execution
main() {
    print_header "Starting K3s Deployment Process"
    
    # Install AWS CLI if needed
    install_aws_cli
    
    # Get instance IPs
    get_instance_ips
    
    # Check SSH connectivity
    print_message "Checking SSH connectivity to instances..."
    
    if ! check_ssh_connectivity $SERVER_IP 10; then
        print_error "Cannot connect to K3S-server at $SERVER_IP"
        exit 1
    fi
    
    if ! check_ssh_connectivity $WORKER_IP 10; then
        print_error "Cannot connect to K3S-worker at $WORKER_IP"
        exit 1
    fi
    
    print_message "SSH connectivity verified for both instances"
    
    # Copy installation script
    copy_script
    
    # Install K3s server first
    if ! install_server; then
        print_error "Server installation failed, aborting deployment"
        exit 1
    fi
    
    # Wait a bit for server to stabilize
    print_message "Waiting for server to stabilize..."
    sleep 30
    
    # Install K3s worker
    if ! install_worker; then
        print_error "Worker installation failed"
        print_message "Server is still running, you can retry worker installation manually"
        exit 1
    fi
    
    # Wait a bit for worker to join
    print_message "Waiting for worker to join cluster..."
    sleep 20
    
    # Verify cluster
    verify_cluster
    
    print_header "K3s deployment completed successfully!"
}

# Execute main function
main "$@" 