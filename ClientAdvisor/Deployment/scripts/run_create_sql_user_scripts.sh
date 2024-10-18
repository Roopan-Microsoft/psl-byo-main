#!/bin/bash
echo "Started the script"

# Install required packages (ensure the correct package manager for your environment)
echo "Installing Python and required packages..."
RUN apt-get update -y
RUN apt-get install -y python3 python3-dev g++ unixodbc-dev unixodbc libpq-dev
pip install pyodbc