<#
.SYNOPSIS
    Generates a production release keystore and key.properties for AeroX AI (AeroX Studio).
.DESCRIPTION
    Creates an industry-standard RSA 4096-bit signing key valid for 10,000 days,
    matching Google Play and Android security requirements.
#>

param(
    [string]$KeystorePath = "$PSScriptRoot\..\aerox-release.keystore",
    [string]$KeyPropertiesPath = "$PSScriptRoot\..\key.properties",
    [string]$Alias = "aerox-release",
    [string]$Password = ""
)

$ErrorActionPreference = "Stop"

Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "   AeroX AI - Production Keystore Generator     " -ForegroundColor Cyan
Write-Host "   Publisher Identity: AeroX Studio             " -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

# Locate keytool
$KeytoolPath = "keytool"
$DefaultJbrKeytool = "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe"

if (Test-Path $DefaultJbrKeytool) {
    $KeytoolPath = $DefaultJbrKeytool
} elseif (-not (Get-Command keytool -ErrorAction SilentlyContinue)) {
    Write-Error "keytool could not be found. Please ensure Java/Android Studio is installed."
    exit 1
}

$ResolvedKeystorePath = [System.IO.Path]::GetFullPath($KeystorePath)
$ResolvedPropertiesPath = [System.IO.Path]::GetFullPath($KeyPropertiesPath)

if (Test-Path $ResolvedKeystorePath) {
    Write-Host "[INFO] Keystore already exists at: $ResolvedKeystorePath" -ForegroundColor Yellow
} else {
    if ([string]::IsNullOrWhiteSpace($Password)) {
        # Generate a strong 32-character random cryptographic password
        $bytes = New-Object byte[] 24
        [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
        $Password = [System.Convert]::ToBase64String($bytes).Replace('+', 'X').Replace('/', 'Z').Replace('=', '9')
    }

    $dname = "CN=AeroX AI, OU=Mobile Engineering, O=AeroX Studio, L=San Francisco, ST=California, C=US"

    Write-Host "[INFO] Generating RSA 4096-bit production keystore..." -ForegroundColor Green
    Write-Host "  Destination : $ResolvedKeystorePath"
    Write-Host "  Alias       : $Alias"
    Write-Host "  Validity    : 10000 days"
    Write-Host "  DName       : $dname"

    & $KeytoolPath -genkeypair `
        -v `
        -keystore "$ResolvedKeystorePath" `
        -alias "$Alias" `
        -keyalg RSA `
        -keysize 4096 `
        -sigalg SHA256withRSA `
        -validity 10000 `
        -storetype PKCS12 `
        -storepass "$Password" `
        -keypass "$Password" `
        -dname "$dname"

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to generate keystore."
        exit $LASTEXITCODE
    }

    Write-Host "[SUCCESS] Keystore generated successfully!" -ForegroundColor Green
}

# Write key.properties if not present
if (-not (Test-Path $ResolvedPropertiesPath)) {
    Write-Host "[INFO] Writing key.properties..." -ForegroundColor Green
    $keystoreFileName = [System.IO.Path]::GetFileName($ResolvedKeystorePath)
    $propertiesContent = @"
storePassword=$Password
keyPassword=$Password
keyAlias=$Alias
storeFile=../$keystoreFileName
"@
    Set-Content -Path $ResolvedPropertiesPath -Value $propertiesContent -Encoding utf8
    Write-Host "[SUCCESS] Created key.properties at: $ResolvedPropertiesPath" -ForegroundColor Green
} else {
    Write-Host "[INFO] key.properties already exists at: $ResolvedPropertiesPath" -ForegroundColor Yellow
}

# Display Certificate Fingerprints
Write-Host ""
Write-Host "---------------- Certificate Fingerprints ----------------" -ForegroundColor Cyan
& $KeytoolPath -list -v -keystore "$ResolvedKeystorePath" -alias "$Alias" -storepass "$Password" | Select-String -Pattern "Certificate fingerprints:", "SHA1:", "SHA256:", "Owner:"
Write-Host "----------------------------------------------------------" -ForegroundColor Cyan
