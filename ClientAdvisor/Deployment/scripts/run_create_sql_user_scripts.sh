#!/bin/bash
echo "started the script"

# Variables
baseUrl="$1"
keyvaultName="$2"
miClientId="$3"
userName="$4"
requirementFile="requirements.txt"
requirementFileUrl=${baseUrl}"Deployment/scripts/index_scripts/requirements.txt"

echo "Script Started"

# Download the create_index and create table python files
curl --output "create_sql_user.py" ${baseUrl}"Deployment/scripts/index_scripts/create_sql_user.py"

# Download the requirement file
curl --output "$requirementFile" "$requirementFileUrl"

echo "Download completed"

# Replace key vault name and other placeholders
sed -i "s/kv_to-be-replaced/${safeKeyvaultName}/g" "create_sql_user.py"
sed -i "s/miClientId_to-be-replaced/${safeMiClientId}/g" "create_sql_user.py"
sed -i "s/user_to-be-replaced/${safeUserName}/g" "create_sql_user.py"

# apt-get update
# apt-get install python3 python3-dev g++ unixodbc-dev unixodbc libpq-dev
# apk add python3 python3-dev g++ unixodbc-dev unixodbc libpq-dev
 
# # RUN apt-get install python3 python3-dev g++ unixodbc-dev unixodbc libpq-dev
# pip install pyodbc

# Install dependencies
pip install -r requirements.txt

# Execute Python script
python create_sql_user.py