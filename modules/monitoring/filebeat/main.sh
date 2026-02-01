#!/bin/bash
set -e

echo '{"status":"running","progress":10,"message":"Starting Filebeat installation","logs":"Checking prerequisites..."}'

if ! command -v curl &> /dev/null; then
    echo '{"status":"error","progress":0,"message":"curl not found","logs":"Please install curl first"}'
    exit 1
fi

echo '{"status":"running","progress":30,"message":"Adding Elastic GPG Key","logs":"Downloading GPG key..."}'
curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elastic-archive-keyring.gpg --yes

echo '{"status":"running","progress":50,"message":"Adding repository","logs":"Adding apt repository..."}'
echo "deb [signed-by=/usr/share/keyrings/elastic-archive-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list

echo '{"status":"running","progress":70,"message":"Installing Filebeat","logs":"Running apt-get install..."}'
sudo apt-get update -qq
sudo apt-get install -y filebeat

echo '{"status":"running","progress":90,"message":"Enabling service","logs":"Starting filebeat..."}'
sudo systemctl enable filebeat
sudo systemctl start filebeat

echo '{"status":"success","progress":100,"message":"Filebeat installed successfully","logs":"Filebeat is running"}'
