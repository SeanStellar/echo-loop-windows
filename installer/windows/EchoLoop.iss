; Echo Loop Windows installer (unofficial fork)
; Build with: ISCC.exe installer\windows\EchoLoop.iss

#define MyAppName "Echo Loop Windows"
#define MyAppVersion "1.0.46"
#define MyAppPublisher "SeanStellar (unofficial fork)"
#define MyAppURL "https://github.com/SeanStellar/echo-loop-windows"
#define MyAppExeName "echo_loop.exe"

[Setup]
AppId={{B7E2F5B4-6C1D-4E9A-9E3B-7A0D4C2F8A11}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}/releases
DefaultDirName={autopf}\Echo Loop Windows
DefaultGroupName=Echo Loop Windows
DisableProgramGroupPage=yes
LicenseFile=..\..\LICENSE
InfoBeforeFile=..\..\NOTICE
OutputDir=..\..\dist\installer
OutputBaseFilename=EchoLoop-Windows-Setup-{#MyAppVersion}
SetupIconFile=..\..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
UninstallDisplayName={#MyAppName}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0.17763
VersionInfoVersion={#MyAppVersion}.0
VersionInfoDescription=Echo Loop Windows installer (unofficial fork)

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional icons:"; Flags: unchecked

[Files]
Source: "..\..\dist\EchoLoop-Windows\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\..\LICENSE"; DestDir: "{app}"; DestName: "LICENSE.txt"; Flags: ignoreversion
Source: "..\..\NOTICE"; DestDir: "{app}"; DestName: "NOTICE.txt"; Flags: ignoreversion
Source: "..\..\THIRD_PARTY_NOTICES.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\WINDOWS.md"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\Echo Loop Windows"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\Echo Loop Windows"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Launch Echo Loop Windows"; Flags: nowait postinstall skipifsilent
