; =====================================================================
; AeroX AI Official Windows Installer Script
; Publisher: AeroX Studio
; Product: AeroX AI
; =====================================================================

#define MyAppName "AeroX AI"
#define MyAppPublisher "AeroX Studio"
#define MyAppURL "https://aeroxai.com"
#define MyAppSupportURL "https://aeroxai.com/support"
#define MyAppUpdatesURL "https://aeroxai.com"
#define MyAppExeName "aeroxai.exe"
#define MyAppId "{{B4208E27-463F-4B41-A89E-7589D7887E8B}}"

#ifndef MyAppVersion
  #define MyAppVersion "1.0.0"
#endif

#ifndef MyAppVersionBuild
  #define MyAppVersionBuild "1.0.0.1"
#endif

#ifndef SourceDir
  #define SourceDir "..\build\windows\x64\runner\Release"
#endif

#ifndef OutputDir
  #define OutputDir "..\build\installer"
#endif

[Setup]
; Unique application identity GUID
AppId={#MyAppId}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppSupportURL}
AppUpdatesURL={#MyAppUpdatesURL}
AppCopyright=Copyright (C) 2026 {#MyAppPublisher}. All rights reserved.

; Installation directories
DefaultDirName={autopf}\AeroX Studio\{#MyAppName}
DefaultGroupName={#MyAppPublisher}\{#MyAppName}
DisableProgramGroupPage=yes

; User vs System privileges (supports both clean user install & system-wide admin install)
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog

; Output configuration
OutputDir={#OutputDir}
OutputBaseFilename=AeroX_AI_Setup_x64
SetupIconFile=..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName},0
UninstallDisplayName={#MyAppName}

; Compression
Compression=lzma2/ultra64
InternalCompressLevel=ultra
SolidCompression=yes

; Architecture (64-bit Windows)
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

; Appearance and Wizard
WizardStyle=modern
DisableDirPage=auto
DisableReadyPage=no
CloseApplications=yes
RestartApplications=no

; Version info in Windows Explorer file properties of Setup.exe
VersionInfoVersion={#MyAppVersionBuild}
VersionInfoCompany={#MyAppPublisher}
VersionInfoDescription={#MyAppName} Windows Setup
VersionInfoTextVersion={#MyAppVersion}
VersionInfoCopyright=Copyright (C) 2026 {#MyAppPublisher}
VersionInfoProductName={#MyAppName}
VersionInfoProductVersion={#MyAppVersion}

; Code signing hooks (optional via Inno Setup command-line /S)
#ifdef UseSignTool
SignTool=signtool $f
SignedUninstaller=yes
#endif

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "startmenuicon"; Description: "Create Start Menu shortcut"; GroupDescription: "{cm:AdditionalIcons}"
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Main executable and libraries
Source: "{#SourceDir}\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourceDir}\*.dll"; DestDir: "{app}"; Flags: ignoreversion
; Application data and flutter assets
Source: "{#SourceDir}\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs
; Official application icon for shortcuts / uninstaller reference
Source: "..\windows\runner\resources\app_icon.ico"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
; Start Menu shortcut
Name: "{autoprograms}\{#MyAppPublisher}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\{#MyAppExeName}"; Tasks: startmenuicon; Comment: "{#MyAppName} Desktop Client"
; Optional Desktop shortcut
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\{#MyAppExeName}"; Tasks: desktopicon; Comment: "{#MyAppName} Desktop Client"

[Registry]
; Register App Path so AeroX AI can be launched from Run dialog or command line
Root: HKA; Subkey: "Software\Microsoft\Windows\CurrentVersion\App Paths\{#MyAppExeName}"; ValueType: string; ValueName: ""; ValueData: "{app}\{#MyAppExeName}"; Flags: uninsdeletekey
Root: HKA; Subkey: "Software\Microsoft\Windows\CurrentVersion\App Paths\{#MyAppExeName}"; ValueType: string; ValueName: "Path"; ValueData: "{app}"; Flags: uninsdeletekey

; Official Publisher and Support Metadata for Windows Apps & Features
Root: HKA; Subkey: "Software\Microsoft\Windows\CurrentVersion\Uninstall\{#MyAppId}_is1"; ValueType: string; ValueName: "Publisher"; ValueData: "{#MyAppPublisher}"; Flags: uninsdeletevalue
Root: HKA; Subkey: "Software\Microsoft\Windows\CurrentVersion\Uninstall\{#MyAppId}_is1"; ValueType: string; ValueName: "DisplayName"; ValueData: "{#MyAppName}"; Flags: uninsdeletevalue
Root: HKA; Subkey: "Software\Microsoft\Windows\CurrentVersion\Uninstall\{#MyAppId}_is1"; ValueType: string; ValueName: "DisplayVersion"; ValueData: "{#MyAppVersion}"; Flags: uninsdeletevalue
Root: HKA; Subkey: "Software\Microsoft\Windows\CurrentVersion\Uninstall\{#MyAppId}_is1"; ValueType: string; ValueName: "DisplayIcon"; ValueData: "{app}\{#MyAppExeName},0"; Flags: uninsdeletevalue
Root: HKA; Subkey: "Software\Microsoft\Windows\CurrentVersion\Uninstall\{#MyAppId}_is1"; ValueType: string; ValueName: "URLInfoAbout"; ValueData: "{#MyAppURL}"; Flags: uninsdeletevalue
Root: HKA; Subkey: "Software\Microsoft\Windows\CurrentVersion\Uninstall\{#MyAppId}_is1"; ValueType: string; ValueName: "HelpLink"; ValueData: "{#MyAppSupportURL}"; Flags: uninsdeletevalue
Root: HKA; Subkey: "Software\Microsoft\Windows\CurrentVersion\Uninstall\{#MyAppId}_is1"; ValueType: string; ValueName: "URLUpdateInfo"; ValueData: "{#MyAppUpdatesURL}"; Flags: uninsdeletevalue
Root: HKA; Subkey: "Software\Microsoft\Windows\CurrentVersion\Uninstall\{#MyAppId}_is1"; ValueType: dword; ValueName: "NoModify"; ValueData: 1; Flags: uninsdeletevalue
Root: HKA; Subkey: "Software\Microsoft\Windows\CurrentVersion\Uninstall\{#MyAppId}_is1"; ValueType: dword; ValueName: "NoRepair"; ValueData: 1; Flags: uninsdeletevalue

[Run]
; Option to launch AeroX AI after installation completes
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
; Clean up only application-created files in installation directory
Type: filesandordirs; Name: "{app}\data"
Type: dirifempty; Name: "{app}"
Type: dirifempty; Name: "{autoprograms}\{#MyAppPublisher}"
