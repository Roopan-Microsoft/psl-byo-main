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

# Install ODBC Driver for SQL Server
if command -v apt-get &> /dev/null; then
    echo "Installing ODBC Driver 18 for SQL Server..."
    sudo su -c "apt-get update && \
                 apt-get install -y curl && \
                 curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
                 curl https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/prod.list > /etc/apt/sources.list.d/mssql-release.list && \
                 apt-get update && \
                 ACCEPT_EULA=Y apt-get install -y msodbcsql18"
elif command -v yum &> /dev/null; then
    echo "Installing ODBC Driver 18 for SQL Server..."
    sudo su -c "yum update -y && \
                 curl https://packages.microsoft.com/keys/microsoft.asc | rpm --import - && \
                 curl https://packages.microsoft.com/config/rhel/$(cat /etc/os-release | grep VERSION_ID | cut -d '=' -f 2)/prod.repo > /etc/yum.repos.d/mssql-release.repo && \
                 ACCEPT_EULA=Y yum install -y msodbcsql18"
else
    echo "Unsupported package manager. Please install ODBC Driver manually."
    exit 1
fi

# Set up a Python virtual environment
python3 -m venv myenv
source myenv/bin/activate

# Install Python dependencies
pip install --upgrade pip  # Upgrade pip to the latest version
pip install -r "$requirementFile"

echo "Executing Python script..."
# Execute the Python script
#python3 create_sql_user.py

echo "Script completed successfully."
