# PowerShell script for PostgreSQL database backup
# Usage: .\pg-backup.ps1 <database_name> [-ExcludeUserTables]
# Options:
#   -ExcludeUserTables    Exclude user-related tables from backup

param(
    [Parameter(Mandatory=$true)]
    [string]$DatabaseName,
    
    [switch]$ExcludeUserTables
)

# Load environment variables from .env file
if (-not (Test-Path ".env")) {
    Write-Host "Error: .env file not found!" -ForegroundColor Red
    Write-Host "Please make sure you're running this script from the docker-compose directory." -ForegroundColor Yellow
    exit 1
}

$envVars = @{}
Get-Content ".env" | Where-Object { $_ -notmatch '^#' -and $_ -ne '' } | ForEach-Object {
    $key, $value = $_ -split '=', 2
    if ($key -and $value) {
        $envVars[$key] = $value
    }
}

$backupName = "${DatabaseName}-backup-$(Get-Date -Format 'yyyy-MM-dd-HH-mm').sql"

# Set environment variable for PostgreSQL password
$env:PGPASSWORD = $envVars['POSTGRES__PASSWORD']

# Execute the backup with conditional exclusions
if ($ExcludeUserTables) {
    Write-Host "Excluding user-related tables from backup..." -ForegroundColor Yellow
    Write-Host "DEBUG: Running pg_dump with user table exclusions" -ForegroundColor Magenta
    
    $excludeArgs = @(
        "--exclude-table=users",
        "--exclude-table=user_claims",
        "--exclude-table=user_logins",
        "--exclude-table=user_roles",
        "--exclude-table=user_tokens",
        "--exclude-table=setting",
        "--exclude-table=roles",
        "--exclude-table=role_claims"
    )
    
    & pg_dump -U $envVars['POSTGRES__USERNAME'] -d $DatabaseName -h localhost -p 5432 -Fc -x @excludeArgs -f $backupName
} else {
    Write-Host "DEBUG: Running pg_dump without exclusions" -ForegroundColor Magenta
    & pg_dump -U $envVars['POSTGRES__USERNAME'] -d $DatabaseName -h localhost -p 5432 -Fc -x -f $backupName
}

if ($LASTEXITCODE -eq 0) {
    Write-Host "Backup completed successfully: $backupName" -ForegroundColor Green
} else {
    Write-Host "Backup failed with exit code: $LASTEXITCODE" -ForegroundColor Red
    exit $LASTEXITCODE
}