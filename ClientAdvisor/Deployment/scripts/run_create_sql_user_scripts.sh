#!/bin/bash
set -e  # Exit on error
echo "Started the script"

# Function to handle errors
error_handler() {
    local exit_code="$?"
    local line_number="$1"
    echo "Error: An error occurred on line $line_number. Exit code: $exit_code."
    exit "$exit_code"
}

# Trap any errors and call the error_handler function, passing the line number
trap 'error_handler $LINENO' ERR

# Variables
baseUrl="$1"
keyvaultName="$2"
miClientId="$3"
userName="$4"
requirementFile="requirements.txt"
requirementFileUrl="${baseUrl}Deployment/scripts/index_scripts/requirements.txt"

echo "Downloading necessary scripts..."

# Download the create_sql_user Python file
if ! curl --output "create_sql_user.py" "${baseUrl}Deployment/scripts/index_scripts/create_sql_user.py"; then
    echo "Error: Failed to download create_sql_user.py from ${baseUrl}."
    exit 1
fi
echo "Downloaded create_sql_user.py"

# Download the requirement file
if ! curl --output "$requirementFile" "$requirementFileUrl"; then
    echo "Error: Failed to download requirements.txt from ${requirementFileUrl}."
    exit 1
fi
echo "Downloaded requirements.txt"

echo "Download completed"

# Escape special characters in variables for sed
keyvaultName=$(printf '%s\n' "$keyvaultName" | sed 's/[&/\]/\\&/g')
miClientId=$(printf '%s\n' "$miClientId" | sed 's/[&/\]/\\&/g')
userName=$(printf '%s\n' "$userName" | sed 's/[&/\]/\\&/g')

# Replace placeholders in the Python script with actual values
if ! sed -i "s/kv_to-be-replaced/${keyvaultName}/g" "create_sql_user.py"; then
    echo "Error: Failed to replace 'kv_to-be-replaced' in create_sql_user.py."
    exit 1
fi

if ! sed -i "s/miClientId_to-be-replaced/${miClientId}/g" "create_sql_user.py"; then
    echo "Error: Failed to replace 'miClientId_to-be-replaced' in create_sql_user.py."
    exit 1
fi

if ! sed -i "s/user_to-be-replaced/${userName}/g" "create_sql_user.py"; then
    echo "Error: Failed to replace 'user_to-be-replaced' in create_sql_user.py."
    exit 1
fi
echo "Replaced placeholders in create_sql_user.py"

echo "Installing necessary dependencies..."

# Install ODBC Driver for SQL Server
if command -v apt-get &> /dev/null; then
    echo "Installing ODBC Driver 18 for SQL Server..."
    if ! output=$(sudo su -c "apt-get update && \
                     apt-get install -y curl && \
                     curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
                     curl https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/prod.list > /etc/apt/sources.list.d/mssql-release.list && \
                     apt-get update && \
                     ACCEPT_EULA=Y apt-get install -y msodbcsql18" 2>&1); then
        echo "Error: Failed to install ODBC Driver 18 for SQL Server. Details: $output"
        exit 1
    fi
    echo "ODBC Driver installed."
elif command -v yum &> /dev/null; then
    echo "Installing ODBC Driver 18 for SQL Server..."
    if ! output=$(sudo su -c "yum update -y && \
                     curl https://packages.microsoft.com/keys/microsoft.asc | rpm --import - && \
                     curl https://packages.microsoft.com/config/rhel/$(cat /etc/os-release | grep VERSION_ID | cut -d '=' -f 2)/prod.repo > /etc/yum.repos.d/mssql-release.repo && \
                     ACCEPT_EULA=Y yum install -y msodbcsql18" 2>&1); then
        echo "Error: Failed to install ODBC Driver 18 for SQL Server. Details: $output"
        exit 1
    fi
    echo "ODBC Driver installed."
else
    echo "Error: Unsupported package manager. Please install ODBC Driver manually."
    exit 1
fi

# Set up a Python virtual environment
if ! output=$(python3 -m venv myenv 2>&1); then
    echo "Error: Failed to create Python virtual environment. Details: $output"
    exit 1
fi
source myenv/bin/activate

# Install Python dependencies
if ! output=$(pip install --upgrade pip 2>&1); then
    echo "Error: Failed to upgrade pip. Details: $output"
    exit 1
fi

if ! output=$(pip install -r "$requirementFile" 2>&1); then
    echo "Error: Failed to install Python dependencies from $requirementFile. Details: $output"
    exit 1
fi
echo "Python dependencies installed."

echo "Executing Python script..."
# Execute the Python script
if ! output=$(python3 create_sql_user.py 2>&1); then
    echo "Error: Execution of create_sql_user.py failed. Details: $output"
    exit 1
fi

echo "Script completed successfully."
