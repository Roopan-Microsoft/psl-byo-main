# db.py
import os
import struct
import pyodbc
from azure.identity import DefaultAzureCredential
from dotenv import load_dotenv

load_dotenv()

server = os.environ.get("SQLDB_SERVER")
database = os.environ.get("SQLDB_DATABASE")
connection_string = (
    f'Driver={{ODBC Driver 18 for SQL Server}};'
    f'Server=tcp:{server},1433;'
    f'Database={database};'
    f'Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;'
)

def get_connection():
    credential = DefaultAzureCredential(exclude_interactive_browser_credential=False)
    token_bytes = credential.get_token("https://database.windows.net/.default").token.encode("UTF-16-LE")
    token_struct = struct.pack(f'<I{len(token_bytes)}s', len(token_bytes), token_bytes)
    SQL_COPT_SS_ACCESS_TOKEN = 1256  # This connection option is defined by microsoft in msodbcsql.h
    conn = pyodbc.connect(connection_string, attrs_before={SQL_COPT_SS_ACCESS_TOKEN: token_struct})
    return conn 
