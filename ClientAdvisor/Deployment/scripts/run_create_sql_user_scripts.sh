#!/bin/bash
echo "Started the script"

# Create a Python virtual environment in /tmp
python3 -m venv /tmp/myenv
source /tmp/myenv/bin/activate

# Install necessary system packages
sudo apt-get update -y
sudo apt-get install -y build-essential python3-dev unixodbc unixodbc-dev

# Upgrade pip, setuptools, and wheel
pip install --upgrade pip setuptools wheel

# Install pyodbc and prefer binary wheels
pip install pyodbc --prefer-binary

echo "Installation complete."
