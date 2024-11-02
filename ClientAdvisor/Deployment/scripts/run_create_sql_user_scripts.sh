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

# Install system dependencies for pyodbc
echo "Installing system packages..."
apk add --no-cache --virtual .build-deps \
    build-base \
    unixodbc-dev

#Download the desired package(s)
curl -O https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/msodbcsql17_17.10.5.1-1_amd64.apk
curl -O https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/mssql-tools_17.10.1.1-1_amd64.apk

#Install the package(s)
apk add --allow-untrusted msodbcsql17_17.10.5.1-1_amd64.apk
apk add --allow-untrusted mssql-tools_17.10.1.1-1_amd64.apk

# Install Python dependencies from requirements.txt
echo "Installing Python dependencies from requirements.txt..."
pip install -r requirements.txt
echo "Installing Python dependencies from requirements.txt completed"

# Execute the Python script to create the SQL user
echo "Executing create_sql_user.py..."
python3 create_sql_user.py
echo "Executing create_sql_user.py completed"
