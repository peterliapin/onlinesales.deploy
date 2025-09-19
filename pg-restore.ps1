# PowerShell script for PostgreSQL database restore
# Usage: .\pg-restore.ps1 <database_name> <backup_file>

param(
    [Parameter(Mandatory=$true)]
    [string]$DatabaseName,
    
    [Parameter(Mandatory=$true)]
    [string]$BackupFile
)

# Check if backup file exists
if (-not (Test-Path $BackupFile)) {
    Write-Host "Error: Backup file '$BackupFile' not found!" -ForegroundColor Red
    exit 1
}

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

# Set environment variable for PostgreSQL password
$env:PGPASSWORD = $envVars['POSTGRES__PASSWORD']

# Check if the database exists, create if not
Write-Host "Checking if database '$DatabaseName' exists..." -ForegroundColor Blue
$dbExists = & psql -U $envVars['POSTGRES__USERNAME'] -h localhost -p 5432 -tAc "SELECT 1 FROM pg_database WHERE datname='$DatabaseName'"

if ($dbExists -ne "1") {
    Write-Host "Database $DatabaseName does not exist. Creating..." -ForegroundColor Yellow
    & createdb -U $envVars['POSTGRES__USERNAME'] -h localhost -p 5432 $DatabaseName
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to create database '$DatabaseName'" -ForegroundColor Red
        exit $LASTEXITCODE
    }
}

Write-Host "Restoring database from backup file '$BackupFile'..." -ForegroundColor Blue
& pg_restore -U $envVars['POSTGRES__USERNAME'] -d $DatabaseName -h localhost -p 5432 -v -c -O -Fc $BackupFile

if ($LASTEXITCODE -eq 0) {
    Write-Host "Database restore completed successfully!" -ForegroundColor Green
} else {
    Write-Host "Database restore failed with exit code: $LASTEXITCODE" -ForegroundColor Red
    exit $LASTEXITCODE
}