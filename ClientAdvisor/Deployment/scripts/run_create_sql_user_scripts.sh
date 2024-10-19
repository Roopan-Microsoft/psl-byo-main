#!/bin/bash
echo "Started the script"

# Create a Python virtual environment in /tmp
python3 -m venv /tmp/myenv
source /tmp/myenv/bin/activate

# Install necessary system packages
sudo apt-get update -y
sudo apt-get install -y build-essential python3-dev unixodbc unixodbc-dev

# Install pyodbc using apt
sudo apt-get install -y python3-pyodbc

echo "Installation complete."
