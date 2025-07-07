# Task 4: Jenkins Installation on Kubernetes with Helm v3

This document provides step-by-step instructions for installing Jenkins on a Kubernetes cluster using Helm v3, based on the official Jenkins documentation.

## Prerequisites

Before proceeding with the installation, ensure you have:

1. **Kubernetes Cluster**: A running Kubernetes cluster (v1.19+) (I used minikube)
2. **kubectl**: Configured to communicate with your cluster
3. **Helm v3**: Package manager for Kubernetes

## Installation Steps

### Step 1: Install Helm v3

If Helm is not already installed, install it using one of the following methods:

**On macOS:**
```bash
brew install helm
```

**On Linux:**
```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

**Verify installation:**
```bash
helm version
```

### Step 2: Configure Helm

Add the Jenkins Helm repository:

```bash
helm repo add jenkins https://charts.jenkins.io
helm repo update
```

### Step 3: Create Namespace

Create a dedicated namespace for Jenkins:

```bash
kubectl create namespace jenkins
```

### Step 4: Create Persistent Volume

Create a persistent volume for Jenkins data persistence. You can use the provided `volume.yaml` file:

```bash
kubectl apply -f k8s/jenkins/volume.yaml
```

**Note:** You need to add permissions for the non-root user to access the volume
```bash
minikube ssh
sudo chown -R 1000:1000 /data/jenkins-volume
```

### Step 5: Create Service Account

Apply the service account configuration:

```bash
kubectl apply -f k8s/jenkins/account.yaml
```

This creates:
- Jenkins service account with necessary permissions
- ClusterRole and ClusterRoleBinding for Jenkins operations

### Step 6: Install Jenkins with Helm

Install Jenkins using Helm with custom values:

```bash
helm install jenkins jenkins/jenkins -n jenkins -f k8s/jenkins/values.yaml
```

### Step 7: Verify Installation

Check the deployment status:

```bash
# Check pods
kubectl get pods -n jenkins

# Check services
kubectl get svc -n jenkins

```

## Accessing Jenkins

### Get Jenkins URL

For NodePort service type:
```bash
jsonpath="{.spec.ports[0].nodePort}"
NODE_PORT=$(kubectl get -n jenkins -o jsonpath=$jsonpath services jenkins)
jsonpath="{.items[0].status.addresses[0].address}"
NODE_IP=$(kubectl get nodes -n jenkins -o jsonpath=$jsonpath)
echo http://$NODE_IP:$NODE_PORT/login
```

### Get Admin Password

Retrieve the initial admin password:

```bash
jsonpath="{.data.jenkins-admin-password}"
secret=$(kubectl get secret -n jenkins jenkins -o jsonpath=$jsonpath)
echo $(echo $secret | base64 --decode)
```

## Configuration Files

The following configuration files are included in this setup:

### `k8s/jenkins/volume.yaml`
- Creates PersistentVolume and StorageClass
- Configures local storage with 20Gi capacity
- Uses hostPath for demonstration (consider cloud storage for production)

### `k8s/jenkins/account.yaml`
- Defines ServiceAccount for Jenkins
- Creates ClusterRole with necessary permissions
- Binds role to service account

### `k8s/jenkins/values.yaml`
- Helm chart values for Jenkins configuration
- Customizes deployment, service, and persistence settings

## References

- [Jenkins Official Documentation](https://www.jenkins.io/doc/book/installing/kubernetes/)
- [Jenkins Helm Chart](https://github.com/jenkinsci/helm-charts)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
