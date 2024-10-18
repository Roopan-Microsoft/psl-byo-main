#!/bin/bash
echo "Started the script"

# Update package list and install required packages
echo "Updating package list and installing Python and required packages..."
sudo apt-get update -y
sudo apt-get install -y build-essential python3-dev unixodbc-dev libpq-dev

# Upgrade pip, setuptools, and wheel
pip3 install --upgrade pip setuptools wheel

# Create a virtual environment
pip3 install virtualenv
virtualenv venv

# Activate the virtual environment
source venv/bin/activate

# Install pyodbc using pip
pip install pyodbc

echo "Installation complete."
