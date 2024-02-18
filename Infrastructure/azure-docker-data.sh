#! /bin/bash

# Install docker
sudo su
sudo apt-get update -y
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo   "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get -y docker-ce docker-ce-cli containerd.io docker.io docker-compose

# Install Github's Action Runner
cd /home/aitu
mkdir actions-runner && cd actions-runner
curl -O https://github.com/actions/runner/releases/download/v2.313.0/actions-runner-linux-x64-2.313.0.tar.gz; tar xzf ./actions-runner-linux-x64-2.313.0.tar.gz
export RUNNER_ALLOW_RUNASROOT="1" && sudo ./config.sh \
    --unattended \
    --labels master-0
    --url https://github.com/majestic-sprinters/ms-gateway \
    --token AQ6TNQEOYBQ7F5VXESQXL33F2DQO4 \
    --runnergroup Default && ./svc.sh install root && ./svc.sh start
