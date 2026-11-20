#ifndef AppVersion
  #error AppVersion must be supplied by the release build
#endif

[Setup]
AppId={{B4B45D16-18AB-4F51-88C5-83A50C765F6C}
AppName=FungiCapture
AppVersion={#AppVersion}
AppPublisher=FungiCapture contributors
AppPublisherURL=https://github.com/achautha/FungiCapture
AppSupportURL=https://github.com/achautha/FungiCapture/issues
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
InfoBeforeFile=WINDOWS.md
CloseApplications=yes
RestartApplications=no
SetupLogging=yes

[Files]
Source: "..\dist\FungiCapture\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\FungiCapture"; Filename: "{app}\FungiCapture.exe"; WorkingDir: "{userdocs}"
Name: "{group}\FungiCapture documentation"; Filename: "{app}\WINDOWS.md"
Name: "{group}\Uninstall FungiCapture"; Filename: "{uninstallexe}"

[Run]
Filename: "{app}\FungiCapture.exe"; Description: "Launch FungiCapture"; Flags: nowait postinstall skipifsilent

; Never delete project/output folders or user settings during uninstall.
