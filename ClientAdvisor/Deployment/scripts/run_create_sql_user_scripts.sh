#!/bin/bash
echo "Started the script"

# Variables
baseUrl="$1"
keyvaultName="$2"
miClientId="$3"
userName="$4"
requirementFile="requirements.txt"
requirementFileUrl=${baseUrl}"Deployment/scripts/index_scripts/requirements.txt"

echo "Base URL: $baseUrl"
echo "Key Vault Name: $keyvaultName"
echo "Managed Identity Client ID: $miClientId"
echo "User Name: $userName"

# Download the Python script for creating the SQL user
echo "Downloading create_sql_user.py..."
curl --output "create_sql_user.py" ${baseUrl}"Deployment/scripts/index_scripts/create_sql_user.py"
curl --output "create_sql_user_log.py" ${baseUrl}"Deployment/scripts/index_scripts/create_sql_user_log.py"

# Download the requirement file
echo "Downloading requirements.txt..."
curl --output "$requirementFile" "$requirementFileUrl"

echo "Download completed"

# Replace key vault name and other placeholders
sed -i "s/kv_to-be-replaced/${keyvaultName}/g" "create_sql_user.py"
sed -i "s/miClientId_to-be-replaced/${miClientId}/g" "create_sql_user.py"
sed -i "s/user_to-be-replaced/${userName}/g" "create_sql_user.py"
cat create_sql_user.py

# # Create a Python virtual environment
# python3 -m venv /tmp/myenv
# source /tmp/myenv/bin/activate
python -m venv env && source ./env/bin/activate
python -m pip install -U pip wheel setuptools
!apt install unixodbc-dev
!pip install pyodbc
Successfully installed pip 20.1 setuptools-46.1.3 wheel-0.34.2

# Install Python dependencies
echo "Installing Python dependencies from requirements.txt..."
pip install -r requirements.txt
echo "Installing Python dependencies from requirements.txt completed"

# # Install necessary system packages
# sudo apt-get update -y
# sudo apt-get install -y build-essential python3-dev unixodbc unixodbc-dev
# # Install pyodbc using apt
# sudo apt-get install -y python3-pyodbc
# echo "Installation complete."

# # Execute the Python script to create the SQL user
echo "Executing create_sql_user.py..."
python3 create_sql_user.py
echo "Executing create_sql_user.py completed"

