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
# Install system dependencies
RUN apk update && \
    apk add --no-cache --virtual .build-deps \
    curl \
    build-base && \
    apk add --no-cache \
    unixodbc-dev \
    && \
    curl -o /etc/apk/keys/microsoft.asc https://packages.microsoft.com/keys/microsoft.asc && \
    curl -o /etc/apk/repositories https://packages.microsoft.com/config/$(. /etc/os-release && echo $ID$VERSION_ID)/prod.list && \
    apk update && \
    apk add msodbcsql17 && \
    apk del .build-deps

# Install Python dependencies from requirements.txt
echo "Installing Python dependencies from requirements.txt..."
pip install -r requirements.txt
echo "Installing Python dependencies from requirements.txt completed"

# Execute the Python script to create the SQL user
echo "Executing create_sql_user.py..."
python3 create_sql_user.py
echo "Executing create_sql_user.py completed"
