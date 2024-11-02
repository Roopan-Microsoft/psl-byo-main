#!/bin/bash
echo "started the script"

# Variables
baseUrl="$1"
keyvaultName="$2"
requirementFile="requirements.txt"
requirementFileUrl=${baseUrl}"Deployment/scripts/index_scripts/requirements.txt"

echo "Script Started"

# Download the create_index and create table python files
curl --output "create_search_index.py" ${baseUrl}"Deployment/scripts/index_scripts/create_search_index.py"
curl --output "create_sql_tables.py" ${baseUrl}"Deployment/scripts/index_scripts/create_sql_tables.py"

# Install system dependencies for pyodbc
echo "Installing system packages..."
apk add --no-cache --virtual .build-deps \
    build-base \
    unixodbc-dev
#Download the desired package(s)
curl -O https://download.microsoft.com/download/7/6/d/76de322a-d860-4894-9945-f0cc5d6a45f8/msodbcsql18_18.4.1.1-1_amd64.apk
curl -O https://download.microsoft.com/download/7/6/d/76de322a-d860-4894-9945-f0cc5d6a45f8/mssql-tools18_18.4.1.1-1_amd64.apk
#Install the package(s)
apk add --allow-untrusted msodbcsql18_18.4.1.1-1_amd64.apk
apk add --allow-untrusted mssql-tools18_18.4.1.1-1_amd64.apk

# Download the requirement file
curl --output "$requirementFile" "$requirementFileUrl"

echo "Download completed"

#Replace key vault name 
sed -i "s/kv_to-be-replaced/${keyvaultName}/g" "create_search_index.py"
sed -i "s/kv_to-be-replaced/${keyvaultName}/g" "create_sql_tables.py"

pip install -r requirements.txt

python create_search_index.py
python create_sql_tables.py