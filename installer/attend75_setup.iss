; ============================================================================
; Attend75 - Professional Inno Setup Script (Production Ready)
; Installer for Attend 75 - Attendance Management for Students
; Windows x64 - With VC++ Redistributable Bundle
; ============================================================================

#define MyAppName "Attend 75"
#define MyAppVersion "0.1.0"
#define MyAppPublisher "Attend75"
#define MyAppURL "https://github.com/naman-kumar1212/attend75"
#define MyAppExeName "attend75.exe"
#define MyAppDescription "Attendance Management for Students"
#define MyAppCopyright "Copyright (C) 2026 Attend75. All rights reserved."

; ============================================================================
; SETUP CONFIGURATION
; ============================================================================

[Setup]
; Application Identity
AppId={{A7753E90-3F8C-4D2E-B125-9E9F6C3A2D41}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}/issues
AppUpdatesURL={#MyAppURL}/releases

; Installation Directories
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
UsePreviousAppDir=yes

; Output Settings
OutputDir=..\build\installer
OutputBaseFilename=Attend75_{#MyAppVersion}_Setup_x64

; Compression Settings
Compression=lzma2/ultra64
SolidCompression=yes
LZMAUseSeparateProcess=yes
LZMADictionarySize=1048576
LZMANumFastBytes=273

; Visual Settings
WizardStyle=modern
WizardSizePercent=120
SetupIconFile=..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
UninstallDisplayName={#MyAppName}

; Privileges and Architecture
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

; Windows Version Requirements
MinVersion=10.0.17763

; Version Information
VersionInfoVersion=0.1.0.0
VersionInfoCompany={#MyAppPublisher}
VersionInfoDescription={#MyAppDescription}
VersionInfoCopyright={#MyAppCopyright}
VersionInfoProductName={#MyAppName}
VersionInfoProductVersion={#MyAppVersion}

; Application Behavior
CloseApplications=force
CloseApplicationsFilter=*.exe
RestartApplications=no
ShowLanguageDialog=auto
AllowNoIcons=yes

; Additional Settings
SetupLogging=yes
DisableReadyMemo=no
DisableWelcomePage=no
DisableFinishedPage=no

; ============================================================================
; LANGUAGES
; ============================================================================

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

; ============================================================================
; INSTALLATION TASKS
; ============================================================================

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "quicklaunchicon"; Description: "{cm:CreateQuickLaunchIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked; OnlyBelowVersion: 6.1.7601; Check: not IsAdminInstallMode
Name: "startup"; Description: "Launch {#MyAppName} at Windows startup"; GroupDescription: "Startup Options:"; Flags: unchecked

; ============================================================================
; FILES TO INSTALL
; ============================================================================

[Files]
; Main Executable
Source: "..\build\windows\x64\runner\Release\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion

; Flutter Engine
Source: "..\build\windows\x64\runner\Release\flutter_windows.dll"; DestDir: "{app}"; Flags: ignoreversion

; Plugin DLLs
Source: "..\build\windows\x64\runner\Release\app_links_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\build\windows\x64\runner\Release\file_saver_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\build\windows\x64\runner\Release\file_selector_windows_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\build\windows\x64\runner\Release\flutter_local_notifications_windows.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\build\windows\x64\runner\Release\permission_handler_windows_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\build\windows\x64\runner\Release\screen_retriever_windows_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\build\windows\x64\runner\Release\url_launcher_windows_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\build\windows\x64\runner\Release\window_manager_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\build\windows\x64\runner\Release\windows_single_instance_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion

; Data Folder (Flutter Assets, ICU Data)
Source: "..\build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

; Visual C++ Redistributable Installer (BUNDLED - Optional)
Source: "..\redist\vc_redist.x64.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall skipifsourcedoesntexist; Check: VCRedistNeedsInstall

; ============================================================================
; SHORTCUTS & ICONS
; ============================================================================

[Icons]
; Start Menu
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Comment: "{#MyAppDescription}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"

; Desktop Icon
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Comment: "{#MyAppDescription}"; Tasks: desktopicon

; Quick Launch (Windows 7 and below)
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: quicklaunchicon

; ============================================================================
; REGISTRY ENTRIES
; ============================================================================

[Registry]
; URL protocol registration for OAuth deep links
Root: HKCU; Subkey: "Software\Classes\com.namankumar.attend75"; ValueType: string; ValueName: ""; ValueData: "URL:Attend75 Protocol"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\com.namankumar.attend75"; ValueType: string; ValueName: "URL Protocol"; ValueData: ""
Root: HKCU; Subkey: "Software\Classes\com.namankumar.attend75\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\{#MyAppExeName},0"
Root: HKCU; Subkey: "Software\Classes\com.namankumar.attend75\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#MyAppExeName}"" ""%1"""

; Application Settings
Root: HKCU; Subkey: "Software\{#MyAppPublisher}\{#MyAppName}"; ValueType: string; ValueName: "InstallPath"; ValueData: "{app}"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\{#MyAppPublisher}\{#MyAppName}"; ValueType: string; ValueName: "Version"; ValueData: "{#MyAppVersion}"

; Startup Entry (if task selected)
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "{#MyAppName}"; ValueData: """{app}\{#MyAppExeName}"""; Tasks: startup; Flags: uninsdeletevalue

; ============================================================================
; POST-INSTALLATION ACTIONS
; ============================================================================

[Run]
; Install Visual C++ Redistributable (RUNS AUTOMATICALLY IF NEEDED)
Filename: "{tmp}\vc_redist.x64.exe"; Parameters: "/quiet /norestart"; StatusMsg: "Installing Microsoft Visual C++ Redistributable..."; Flags: waituntilterminated skipifdoesntexist; Check: VCRedistNeedsInstall

; Launch Application
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

; ============================================================================
; UNINSTALL CLEANUP
; ============================================================================

[UninstallDelete]
; Only remove user-specific app data
Type: filesandordirs; Name: "{localappdata}\Attend75"

; ============================================================================
; CUSTOM MESSAGES
; ============================================================================

[Messages]
WelcomeLabel2=This will install [name/ver] on your computer.%n%n{#MyAppDescription}%n%nIt is recommended that you close all other applications before continuing.%n%nNote: This installer will automatically install Microsoft Visual C++ Redistributable if needed.
FinishedHeadingLabel=Completing the [name] Setup Wizard
FinishedLabel=Setup has finished installing [name] on your computer. The application may be launched by selecting the installed shortcuts.

; ============================================================================
; PASCAL SCRIPT CODE
; ============================================================================

[Code]
var
  DeleteAppDataOnUninstall: Boolean;
  VCRedistInstalled: Boolean;

// Check if Visual C++ Redistributable is installed
function VCRedistNeedsInstall: Boolean;
var
  Version: String;
  Major, Minor, Build: Integer;
  VersionStr: String;
begin
  Result := True;
  VCRedistInstalled := False;
  
  // Check for VC++ 2015-2022 Redistributable (x64)
  // Check both possible registry locations
  if RegQueryStringValue(HKLM64, 'SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\X64', 'Version', Version) or
     RegQueryStringValue(HKLM64, 'SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64', 'Version', Version) then
  begin
    // Version format is like "v14.30.30704" or "v14.38.33135"
    // We need at least v14.30.30704 for modern Flutter apps
    if (Length(Version) > 4) and (Copy(Version, 1, 1) = 'v') then
    begin
      try
        // Parse version string
        Delete(Version, 1, 1); // Remove 'v'
        VersionStr := Version;
        
        // Extract major version
        Major := StrToInt(Copy(VersionStr, 1, Pos('.', VersionStr) - 1));
        Delete(VersionStr, 1, Pos('.', VersionStr));
        
        // Extract minor version
        Minor := StrToInt(Copy(VersionStr, 1, Pos('.', VersionStr) - 1));
        Delete(VersionStr, 1, Pos('.', VersionStr));
        
        // Extract build number
        Build := StrToInt(VersionStr);
        
        // Check if version is sufficient (14.30.30704 or higher)
        if (Major > 14) or 
           ((Major = 14) and (Minor > 30)) or
           ((Major = 14) and (Minor = 30) and (Build >= 30704)) then
        begin
          Result := False;
          VCRedistInstalled := True;
          Log('VC++ Redistributable already installed: v' + IntToStr(Major) + '.' + IntToStr(Minor) + '.' + IntToStr(Build));
        end
        else
        begin
          Log('VC++ Redistributable version too old: v' + IntToStr(Major) + '.' + IntToStr(Minor) + '.' + IntToStr(Build));
          Log('Required version: v14.30.30704 or higher');
        end;
      except
        Result := True; // If parsing fails, assume we need to install
        Log('Failed to parse VC++ version string: ' + Version);
      end;
    end;
  end
  else
  begin
    Log('VC++ Redistributable not found in registry');
  end;
  
  if Result then
    Log('VC++ Redistributable installation required')
  else
    Log('VC++ Redistributable installation not needed');
end;

// Initialize Setup
function InitializeSetup(): Boolean;
begin
  Result := True;
  DeleteAppDataOnUninstall := False;
  
  Log('===========================================');
  Log('Attend 75 Setup - Version {#MyAppVersion}');
  Log('===========================================');
end;

// Custom wizard initialization
procedure InitializeWizard;
begin
  WizardForm.WelcomeLabel2.Caption := 
    'This will install ' + '{#MyAppName}' + ' version ' + '{#MyAppVersion}' + ' on your computer.' + #13#10 + #13#10 +
    '{#MyAppDescription}' + #13#10 + #13#10 +
    'It is recommended that you close all other applications before continuing.' + #13#10 + #13#10 +
    'Note: This installer will automatically install Microsoft Visual C++ ' +
    'Redistributable if needed.' + #13#10 + #13#10 +
    'Click Next to continue, or Cancel to exit Setup.';
end;

// Pre-install checks
function PrepareToInstall(var NeedsRestart: Boolean): String;
begin
  Result := '';
  NeedsRestart := False;
  
  // Check if VC++ needs to be installed
  if VCRedistNeedsInstall then
  begin
    Log('Preparing to install VC++ Redistributable...');
  end;
end;

// Post-installation actions
procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    Log('Installation completed successfully');
  end;
  
  if CurStep = ssInstall then
  begin
    Log('Beginning installation...');
  end;
end;

// Done installing
procedure DeinitializeSetup();
begin
  Log('Setup wizard closing');
  Log('===========================================');
end;

// Initialize uninstall
function InitializeUninstall: Boolean;
var
  MsgResult: Integer;
begin
  Result := True;
  
  // Ask user if they want to remove app data
  MsgResult := MsgBox(
    'Do you want to remove all application data?' + #13#10 +
    '(This includes settings, cached data, and saved information)' + #13#10 + #13#10 +
    'Choose "Yes" to delete all data, or "No" to keep your settings.',
    mbConfirmation, MB_YESNO or MB_DEFBUTTON2
  );
  
  DeleteAppDataOnUninstall := (MsgResult = IDYES);
end;

// Uninstall step changed
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  AppDataPath, PublisherPath: String;
begin
  if CurUninstallStep = usPostUninstall then
  begin
    // Only delete app data if user confirmed
    if DeleteAppDataOnUninstall then
    begin
      AppDataPath := ExpandConstant('{localappdata}\Attend75');
      PublisherPath := ExpandConstant('{localappdata}\{#MyAppPublisher}\{#MyAppName}');
      
      if DirExists(AppDataPath) then
      begin
        if DelTree(AppDataPath, True, True, True) then
          Log('Deleted app data: ' + AppDataPath)
        else
          Log('Failed to delete app data: ' + AppDataPath);
      end;
      
      if DirExists(PublisherPath) then
      begin
        if DelTree(PublisherPath, True, True, True) then
          Log('Deleted app data: ' + PublisherPath)
        else
          Log('Failed to delete app data: ' + PublisherPath);
      end;
    end
    else
    begin
      Log('User chose to keep application data');
    end;
  end;
end;