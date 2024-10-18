#!/bin/bash
set -e  # Exit on error
echo "Started the script"

# Variables
baseUrl="$1"
keyvaultName="$2"
miClientId="$3"
userName="$4"
requirementFile="requirements.txt"
requirementFileUrl="${baseUrl}Deployment/scripts/index_scripts/requirements.txt"

echo "Downloading necessary scripts..."

# Download the create_sql_user Python file
curl --output "create_sql_user.py" "${baseUrl}Deployment/scripts/index_scripts/create_sql_user.py"
if [ $? -ne 0 ]; then
    echo "Error downloading create_sql_user.py from ${baseUrl}."
    exit 1
fi

# Download the requirement file
curl --output "$requirementFile" "$requirementFileUrl"
if [ $? -ne 0 ]; then
    echo "Error downloading requirements.txt from ${baseUrl}."
    exit 1
fi

echo "Download completed"

# Escape special characters in variables for sed
keyvaultName=$(printf '%s\n' "$keyvaultName" | sed 's/[&/\]/\\&/g')
miClientId=$(printf '%s\n' "$miClientId" | sed 's/[&/\]/\\&/g')
userName=$(printf '%s\n' "$userName" | sed 's/[&/\]/\\&/g')

# Replace placeholders in the Python script with actual values
sed -i "s/kv_to-be-replaced/${keyvaultName}/g" "create_sql_user.py"
sed -i "s/miClientId_to-be-replaced/${miClientId}/g" "create_sql_user.py"
sed -i "s/user_to-be-replaced/${userName}/g" "create_sql_user.py"

if [ $? -ne 0 ]; then
    echo "Error replacing placeholders in create_sql_user.py."
    exit 1
fi

echo "Installing necessary dependencies..."

# Install dependencies (apt-get or apk)
if command -v apt-get &> /dev/null; then
    sudo apt-get update
    sudo apt-get install -y python3 python3-dev g++ unixodbc-dev unixodbc libpq-dev curl
elif command -v apk &> /dev/null; then
    apk add --no-cache python3 python3-dev g++ unixodbc-dev unixodbc libpq-dev curl
else
    echo "Unsupported package manager. Please install dependencies manually."
    exit 1
fi

# Install Python dependencies
pip install -r "$requirementFile"

echo "Executing Python script..."
# Execute the Python script
python3 create_sql_user.py

echo "Script completed successfully."
