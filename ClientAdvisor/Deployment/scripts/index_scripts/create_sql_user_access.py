key_vault_name = 'kv_to-be-replaced'
managed_identity_client_id = 'miClientId_to-be-replaced'
user_name = 'user_to-be-replaced'

from azure.keyvault.secrets import SecretClient  
from azure.identity import DefaultAzureCredential
import pymssql 

def get_secrets_from_kv(kv_name, secret_name):
    key_vault_name = kv_name  # Set the name of the Azure Key Vault  
    credential = DefaultAzureCredential()
    secret_client = SecretClient(vault_url=f"https://{key_vault_name}.vault.azure.net/", credential=credential)  # Create a secret client object using the credential and Key Vault name  
    return(secret_client.get_secret(secret_name).value) # Retrieve the secret value  

server = get_secrets_from_kv(key_vault_name,"SQLDB-SERVER")
database = get_secrets_from_kv(key_vault_name,"SQLDB-DATABASE")
username = get_secrets_from_kv(key_vault_name,"SQLDB-USERNAME")
password = get_secrets_from_kv(key_vault_name,"SQLDB-PASSWORD")

conn = pymssql.connect(server, username, password, database)
cursor = conn.cursor()

cursor = conn.cursor()

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