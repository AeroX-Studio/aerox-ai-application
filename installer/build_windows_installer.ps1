<#
.SYNOPSIS
    Builds and packages AeroX AI into a production-ready Windows installer.

.DESCRIPTION
    Compiles the Flutter Windows release bundle with official AeroX Studio
    metadata, supports code signing via SignTool when a certificate is provided,
    and produces an enterprise-grade Inno Setup installer/uninstaller package.

.PARAMETER CertificatePath
    Optional path to a valid code-signing PFX/P12 file.

.PARAMETER CertificatePassword
    Optional password for the code-signing certificate.

.PARAMETER CertThumbprint
    Optional certificate thumbprint from the local Windows Certificate Store.

.PARAMETER TimestampServer
    RFC 3161 Timestamp Server (default: http://timestamp.digicert.com).

.PARAMETER SkipFlutterBuild
    Skips the 'flutter build windows --release' step if already compiled.

.EXAMPLE
    .\build_windows_installer.ps1
    .\build_windows_installer.ps1 -CertificatePath "C:\certs\aerox_cert.pfx" -CertificatePassword "secret"
    .\build_windows_installer.ps1 -SkipFlutterBuild
#>

[CmdletBinding()]
param(
    [string]$CertificatePath = $env:AEROX_CERT_PATH,
    [string]$CertificatePassword = $env:AEROX_CERT_PASSWORD,
    [string]$CertThumbprint = $env:AEROX_CERT_THUMBPRINT,
    [string]$TimestampServer = "http://timestamp.digicert.com",
    [switch]$SkipFlutterBuild
)

$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "     AeroX AI Windows Distribution Packaging System       " -ForegroundColor Cyan
Write-Host "               Publisher: AeroX Studio                    " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Resolve Directories
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$projectDir = Resolve-Path (Join-Path $scriptDir "..")
$pubspecPath = Join-Path $projectDir "pubspec.yaml"
$issPath = Join-Path $scriptDir "aerox_ai_setup.iss"
$releaseDir = Join-Path $projectDir "build\windows\x64\runner\Release"
$installerOutputDir = Join-Path $projectDir "build\installer"

if (-not (Test-Path $pubspecPath)) {
    throw "Cannot locate pubspec.yaml at $pubspecPath"
}
if (-not (Test-Path $issPath)) {
    throw "Cannot locate Inno Setup script at $issPath"
}

# 2. Extract Version from pubspec.yaml
$pubspecContent = Get-Content $pubspecPath -Raw
$versionMatch = [regex]::Match($pubspecContent, 'version:\s*([0-9]+\.[0-9]+\.[0-9]+)(?:\+([0-9]+))?')
if ($versionMatch.Success) {
    $appVersion = $versionMatch.Groups[1].Value
    $buildNumber = if ($versionMatch.Groups[2].Success) { $versionMatch.Groups[2].Value } else { "1" }
    $appVersionBuild = "$appVersion.$buildNumber"
} else {
    $appVersion = "1.0.0"
    $appVersionBuild = "1.0.0.1"
}

Write-Host "• Application Name:    AeroX AI" -ForegroundColor White
Write-Host "• Official Publisher:  AeroX Studio" -ForegroundColor White
Write-Host "• Version:             $appVersion (Build $appVersionBuild)" -ForegroundColor White
Write-Host "• Project Directory:   $projectDir" -ForegroundColor White

# 3. Locate Inno Setup Compiler (ISCC.exe)
$isccCandidates = @(
    "C:\Users\Joy\AppData\Local\Programs\Inno Setup 6\ISCC.exe",
    "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe",
    "C:\Program Files (x86)\Inno Setup 6\ISCC.exe",
    "C:\Program Files\Inno Setup 6\ISCC.exe"
)

$isccPath = $null
foreach ($cand in $isccCandidates) {
    if (Test-Path $cand) {
        $isccPath = $cand
        break
    }
}

if (-not $isccPath) {
    $cmd = Get-Command iscc.exe -ErrorAction SilentlyContinue
    if ($cmd) {
        $isccPath = $cmd.Source
    }
}

if (-not $isccPath) {
    throw "Inno Setup Compiler (ISCC.exe) not found. Please install Inno Setup 6."
}
Write-Host "• Inno Setup Compiler: $isccPath" -ForegroundColor Green

# 4. Locate SignTool.exe (for optional digital signatures)
$signtoolCandidates = @(
    "C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x64\signtool.exe",
    "C:\Program Files (x86)\Windows Kits\10\bin\x64\signtool.exe",
    "C:\Program Files (x86)\Windows Kits\10\App Certification Kit\signtool.exe"
)

$signtoolPath = $null
foreach ($cand in $signtoolCandidates) {
    if (Test-Path $cand) {
        $signtoolPath = $cand
        break
    }
}
if (-not $signtoolPath) {
    $cmd = Get-Command signtool.exe -ErrorAction SilentlyContinue
    if ($cmd) {
        $signtoolPath = $cmd.Source
    }
}

# 5. Build Flutter Windows Application
if (-not $SkipFlutterBuild) {
    Write-Host "`n>>> [1/4] Compiling Flutter Windows Release Bundle..." -ForegroundColor Yellow
    Push-Location $projectDir
    try {
        & flutter build windows --release
        if ($LASTEXITCODE -ne 0) {
            throw "Flutter build failed with exit code $LASTEXITCODE"
        }
    } finally {
        Pop-Location
    }
} else {
    Write-Host "`n>>> [1/4] Skipping Flutter build (--SkipFlutterBuild specified)..." -ForegroundColor DarkGray
}

$mainExe = Join-Path $releaseDir "aeroxai.exe"
if (-not (Test-Path $mainExe)) {
    throw "Compiled binary not found at $mainExe. Run without -SkipFlutterBuild."
}

# 6. Verify Executable Metadata
Write-Host "`n>>> [2/4] Verifying Binary Metadata and Application Identity..." -ForegroundColor Yellow
$item = Get-Item $mainExe
$info = $item.VersionInfo

Write-Host "  File:             $($item.Name)" -ForegroundColor White
Write-Host "  Company / Org:    $($info.CompanyName)" -ForegroundColor White
Write-Host "  Product Name:     $($info.ProductName)" -ForegroundColor White
Write-Host "  File Description: $($info.FileDescription)" -ForegroundColor White
Write-Host "  Legal Copyright:  $($info.LegalCopyright)" -ForegroundColor White
Write-Host "  Product Version:  $($info.ProductVersion)" -ForegroundColor White

if ($info.CompanyName -ne "AeroX Studio") {
    Write-Warning "CompanyName is '$($info.CompanyName)'. Expected 'AeroX Studio'."
}
if ($info.ProductName -ne "AeroX AI") {
    Write-Warning "ProductName is '$($info.ProductName)'. Expected 'AeroX AI'."
}

# 7. Code Signing (Optional legitimate certificate handling)
Write-Host "`n>>> [3/4] Checking Code Signing Pipeline..." -ForegroundColor Yellow
$canSign = $false
$signArgsBase = @()

if ($signtoolPath -and (Test-Path $signtoolPath)) {
    if ($CertificatePath -and (Test-Path $CertificatePath)) {
        $canSign = $true
        $signArgsBase = @("sign", "/fd", "SHA256", "/tr", $TimestampServer, "/td", "SHA256", "/f", $CertificatePath)
        if ($CertificatePassword) {
            $signArgsBase += @("/p", $CertificatePassword)
        }
        Write-Host "  [OK] SignTool found. Code signing configured using file: $CertificatePath" -ForegroundColor Green
    } elseif ($CertThumbprint) {
        $canSign = $true
        $signArgsBase = @("sign", "/fd", "SHA256", "/tr", $TimestampServer, "/td", "SHA256", "/sha1", $CertThumbprint)
        Write-Host "  [OK] SignTool found. Code signing configured using certificate store thumbprint: $CertThumbprint" -ForegroundColor Green
    } else {
        Write-Host "  [Notice] No code-signing certificate provided. Application metadata is verified as AeroX Studio." -ForegroundColor Cyan
        Write-Host "  To sign binaries, pass -CertificatePath <pfx> or set `$env:AEROX_CERT_PATH." -ForegroundColor DarkGray
    }
} else {
    Write-Host "  [Notice] SignTool not detected on PATH or Windows Kits. Skipping digital signature." -ForegroundColor DarkGray
}

if ($canSign) {
    Write-Host "  Signing main executable: $mainExe" -ForegroundColor Cyan
    & $signtoolPath @signArgsBase $mainExe
}

# 8. Compile Inno Setup Installer
Write-Host "`n>>> [4/4] Generating AeroX AI Windows Installer Package..." -ForegroundColor Yellow

if (-not (Test-Path $installerOutputDir)) {
    New-Item -ItemType Directory -Path $installerOutputDir -Force | Out-Null
}

$isccArgs = @(
    "/DMyAppVersion=$appVersion",
    "/DMyAppVersionBuild=$appVersionBuild",
    "/DSourceDir=$releaseDir",
    "/DOutputDir=$installerOutputDir",
    "/Qp"
)

if ($canSign) {
    $quotedSignCmd = "`"$signtoolPath`" $($signArgsBase -join ' ') `$f"
    $isccArgs += "/Ssigntool=$quotedSignCmd"
    $isccArgs += "/DUseSignTool=1"
}

& $isccPath @isccArgs $issPath
if ($LASTEXITCODE -ne 0) {
    throw "Inno Setup compilation failed with exit code $LASTEXITCODE"
}

$installerExe = Join-Path $installerOutputDir "AeroX_AI_Setup_x64.exe"
if (-not (Test-Path $installerExe)) {
    throw "Installer executable was not found at $installerExe"
}

# If standalone installer was built without Inno Setup SignTool hook, sign installer directly
if ($canSign) {
    Write-Host "  Signing final installer: $installerExe" -ForegroundColor Cyan
    & $signtoolPath @signArgsBase $installerExe
}

$installerItem = Get-Item $installerExe
$installerInfo = $installerItem.VersionInfo

Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host "       AeroX AI Windows Installer Build Complete!         " -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "• Installer File:    $($installerItem.FullName)" -ForegroundColor White
Write-Host "• Package Size:      $([math]::Round($installerItem.Length / 1MB, 2)) MB" -ForegroundColor White
Write-Host "• Publisher:         $($installerInfo.CompanyName)" -ForegroundColor White
Write-Host "• Product Name:      $($installerInfo.ProductName)" -ForegroundColor White
Write-Host "• Product Version:   $($installerInfo.ProductVersion)" -ForegroundColor White
Write-Host "• Copyright:         $($installerInfo.LegalCopyright)" -ForegroundColor White
Write-Host "• Description:       $($installerInfo.FileDescription)" -ForegroundColor White
Write-Host "==========================================================" -ForegroundColor Green
