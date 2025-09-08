# PowerShell script to generate secure environment variables
# Run this script to create a .env file with secure random passwords

function Generate-SecurePassword {
    param(
        [int]$Length = 32
    )
    
    # Use only alphanumeric characters and safe special characters to avoid Docker Compose issues
    $chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    $password = ""
    
    for ($i = 0; $i -lt $Length; $i++) {
        $password += $chars[(Get-Random -Maximum $chars.Length)]
    }
    
    return $password
}

function Generate-JWTSecret {
    # JWT secrets should be at least 32 characters long
    return Generate-SecurePassword -Length 64
}

function Generate-ComplexPassword {
    param(
        [int]$Length = 12
    )
    if ($Length -lt 6) { throw "Password length must be at least 6." }

    $upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    $lower = 'abcdefghijklmnopqrstuvwxyz'
    $digits = '0123456789'
    $special = '@%!'
    $safe = $upper + $lower + $digits + $special

    # Ensure at least one of each type, using single character selection
    $passwordChars = @()
    $passwordChars += $upper[(Get-Random -Minimum 0 -Maximum $upper.Length)]
    $passwordChars += $lower[(Get-Random -Minimum 0 -Maximum $lower.Length)]
    $passwordChars += $digits[(Get-Random -Minimum 0 -Maximum $digits.Length)]
    $passwordChars += $special[(Get-Random -Minimum 0 -Maximum $special.Length)]

    for ($i = 4; $i -lt $Length; $i++) {
        $passwordChars += $safe[(Get-Random -Minimum 0 -Maximum $safe.Length)]
    }
    # Shuffle the password
    $password = ($passwordChars | Get-Random -Count $passwordChars.Count) -join ''
    Write-Host "DEBUG: Generated password: $password (Length: $($password.Length))" -ForegroundColor Magenta
    return $password
}

# Check if .env.sample exists
if (-not (Test-Path ".env.sample")) {
    Write-Host "Error: .env.sample file not found!" -ForegroundColor Red
    Write-Host "Please make sure you're running this script from the docker-compose directory." -ForegroundColor Yellow
    exit 1
}

Write-Host "Generating secure environment variables..." -ForegroundColor Green
Write-Host "Reading template from .env.sample..." -ForegroundColor Blue

# Read the .env.sample file
$envTemplate = Get-Content ".env.sample" -Raw

# Generate secure passwords
$jwtSecret = Generate-JWTSecret
$adminPassword = Generate-ComplexPassword -Length 12
$adminPassword = $adminPassword.Trim()
if ($adminPassword.Length -ne 12) {
    Write-Host "Error: Generated admin password is not 8 characters!" -ForegroundColor Red
    exit 1
}
Write-Host "DEBUG: Admin password length: $($adminPassword.Length)" -ForegroundColor Magenta
$postgresPassword = Generate-SecurePassword -Length 16
$elasticPassword = Generate-SecurePassword -Length 16

# Display the generated values
Write-Host ""
Write-Host "Generated secure values:" -ForegroundColor Yellow
Write-Host "JWT__SECRET=$jwtSecret" -ForegroundColor Cyan
Write-Host "DEFAULTUSERS__0__PASSWORD=$adminPassword" -ForegroundColor Cyan
Write-Host "POSTGRES__PASSWORD=$postgresPassword" -ForegroundColor Cyan
Write-Host "ELASTIC__PASSWORD=$elasticPassword" -ForegroundColor Cyan

# Replace placeholder values in the template
$envContent = $envTemplate
$envContent = $envContent -replace "your-super-secret-jwt-key-at-least-32-characters-long", $jwtSecret
$envContent = $envContent -replace "your-application-issuer", "leadcms-issuer"
$envContent = $envContent -replace "your-application-audience", "leadcms-audience"
$envContent = $envContent -replace "YourSecurePassword123!", $adminPassword
$envContent = $envContent -replace "YourSecurePostgresPassword123!", $postgresPassword
$envContent = $envContent -replace "YourSecureElasticPassword123!", $elasticPassword

# Check if .env already exists
if (Test-Path ".env") {
    Write-Host ""
    Write-Host "Warning: .env file already exists!" -ForegroundColor Yellow
    $response = Read-Host "Do you want to overwrite it? (y/N)"
    if ($response -ne "y" -and $response -ne "Y") {
        Write-Host "Operation cancelled. Your existing .env file was not modified." -ForegroundColor Green
        exit 0
    }
}

# Create .env file
$envContent | Out-File -FilePath ".env" -Encoding UTF8 -NoNewline
Write-Host ""
Write-Host "Created .env file with secure passwords!" -ForegroundColor Green
Write-Host "Please review and customize the .env file before starting the application." -ForegroundColor Yellow
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Blue
Write-Host "1. Review the generated .env file" -ForegroundColor White
Write-Host "2. Update EMAIL__USERNAME and EMAIL__PASSWORD with your SMTP credentials" -ForegroundColor White
Write-Host "3. Update CORS__ALLOWEDORIGINS if needed" -ForegroundColor White
Write-Host "4. Add any optional API keys (commented in .env.sample)" -ForegroundColor White
Write-Host "5. Run: docker-compose up -d" -ForegroundColor White
