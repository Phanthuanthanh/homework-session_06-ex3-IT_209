#!/bin/bash
set -e

which ufw >/dev/null 2>&1 || { sudo apt-get update && sudo apt-get install -y ufw; }
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw allow 8080/tcp
sudo ufw --force enable
sudo ufw status verbose
