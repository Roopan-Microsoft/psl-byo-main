#!/bin/bash
echo "Started the script"

# Update package list and install required packages
echo "Updating package list and installing Python and required packages..."
sudo apt-get update -y
sudo apt-get install -y python3 python3-dev g++ build-essential unixodbc-dev libpq-dev

# Install pyodbc using pip
pip3 install --upgrade pip setuptools wheel
pip3 install pyodbc

echo "Installation complete."
