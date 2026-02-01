#!/bin/bash
set -e

echo '{"status":"running","progress":10,"message":"Starting Kibana installation","logs":"Checking prerequisites..."}'

if [ ! -f /etc/apt/sources.list.d/elastic-8.x.list ]; then
    curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elastic-archive-keyring.gpg --yes
    echo "deb [signed-by=/usr/share/keyrings/elastic-archive-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list
fi

echo '{"status":"running","progress":40,"message":"Installing Kibana","logs":"Downloading Kibana..."}'
sudo apt-get update -qq
sudo apt-get install -y kibana

echo '{"status":"running","progress":80,"message":"Starting Kibana","logs":"Enabling service..."}'
sudo systemctl daemon-reload
sudo systemctl enable kibana
sudo systemctl start kibana

echo '{"status":"success","progress":100,"message":"Kibana installed successfully","logs":"Access Kibana at http://localhost:5601"}'
