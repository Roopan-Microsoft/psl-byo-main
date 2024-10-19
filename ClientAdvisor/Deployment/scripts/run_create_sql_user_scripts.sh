#!/bin/bash
echo "Started the script"

# Set up a Python virtual environment
if ! python3 -m venv myenv; then
    echo "Error: Failed to create Python virtual environment."
    exit 1
fi
source myenv/bin/activate

# Make sure all dependencies are installed
sudo apt-get update -y
sudo apt-get install -y build-essential python3-dev unixodbc-dev

# Upgrade pip, setuptools, and wheel
pip3 install --upgrade pip setuptools wheel

# Install pyodbc directly
pip3 install pyodbc


echo "Installation complete."
