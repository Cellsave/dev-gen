#!/bin/bash
set -e

echo '{"status":"running","progress":10,"message":"Starting Prometheus installation","logs":"Updating apt..."}'

sudo apt-get update -qq

echo '{"status":"running","progress":50,"message":"Installing Prometheus","logs":"Running apt-get install..."}'
sudo apt-get install -y prometheus

echo '{"status":"running","progress":80,"message":"Starting Prometheus","logs":"Enabling service..."}'
sudo systemctl enable prometheus
sudo systemctl start prometheus

echo '{"status":"success","progress":100,"message":"Prometheus installed successfully","logs":"Prometheus is running on port 9090"}'
