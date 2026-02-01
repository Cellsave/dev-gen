#!/bin/bash
set -e

echo '{"status":"running","progress":10,"message":"Starting Grafana installation","logs":"Adding prerequisites..."}'
sudo apt-get install -y -qq software-properties-common

echo '{"status":"running","progress":30,"message":"Adding Grafana GPG key","logs":"Downloading key..."}'
sudo wget -q -O /usr/share/keyrings/grafana.key https://apt.grafana.com/gpg.key

echo '{"status":"running","progress":50,"message":"Adding repository","logs":"Adding stable repo..."}'
echo "deb [signed-by=/usr/share/keyrings/grafana.key] https://apt.grafana.com stable main" | sudo tee /etc/apt/sources.list.d/grafana.list

echo '{"status":"running","progress":70,"message":"Installing Grafana","logs":"Running apt-get install..."}'
sudo apt-get update -qq
sudo apt-get install -y grafana

echo '{"status":"running","progress":90,"message":"Starting Grafana","logs":"Enabling service..."}'
sudo systemctl daemon-reload
sudo systemctl enable grafana-server
sudo systemctl start grafana-server

echo '{"status":"success","progress":100,"message":"Grafana installed successfully","logs":"Access Grafana on port 3000 (admin/admin)"}'
