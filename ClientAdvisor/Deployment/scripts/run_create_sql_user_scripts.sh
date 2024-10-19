#!/bin/bash
echo "Started the script"

python3 -m venv /tmp/myenv
source /tmp/myenv/bin/activate

# Install necessary system packages
sudo apt-get update -y
sudo apt-get install -y build-essential python3-dev unixodbc-dev

# Upgrade pip, setuptools, and wheel
pip install --upgrade pip setuptools wheel

# Install pyodbc directly
pip install pyodbc

echo "Installation complete."
