#ifndef AppVersion
  #error AppVersion must be supplied by the release build
#endif

[Setup]
AppId={{B4B45D16-18AB-4F51-88C5-83A50C765F6C}
AppName=FungiCapture
AppVersion={#AppVersion}
AppPublisher=FungiCapture contributors
AppPublisherURL=https://github.com/achautha/FungiCapture
DefaultDirName={localappdata}\Programs\FungiCapture
DefaultGroupName=FungiCapture
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0.17763
OutputDir=..\dist\installer
OutputBaseFilename=FungiCapture-{#AppVersion}-windows-x64-setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
UninstallDisplayIcon={app}\FungiCapture.exe
LicenseFile=..\LICENSE
CloseApplications=yes
RestartApplications=no
SetupLogging=yes
UsePreviousAppDir=yes

[Files]
Source: "..\dist\FungiCapture\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\FungiCapture"; Filename: "{app}\FungiCapture.exe"; WorkingDir: "{userdocs}"
Name: "{group}\Uninstall FungiCapture"; Filename: "{uninstallexe}"

[Run]
Filename: "{app}\FungiCapture.exe"; Description: "Launch FungiCapture"; Flags: nowait postinstall skipifsilent

; Same AppId/per-user scope as 0.0.1: upgrade in place, never uninstall first.
; No InstallDelete/UninstallDelete: projects, preferences and imported models
; are user data and must never be recursively removed by this installer.
