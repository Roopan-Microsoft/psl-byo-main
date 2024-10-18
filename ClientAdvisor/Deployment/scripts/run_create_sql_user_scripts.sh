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

#Replace key vault name 
sed -i "s/kv_to-be-replaced/${keyvaultName}/g" "create_sql_user.py"
sed -i "s/miClientId_to-be-replaced/${miClientId}/g" "create_sql_user.py"
sed -i "s/user_to-be-replaced/${userName}/g" "create_sql_user.py"

sudo apt-get update && sudo apt-get install -y unixodbc-dev g++
pip install --upgrade pip
pip install -r requirements.txt

python create_sql_user.py