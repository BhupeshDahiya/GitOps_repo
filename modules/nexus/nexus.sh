#!/bin/bash
# Exit immediately if any command fails
set -e

# 1. CENTRALIZED VARIABLE DEFINITIONS
NEXUS_VERSION="3.92.0-03" # Updated to a valid, stable release
TARGET_WORKSPACE="/opt/nexus"

echo "Updating package indexes and pulling Java 21 runtime + unzip utility..."
sudo apt-get update -y
sudo apt-get install -y openjdk-21-jdk wget unzip

echo "Preparing workspace layout inside $TARGET_WORKSPACE..."
sudo mkdir -p "$TARGET_WORKSPACE"
cd "$TARGET_WORKSPACE"

echo "Downloading modern Sonatype Nexus assembly package v${NEXUS_VERSION}..."
# 🌟 Updated to use the correct Sonatype Zip distribution format
sudo wget "https://download.sonatype.com/nexus/3/sonatype-nexus-repository-${NEXUS_VERSION}-assembly.zip" -O nexus.zip

echo "Extracting zip archive payload..."
sudo unzip nexus.zip
sudo rm -f nexus.zip

# 2. DYNAMIC FOLDER DISCOVERY
# dynamic matching handles the zip folder structure
NEXUS_DIR_NAME=$(ls -d nexus-3* | head -n 1)
echo "Identified target binary folder: $NEXUS_DIR_NAME"

echo "Creating dedicated system runner user safely..."
if ! id -u nexus > /dev/null 2>&1; then
    sudo useradd -r -d "$TARGET_WORKSPACE" -s /bin/false nexus
fi

# 3. RECURSIVE PERMISSION ALIGNMENT
sudo chown -R nexus:nexus "$TARGET_WORKSPACE"

echo "Registering active execution profile permissions..."
echo "run_as_user=\"nexus\"" | sudo tee "$TARGET_WORKSPACE/$NEXUS_DIR_NAME/bin/nexus.rc" > /dev/null

echo "Building out declarative systemd service architecture..."
sudo tee /etc/systemd/system/nexus.service <<EOT > /dev/null
[Unit]
Description=Sonatype Nexus Repository Manager
After=network.target

[Service]
Type=forking
LimitNOFILE=65536
ExecStart=$TARGET_WORKSPACE/$NEXUS_DIR_NAME/bin/nexus start
ExecStop=$TARGET_WORKSPACE/$NEXUS_DIR_NAME/bin/nexus stop
User=nexus
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOT

echo "Reloading control daemons and initialization sequences..."
sudo systemctl daemon-reload
sudo systemctl enable nexus
sudo systemctl start nexus

echo "Nexus Automation Sequence Executed Successfully with Java 21!"