Unicode true
RequestExecutionLevel user
Name "NauticMixxx"
OutFile "${OUTPUT}"
InstallDir "$LOCALAPPDATA\Programs\NauticMixxx"
InstallDirRegKey HKCU "Software\NauticMixxx" "InstallDir"
SetCompressor /SOLID lzma
Icon "${ICON}"
UninstallIcon "${ICON}"
VIProductVersion "${VERSION}.0"
VIAddVersionKey "ProductName" "NauticMixxx"
VIAddVersionKey "FileDescription" "NauticMixxx Windows installer"
VIAddVersionKey "CompanyName" "NauticMixxx contributors"
VIAddVersionKey "FileVersion" "${VERSION}"
VIAddVersionKey "ProductVersion" "${VERSION}"

!include "MUI2.nsh"
!define MUI_ABORTWARNING
!define MUI_ICON "${ICON}"
!define MUI_UNICON "${ICON}"
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "English"
!insertmacro MUI_LANGUAGE "Spanish"

Section "NauticMixxx" MainSection
  SetShellVarContext current
  SetOutPath "$INSTDIR"
  File /r "${PAYLOAD}\runtime\*"
  File "${PAYLOAD}\LICENSE"
  File "${PAYLOAD}\THIRD_PARTY_NOTICES.md"
  SetOutPath "$LOCALAPPDATA\NauticMixxx\skins\XDJ_RX3_Mixxx"
  File /r "${PAYLOAD}\skins\XDJ_RX3_Mixxx\*"
  SetOutPath "$LOCALAPPDATA\NauticMixxx\controllers"
  File /r "${PAYLOAD}\controllers\Hercules_DJControl_Inpulse_500_RX3\*"
  File /r "${PAYLOAD}\controllers\Pioneer_DDJ_FLX4_RX3\*"
  File /r "${PAYLOAD}\controllers\Pioneer_DDJ_FLX6_RX3\*"
  File /r "${PAYLOAD}\controllers\Pioneer_Roland_RX3\*"
  SetOutPath "$LOCALAPPDATA\NauticMixxx\effects\chains"
  File /r "${PAYLOAD}\effects\chains\*"
  InitPluginsDir
  SetOutPath "$PLUGINSDIR"
  File /oname=profile.cfg "${PAYLOAD}\profile\XDJ_RX3_Mixxx.profile.cfg"
  File /oname=configure-profile.ps1 "${PROFILE_SCRIPT}"
  nsExec::ExecToStack '"$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "$PLUGINSDIR\configure-profile.ps1" -Profile "$LOCALAPPDATA\NauticMixxx" -Template "$PLUGINSDIR\profile.cfg"'
  Pop $0
  Pop $1
  StrCmp $0 "0" +3 0
    MessageBox MB_ICONSTOP "NauticMixxx could not configure its Windows profile: $1"
    Abort
  SetOutPath "$INSTDIR"
  WriteUninstaller "$INSTDIR\Uninstall-NauticMixxx.exe"
  WriteRegStr HKCU "Software\NauticMixxx" "InstallDir" "$INSTDIR"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\NauticMixxx" "DisplayName" "NauticMixxx"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\NauticMixxx" "DisplayVersion" "${VERSION}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\NauticMixxx" "Publisher" "NauticMixxx contributors"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\NauticMixxx" "DisplayIcon" "$INSTDIR\NauticMixxx.exe"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\NauticMixxx" "UninstallString" '"$INSTDIR\Uninstall-NauticMixxx.exe"'
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\NauticMixxx" "NoModify" 1
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\NauticMixxx" "NoRepair" 1
  CreateDirectory "$SMPROGRAMS\NauticMixxx"
  CreateShortcut "$SMPROGRAMS\NauticMixxx\NauticMixxx.lnk" "$INSTDIR\NauticMixxx.exe" '--settings-path "$LOCALAPPDATA\NauticMixxx"' "$INSTDIR\NauticMixxx.exe" 0
  CreateShortcut "$SMPROGRAMS\NauticMixxx\Uninstall NauticMixxx.lnk" "$INSTDIR\Uninstall-NauticMixxx.exe"
  CreateShortcut "$DESKTOP\NauticMixxx.lnk" "$INSTDIR\NauticMixxx.exe" '--settings-path "$LOCALAPPDATA\NauticMixxx"' "$INSTDIR\NauticMixxx.exe" 0
SectionEnd

Section "Uninstall"
  SetShellVarContext current
  Delete "$DESKTOP\NauticMixxx.lnk"
  RMDir /r "$SMPROGRAMS\NauticMixxx"
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\NauticMixxx"
  DeleteRegKey HKCU "Software\NauticMixxx"
  RMDir /r "$INSTDIR"
  ; Keep the user's music library and settings in LOCALAPPDATA\NauticMixxx.
SectionEnd
