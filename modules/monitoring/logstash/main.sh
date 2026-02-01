#!/bin/bash
set -e

echo '{"status":"running","progress":10,"message":"Starting Logstash installation","logs":"Checking prerequisites..."}'

# Check Java (Logstash needs it, though it comes bundled usually)
echo '{"status":"running","progress":20,"message":"Checking Repositories","logs":"Ensuring Elastic repo exists..."}'

if [ ! -f /etc/apt/sources.list.d/elastic-8.x.list ]; then
    curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elastic-archive-keyring.gpg --yes
    echo "deb [signed-by=/usr/share/keyrings/elastic-archive-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list
fi

echo '{"status":"running","progress":50,"message":"Installing Logstash","logs":"This may take a while..."}'
sudo apt-get update -qq
sudo apt-get install -y logstash

echo '{"status":"running","progress":80,"message":"Enabling service","logs":"Starting logstash..."}'
sudo systemctl enable logstash
sudo systemctl start logstash

echo '{"status":"success","progress":100,"message":"Logstash installed successfully","logs":"Logstash is running"}'
