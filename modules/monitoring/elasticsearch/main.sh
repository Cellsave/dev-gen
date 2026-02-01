#!/bin/bash
set -e

echo '{"status":"running","progress":10,"message":"Starting Elasticsearch installation","logs":"Checking system requirements..."}'

# Check memory (warn if < 4GB total)
KB_MEM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
MB_MEM=$((KB_MEM / 1024))
if [ "$MB_MEM" -lt 2000 ]; then
    echo '{"status":"warning","progress":15,"message":"Low Memory Warning","logs":"Elasticsearch requires significant RAM. You have less than 2GB."}'
fi

echo '{"status":"running","progress":20,"message":"Checking Repositories","logs":"Ensuring Elastic repo exists..."}'
if [ ! -f /etc/apt/sources.list.d/elastic-8.x.list ]; then
    curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elastic-archive-keyring.gpg --yes
    echo "deb [signed-by=/usr/share/keyrings/elastic-archive-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list
fi

echo '{"status":"running","progress":40,"message":"Installing Elasticsearch","logs":"This is a large package, please wait..."}'
sudo apt-get update -qq
sudo apt-get install -y elasticsearch

echo '{"status":"running","progress":80,"message":"Configuring service","logs":"Enabling automatic startup..."}'
sudo systemctl daemon-reload
sudo systemctl enable elasticsearch
sudo systemctl start elasticsearch

echo '{"status":"success","progress":100,"message":"Elasticsearch installed successfully","logs":"Service started. Password generation is required manually for first login."}'
