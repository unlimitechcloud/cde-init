#!/bin/bash
set -euo pipefail

sudo apt update -y
sudo apt upgrade -y
sudo apt install net-tools jq -y