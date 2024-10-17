import pyodbc
from azure.keyvault.secrets import SecretClient  
from azure.identity import DefaultAzureCredential

# Replace with your Key Vault name and Managed Identity client ID
key_vault_name = 'kv_to-be-replaced'
managed_identity_client_id = 'miClientId_to-be-replaced'
user_name = 'user_to-be-replaced'

# Function to retrieve secrets from Azure Key Vault
def get_secrets_from_kv(kv_name, secret_name):
    credential = DefaultAzureCredential()
    secret_client = SecretClient(vault_url=f"https://{kv_name}.vault.azure.net/", credential=credential)
    return secret_client.get_secret(secret_name).value

# Retrieve server and database secrets from Key Vault
server = get_secrets_from_kv(key_vault_name, "SQLDB-SERVER")
database = get_secrets_from_kv(key_vault_name, "SQLDB-DATABASE")

# Managed Identity-based authentication
authentication = 'ActiveDirectoryMsi'

# Connection string for SQL Server using Managed Identity
conn_string = (
    f'Driver={{ODBC Driver 18 for SQL Server}};'
    f'Server={server},1433;'
    f'Database={database};'
    f'UID={managed_identity_client_id};'  # Use managed identity client ID for user
    f'Authentication={authentication};'
    f'Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;'
)

# Establish the connection
conn = pyodbc.connect(conn_string)
cursor = conn.cursor()

# SQL commands to create user and assign roles
user_email = 'user@domain.com'  # Replace with the actual user email
create_user_sql = f"""
CREATE USER [{user_name}] FROM EXTERNAL PROVIDER;
ALTER ROLE db_datareader ADD MEMBER [{user_name}];
ALTER ROLE db_datawriter ADD MEMBER [{user_name}];
ALTER ROLE db_ddladmin ADD MEMBER [{user_name}];
"""

# Execute SQL commands
cursor.execute(create_user_sql)
conn.commit()

# Close the connection
cursor.close()
conn.close()

print(f"User [{user_email}] created and roles assigned successfully.")
