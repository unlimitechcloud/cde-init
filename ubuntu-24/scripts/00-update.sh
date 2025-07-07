#!/bin/bash
set -euo pipefail

sudo apt update -y
sudo apt upgrade -y
sudo apt install net-tools jq make xmlstarlet -y
sudo sysctl fs.inotify.max_user_watches=1000000