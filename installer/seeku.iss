#define MyAppName "SeekU"
#define MyAppVersion "0.1.0-rc.1"
#define MyAppExeName "seeku.exe"

[Setup]
AppId={{7D2E8F74-F41F-4F22-9E84-5E0C00000001}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher=Tokiperson
DefaultDirName={autopf}\SeekU
DefaultGroupName=SeekU
OutputDir=..\dist\inno
OutputBaseFilename=SeekU-v{#MyAppVersion}-setup
SetupIconFile=..\windows\runner\resources\app_icon.ico
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
DisableProgramGroupPage=yes
UninstallDisplayIcon={app}\{#MyAppExeName}

[Tasks]
Name: "desktopicon"; Description: "创建桌面快捷方式"; GroupDescription: "附加任务："; Flags: unchecked

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\SeekU"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\SeekU"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "启动 SeekU"; Flags: nowait postinstall skipifsilent
