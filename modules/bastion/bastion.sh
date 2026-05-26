#!/bin/bash
# Direct all output to a log file so you can watch execution progress via tail -f
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "==================== STARTING BASTION CONFIGURATION ===================="

# 1. Update apt and get useful utilities
apt-get update -y
apt-get install unzip wget curl jq -y

# 2. Install Native AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf awscliv2.zip aws/

# 3. Install Native Kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

# 4. Install Native Helm v3
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# 5. EKS Initialization Wait Loop
echo "Poller: Waiting for EKS cluster 'gitops_cluster' to reach ACTIVE state..."
while true; do
  STATUS=$(aws eks describe-cluster --region us-east-1 --name gitops_cluster --query "cluster.status" --output text 2>/dev/null || echo "NOT_FOUND")
  if [ "$STATUS" = "ACTIVE" ]; then
    echo "EKS cluster is ACTIVE!"
    break
  fi
  echo "Cluster status is currently: ${STATUS}. Sleeping 30 seconds..."
  sleep 30
done

# 6. Configure Cluster Context for the UBUNTU User (Not Root)
echo "Configuring cluster context for EKS under ubuntu user profile..."
SU_USER="ubuntu"
SU_HOME="/home/ubuntu"

# Force the AWS command to generate config inside the ubuntu home directory
runuser -l $SU_USER -c "aws eks update-kubeconfig --region us-east-1 --name gitops_cluster"

echo "==================== BASTION SETUP COMPLETE ===================="