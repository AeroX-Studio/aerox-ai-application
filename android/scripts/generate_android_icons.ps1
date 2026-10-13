<#
.SYNOPSIS
    Generates high-definition legacy and adaptive launcher icons for AeroX AI on Android.
#>

Add-Type -AssemblyName System.Drawing

$SourcePath = [System.IO.Path]::GetFullPath("$PSScriptRoot\..\..\assets\images\logo_512.png")
$ResDir = [System.IO.Path]::GetFullPath("$PSScriptRoot\..\app\src\main\res")

if (-not (Test-Path $SourcePath)) {
    Write-Error "Source image not found: $SourcePath"
    exit 1
}

$sourceImg = [System.Drawing.Image]::FromFile($SourcePath)

# 1. Generate Legacy Full Launcher Icons
$densities = @(
    @{ Name = "mipmap-mdpi"; Size = 48; ForeSize = 108; InnerSize = 72 },
    @{ Name = "mipmap-hdpi"; Size = 72; ForeSize = 162; InnerSize = 108 },
    @{ Name = "mipmap-xhdpi"; Size = 96; ForeSize = 216; InnerSize = 144 },
    @{ Name = "mipmap-xxhdpi"; Size = 144; ForeSize = 324; InnerSize = 216 },
    @{ Name = "mipmap-xxxhdpi"; Size = 192; ForeSize = 432; InnerSize = 288 }
)

function Resize-And-Save($src, $destPath, $w, $h) {
    $bmp = New-Object System.Drawing.Bitmap($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $g.Clear([System.Drawing.Color]::Transparent)
    $g.DrawImage($src, 0, 0, $w, $h)
    $g.Dispose()

    $bmp.Save($destPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
}

function Generate-Foreground($src, $destPath, $canvasSize, $innerSize) {
    $bmp = New-Object System.Drawing.Bitmap($canvasSize, $canvasSize, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $g.Clear([System.Drawing.Color]::Transparent)

    $offset = [int](($canvasSize - $innerSize) / 2)
    $g.DrawImage($src, $offset, $offset, $innerSize, $innerSize)
    $g.Dispose()

    $bmp.Save($destPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
}

foreach ($d in $densities) {
    $folder = Join-Path $ResDir $d.Name
    if (-not (Test-Path $folder)) {
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
    }

    # Legacy icon
    $legacyPath = Join-Path $folder "ic_launcher.png"
    Resize-And-Save $sourceImg $legacyPath $d.Size $d.Size
    Write-Host "Created $legacyPath ($($d.Size)x$($d.Size))" -ForegroundColor Green

    # Adaptive foreground
    $forePath = Join-Path $folder "ic_launcher_foreground.png"
    Generate-Foreground $sourceImg $forePath $d.ForeSize $d.InnerSize
    Write-Host "Created $forePath ($($d.ForeSize)x$($d.ForeSize))" -ForegroundColor Green
}

$sourceImg.Dispose()

# 2. Adaptive Icon XMLs
$anyDpiFolder = Join-Path $ResDir "mipmap-anydpi-v26"
if (-not (Test-Path $anyDpiFolder)) {
    New-Item -ItemType Directory -Path $anyDpiFolder -Force | Out-Null
}

$adaptiveXml = @"
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
</adaptive-icon>
"@
Set-Content -Path (Join-Path $anyDpiFolder "ic_launcher.xml") -Value $adaptiveXml -Encoding utf8

$drawFolder = Join-Path $ResDir "drawable"
if (-not (Test-Path $drawFolder)) {
    New-Item -ItemType Directory -Path $drawFolder -Force | Out-Null
}

$backgroundXml = @"
<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android"
    android:shape="rectangle">
    <solid android:color="#0B0F17" />
</shape>
"@
Set-Content -Path (Join-Path $drawFolder "ic_launcher_background.xml") -Value $backgroundXml -Encoding utf8

Write-Host "All official AeroX AI Android launcher icons generated successfully!" -ForegroundColor Cyan
