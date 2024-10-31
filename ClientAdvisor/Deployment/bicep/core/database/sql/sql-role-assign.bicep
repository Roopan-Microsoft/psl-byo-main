@metadata({
  description: 'Creates a SQL role assignment under an Azure SQL Server.'
})
param sqlServerName string
param sqlDBName string
param principalId string = ''
param location string
param userAssignedIdentityId string

resource deployScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'assignSqlRoles'
  location: location
  kind: 'AzurePowerShell'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityId}': {}
    }
  }
  properties: {
    azPowerShellVersion: '7.0'
    scriptContent: '''
      try {
        Write-Host "Starting script execution..."
        $serverName = "${env:SQL_SERVER}.database.windows.net"
        $databaseName = "${env:SQL_DATABASE}"
        $managedIdentityObjectId = "${env:PRINCIPAL_ID}"

        # Retrieve app service name (optional, can be skipped if permissions issue persists)
        try {
            Write-Host "Retrieving app service name for Object ID: $managedIdentityObjectId"
            $appName = (Get-AzADServicePrincipal -ObjectId $managedIdentityObjectId).DisplayName
            Write-Host "App Service Name: $appName"
        } catch {
            Write-Host "Failed to retrieve app service name, using default or passed-in value."
            $appName = $managedIdentityObjectId  # Or use another variable for the app name
        }

        # Connect to SQL using Managed Identity
        Write-Host "Connecting to SQL Server: $serverName, Database: $databaseName"
        
        $sqlConnection = New-Object System.Data.SqlClient.SqlConnection
        $sqlConnection.ConnectionString = "Server=$serverName;Database=$databaseName;Authentication=Active Directory Managed Identity"
        $sqlConnection.Open()
        Write-Host "Successfully connected to SQL Server."

        # SQL commands to create user and assign roles
        $sqlCommand = $sqlConnection.CreateCommand()

        Write-Host "Creating user [$appName]..."
        $sqlCommand.CommandText = "CREATE USER [$appName] FROM EXTERNAL PROVIDER"
        $sqlCommand.ExecuteNonQuery()
        Write-Host "User [$appName] created successfully."

        Write-Host "Assigning roles to user [$appName]..."
        $sqlCommand.CommandText = "ALTER ROLE db_datareader ADD MEMBER [$appName]"
        $sqlCommand.ExecuteNonQuery()
        Write-Host "User [$appName] added to db_datareader role."

        $sqlCommand.CommandText = "ALTER ROLE db_datawriter ADD MEMBER [$appName]"
        $sqlCommand.ExecuteNonQuery()
        Write-Host "User [$appName] added to db_datawriter role."

        $sqlConnection.Close()
        Write-Host "SQL connection closed."
        Write-Host "Script execution completed successfully."
    } catch {
        Write-Error "An error occurred: $_"
        Write-Host "Failed on line: $($MyInvocation.ScriptLineNumber)"
        exit 1
    }
    '''
    environmentVariables: [
      {
        name: 'SQL_SERVER'
        value: sqlServerName
      }
      {
        name: 'SQL_DATABASE'
        value: sqlDBName
      }
      {
        name: 'PRINCIPAL_ID'
        value: principalId
      }
    ]
    retentionInterval: 'PT1H'
    cleanupPreference: 'OnSuccess'
    forceUpdateTag: '1.0'
  }
}
