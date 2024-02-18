#! /bin/bash

# Установка Docker
sudo apt-get update -y
sudo apt-get install apt-transport-https ca-certificates curl gnupg lsb-release -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker.io docker-compose

# Установка GitLab Runner
# curl -LJO "https://gitlab-runner-downloads.s3.amazonaws.com/latest/deb/gitlab-runner_amd64.deb"
# dpkg -i gitlab-runner_amd64.deb
# sudo usermod -aG docker gitlab-runner
# sudo systemctl restart gitlab-runner.service
# sudo gitlab-runner register \
#     --non-interactive \
#     --url "https://gitlab.com/" \
#     --registration-token "GR13489419kd3bZ3sEKAwmoFjgX9B" \
#     --tag-list "database-vm,shell,azure" \
#     --description "codechecker" \
#     --executor "shell"
