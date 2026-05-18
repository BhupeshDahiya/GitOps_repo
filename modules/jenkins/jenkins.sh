#!/bin/bash
# Stop execution immediately if any command encounters an error
set -e

echo "Updating local package indexes..."
sudo apt-get update -y

echo "Installing required font engines and Java 21..."
sudo apt-get install -y fontconfig openjdk-21-jdk # can use openjdk-25-jdk as well, 17 isnt supported by jenkins anymore

echo "Downloading the valid 2026 Jenkins repository signing key..."
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key

echo "Adding the Jenkins repository to the local system sources..."
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

echo "Syncing new repository configurations..."
sudo apt-get update -y

echo "Installing the Jenkins engine..."
sudo apt-get install jenkins -y

# Force systemd to kickstart the engine if cloud-init blocked the post-install hook
echo "Enforcing explicit service start..."
sudo systemctl daemon-reload
sudo systemctl enable jenkins
sudo systemctl start jenkins

echo "Jenkins bootstrap sequence completed successfully!"