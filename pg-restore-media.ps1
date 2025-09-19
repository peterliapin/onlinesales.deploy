# PowerShell script for PostgreSQL media table restore
# Usage: .\pg-restore-media.ps1 <database_name> <backup_file>

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

Write-Host "Restoring media table from backup file '$BackupFile' to database '$DatabaseName'..." -ForegroundColor Blue
& pg_restore -U $envVars['POSTGRES__USERNAME'] -d $DatabaseName -h localhost -p 5432 -v -c -O -Fc -t media $BackupFile

if ($LASTEXITCODE -eq 0) {
    Write-Host "Media table restore completed successfully!" -ForegroundColor Green
} else {
    Write-Host "Media table restore failed with exit code: $LASTEXITCODE" -ForegroundColor Red
    exit $LASTEXITCODE
}