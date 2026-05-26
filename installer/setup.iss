; Nexus Tracker Installer Script
; Requires Inno Setup 6.2 or later: https://jrsoftware.org/isinfo.php

#define MyAppName "Nexus Tracker"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "cookiesn1ffer"
#define MyAppURL "https://github.com/yourusername/nexus-tracker"
#define MyAppExeName "nexus_tracker.exe"

[Setup]
AppId={{com.nexustracker.app}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
OutputDir=..\dist
OutputBaseFilename=Nexus Tracker Setup {#MyAppVersion}
SetupIconFile=..\windows\runner\resources\app_icon.ico
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequiredOverridesAllowed=dialog
DisableProgramGroupPage=yes
DisableWelcomePage=no
LicenseFile=..\LICENSE

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "quicklaunchicon"; Description: "{cm:CreateQuickLaunchIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked; OnlyBelowVersion: 6.1; Check: not IsAdminInstallMode

[Files]
; Main executable and all runtime files
Source: "..\build\windows\x64\runner\Release\nexus_tracker.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\build\windows\x64\runner\Release\*.dll"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs
Source: "..\build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
