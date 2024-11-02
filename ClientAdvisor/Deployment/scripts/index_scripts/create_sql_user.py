import struct


print(f"+++++++++Logs++++++++++")

try:
    import sys
    from azure.keyvault.secrets import SecretClient  
    from azure.identity import DefaultAzureCredential
    print(f'Inside Creating SQL user...*****************log**********uploaded****************************')
    
    def get_conn():
        credential = DefaultAzureCredential(exclude_interactive_browser_credential=False)
        token_bytes = credential.get_token("https://database.windows.net/.default").token.encode("UTF-16-LE")
        token_struct = struct.pack(f'<I{len(token_bytes)}s', len(token_bytes), token_bytes)
        SQL_COPT_SS_ACCESS_TOKEN = 1256  # This connection option is defined by microsoft in msodbcsql.h
        conn = pyodbc.connect(connection_string, attrs_before={SQL_COPT_SS_ACCESS_TOKEN: token_struct})
        return conn

    # Replace with your Key Vault name and Managed Identity client ID
    key_vault_name = 'kv_to-be-replaced'
    managed_identity_client_id = 'miClientId_to-be-replaced'
    user_name = 'user_to-be-replaced'

    # Function to retrieve secrets from Azure Key Vault
    def get_secrets_from_kv(kv_name, secret_name):
        credential = DefaultAzureCredential()
        secret_client = SecretClient(vault_url=f"https://{kv_name}.vault.azure.net/", credential=credential)
        return secret_client.get_secret(secret_name).value

    import pyodbc
    # Retrieve server and database secrets from Key Vault
    server = get_secrets_from_kv(key_vault_name, "SQLDB-SERVER")
    database = get_secrets_from_kv(key_vault_name, "SQLDB-DATABASE")
    print(f"Server: {server}, Database: {database}")  # Debug info
    # Managed Identity-based authentication
    authentication = 'ActiveDirectoryManagedIdentity'

    # Connection string for SQL Server using Managed Identity
    connection_string = (
        f'Driver={{ODBC Driver 17 for SQL Server}};'
        f'Server=tcp:{server},1433;'
        f'Database={database};'
        f'Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;'
    )
    print(f"conn_string: {connection_string}")
    print(f"Server: {server}, Database: {database}")
    # Establish the connection
    with get_conn() as conn:
        cursor = conn.cursor()
        # Do something with the data
    print("Connection established successfully")  # Debug info

# cursor = conn.cursor()

# # SQL commands to create user and assign roles
# create_user_sql = f"""
# CREATE USER [{user_name}] FROM EXTERNAL PROVIDER;
# ALTER ROLE db_datareader ADD MEMBER [{user_name}];
# ALTER ROLE db_datawriter ADD MEMBER [{user_name}];
# ALTER ROLE db_ddladmin ADD MEMBER [{user_name}];
# """

# # Execute SQL commands
# cursor.execute(create_user_sql)
# conn.commit()

# create_table_sql = f"""
# CREATE TABLE Employees (
#     EmployeeID INT PRIMARY KEY,
#     FirstName VARCHAR(50),
#     LastName VARCHAR(50),
#     BirthDate DATE,
#     HireDate DATE,
#     JobTitle VARCHAR(50)
# );
# """

# # Execute SQL commands
# cursor.execute(create_table_sql)
# conn.commit()

# # Close the connection
# cursor.close()
# conn.close()

except Exception as e:
    print(f"An error occurred: {str(e)}")