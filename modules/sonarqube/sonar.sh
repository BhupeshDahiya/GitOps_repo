#!/bin/bash
# Direct all outputs to a log file for real-time tracking via Bastion
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "==================== STARTING SONARQUBE LTA DEPLOYMENT ===================="

# 1. Apply mandatory kernel parameters required by SonarQube's embedded Elasticsearch
cp /etc/sysctl.conf /root/sysctl.conf_backup
cat <<EOT >> /etc/sysctl.conf
vm.max_map_count=524288
fs.file-max=131072
EOT
sysctl -p

# 2. Update system packages and install Docker dependencies
apt-get update -y
apt-get install -y apt-transport-https ca-certificates curl software-properties-common unzip gnupg

# 3. Install Docker CE Engine natively
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Ensure Docker starts on system boot
systemctl enable docker
systemctl start docker

# 4. Create dedicated application space with stateful volume persistence
mkdir -p /opt/sonarqube-stack/data
mkdir -p /opt/sonarqube-stack/extensions
mkdir -p /opt/sonarqube-stack/logs
mkdir -p /opt/sonarqube-stack/postgres_data

# Fix permissions for mapped folders (Elasticsearch container runs as UID 1000)
chown -R 1000:1000 /opt/sonarqube-stack/data /opt/sonarqube-stack/extensions /opt/sonarqube-stack/logs

# 5. Establish the multi-container stack deployment layout
cat << 'EOT' > /opt/sonarqube-stack/docker-compose.yml
version: "3.8"

services:
  sonarqube-db:
    image: postgres:15-alpine
    container_name: sonarqube-postgres
    environment:
      - POSTGRES_USER=sonar
      - POSTGRES_PASSWORD=sonar_secure_pass123
      - POSTGRES_DB=sonarqube
    volumes:
      - /opt/sonarqube-stack/postgres_data:/var/lib/postgresql/data
    networks:
      - sonar-network
    restart: always

  sonarqube:
    image: sonarqube:2025.1-community  
    container_name: sonarqube-app
    depends_on:
      - sonarqube-db
    ports:
      - "9000:9000"
    environment:
      - SONAR_JDBC_USERNAME=sonar
      - SONAR_JDBC_PASSWORD=sonar_secure_pass123
      - SONAR_JDBC_URL=jdbc:postgresql://sonarqube-db:5432/sonarqube?currentSchema=public 
    volumes:
      - /opt/sonarqube-stack/data:/opt/sonarqube/data
      - /opt/sonarqube-stack/extensions:/opt/sonarqube/extensions
      - /opt/sonarqube-stack/logs:/opt/sonarqube/logs
    ulimits:
      nofile:
        soft: 65536
        hard: 65536
    networks:
      - sonar-network
    restart: always

networks:
  sonar-network:
    driver: bridge
EOT

# 6. Spin up the cluster stack in background detached mode
cd /opt/sonarqube-stack
docker compose up -d

echo "==================== DEPLOYMENT STEP COMPLETE ===================="