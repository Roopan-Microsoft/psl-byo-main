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

# Download the requirement file
echo "Downloading requirements.txt..."
curl --output "$requirementFile" "$requirementFileUrl"

echo "Download completed"

# Replace key vault name and other placeholders
sed -i "s/kv_to-be-replaced/${keyvaultName}/g" "create_sql_user.py"
sed -i "s/miClientId_to-be-replaced/${miClientId}/g" "create_sql_user.py"
sed -i "s/user_to-be-replaced/${userName}/g" "create_sql_user.py"

# Install required packages (ensure the correct package manager for your environment)
echo "Installing Python and required packages..."
apt-get update -y && apt-get install -y python3 python3-dev g++ unixodbc-dev unixodbc libpq-dev
pip install pyodbc

# Install Python dependencies
echo "Installing Python dependencies from requirements.txt..."
pip install -r requirements.txt

# Execute the Python script to create the SQL user
echo "Executing create_sql_user.py..."
python3 create_sql_user.py

# Check for errors during Python script execution
if [ $? -eq 0 ]; then
    echo "SQL user creation script executed successfully!"
else
    echo "Error executing SQL user creation script." >&2
    exit 1
fi
