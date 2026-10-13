# AeroX AI Windows Distribution System

Official Windows distribution and installation packaging system for **AeroX AI**, published under the identity **AeroX Studio**.

---

## 1. Package Identity & Metadata Consistency

All Windows binaries, shortcuts, uninstaller entries, and Windows Apps & Features registry keys are unified under:

| Field | Value |
|---|---|
| **Product Name** | `AeroX AI` |
| **Publisher / Company** | `AeroX Studio` |
| **File Description** | `AeroX AI Desktop Client` |
| **Product Version** | `1.0.0` (synchronous with `pubspec.yaml`) |
| **Copyright** | `Copyright (C) 2026 AeroX Studio. All rights reserved.` |
| **Original Filename** | `aeroxai.exe` |
| **Default Install Directory** | `%LOCALAPPDATA%\Programs\AeroX Studio\AeroX AI` (User) / `Program Files\AeroX Studio\AeroX AI` (Machine) |
| **Start Menu Folder** | `AeroX Studio\AeroX AI` |

---

## 2. Prerequisites

- **Flutter SDK**: 3.47+ with Windows desktop support (`flutter doctor`)
- **Visual Studio 2022+**: With *Desktop development with C++*
- **Inno Setup 6**: (`ISCC.exe`) installed at standard paths or on system `PATH`
- **Windows SDK**: (`signtool.exe`) for digital signing (optional)

---

## 3. How to Build the Windows Installer

### Standard Release Build (Unsigned)
From PowerShell inside `Application/aeroxai`:
```powershell
.\installer\build_windows_installer.ps1
```

### Fast Packaging (Skip Flutter Compilation if Binaries Exist)
```powershell
.\installer\build_windows_installer.ps1 -SkipFlutterBuild
```

### Production Release with Digital Code Signing
Provide a certificate PFX file or specify a certificate thumbprint from the local Windows Certificate Store:
```powershell
# Using a PFX file
.\installer\build_windows_installer.ps1 -CertificatePath "C:\certs\AeroX_Studio_CodeSigning.pfx" -CertificatePassword "YourPassword"

# Or using Environment Variables
$env:AEROX_CERT_PATH = "C:\certs\AeroX_Studio_CodeSigning.pfx"
$env:AEROX_CERT_PASSWORD = "YourPassword"
.\installer\build_windows_installer.ps1

# Using Windows Certificate Store Thumbprint
.\installer\build_windows_installer.ps1 -CertThumbprint "A1B2C3D4E5F6..."
```

---

## 4. Output Artifacts

The compiled installer is written to:
```
Application/aeroxai/build/installer/AeroX_AI_Setup_x64.exe
```

### Features Built into the Installer
1. **Dual Privilege Mode**: Supports clean per-user installation without unnecessary UAC prompts, while supporting administrator multi-user installations.
2. **Start Menu & Desktop Shortcuts**: Pre-configured with official AeroX AI icon and description.
3. **Windows Apps & Features Registration**: Cleanly registers Publisher, Support URL (`https://aeroxai.com/support`), Version, and Uninstall String.
4. **Clean Uninstaller**: `unins000.exe` cleanly purges only the installed files and shortcuts, preserving unrelated user files.
5. **App Path Registration**: Registers `aeroxai.exe` under Windows App Paths for command-line / Run dialog execution.
