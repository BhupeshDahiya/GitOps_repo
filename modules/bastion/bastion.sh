#!/bin/bash
# Direct all output to a log file so you can watch execution progress via tail -f
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "==================== STARTING BASTION CONFIGURATION ===================="

# 1. Update system package headers
apt-get update -y

# 2. Install basic utility dependencies
apt-get install unzip wget -y

# 3. Install Cloud & Kubernetes Tooling via Snaps
snap install aws-cli --classic
snap install kubectl --classic

# 4. Automate Cluster Registration (The Portfolio Touch)
# This hooks your kubectl context to your cluster automatically on system boot
echo "Configuring cluster context for EKS..."
/snap/bin/aws eks update-kubeconfig --region us-east-1 --name gitops_cluster

echo "==================== BASTION SETUP COMPLETE ===================="