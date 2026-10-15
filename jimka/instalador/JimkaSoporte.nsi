; Instalador Jimka Offshore Soporte
; Descarga el RustDesk oficial y lo deja apuntando al servidor de Jimka
; mediante el nombre del ejecutable (host=...,key=...).
Unicode true
!include "MUI2.nsh"
!include "LogicLib.nsh"

!define APPNAME "Jimka Soporte"
!define COMPANY "Jimka Offshore"
!define HOST "rust.jimkaoffshore.com"
!define KEY "vrsx5Fk+trBT8nKoPSN0i+RZL6dHyaF0WWFmuM6oCX0="
!define EXENAME "rustdesk-host=${HOST},key=${KEY},.exe"
!define UNINSTKEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\JimkaSoporte"

Name "${APPNAME}"
OutFile "JimkaSoporte-Setup.exe"
InstallDir "$LOCALAPPDATA\JimkaSoporte"
RequestExecutionLevel user
BrandingText "${COMPANY}"
VIProductVersion "1.0.0.0"
VIAddVersionKey "ProductName" "${APPNAME}"
VIAddVersionKey "CompanyName" "${COMPANY}"
VIAddVersionKey "FileDescription" "Instalador ${APPNAME}"
VIAddVersionKey "FileVersion" "1.0.0"
VIAddVersionKey "LegalCopyright" "${COMPANY}. RustDesk es AGPL-3.0."

!define MUI_ICON "icon.ico"
!define MUI_UNICON "icon.ico"
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP "header.bmp"
!define MUI_WELCOMEFINISHPAGE_BITMAP "welcome.bmp"
!define MUI_UNWELCOMEFINISHPAGE_BITMAP "welcome.bmp"
!define MUI_WELCOMEPAGE_TITLE "Soporte remoto Jimka Offshore"
!define MUI_WELCOMEPAGE_TEXT "Este asistente instala la herramienta de soporte remoto del equipo de Tecnologia de Jimka Offshore.$\r$\n$\r$\nSe necesita conexion a internet para descargar el programa."
!define MUI_FINISHPAGE_RUN "$INSTDIR\${EXENAME}"
!define MUI_FINISHPAGE_RUN_TEXT "Abrir ${APPNAME} ahora"

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "Spanish"

Section "Instalar"
  SetOutPath "$INSTDIR"
  File "icon.ico"
  File "descargar.ps1"
  DetailPrint "Descargando RustDesk oficial..."
  nsExec::ExecToLog 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$INSTDIR\descargar.ps1" -Destino "$INSTDIR\${EXENAME}"'
  Pop $0
  ${If} $0 != 0
    MessageBox MB_ICONSTOP "No se pudo descargar el programa. Revisa la conexion a internet e intenta de nuevo."
    Abort
  ${EndIf}
  Delete "$INSTDIR\descargar.ps1"

  CreateShortcut "$DESKTOP\${APPNAME}.lnk" "$INSTDIR\${EXENAME}" "" "$INSTDIR\icon.ico"
  CreateDirectory "$SMPROGRAMS\${APPNAME}"
  CreateShortcut "$SMPROGRAMS\${APPNAME}\${APPNAME}.lnk" "$INSTDIR\${EXENAME}" "" "$INSTDIR\icon.ico"
  CreateShortcut "$SMPROGRAMS\${APPNAME}\Desinstalar.lnk" "$INSTDIR\Desinstalar.exe"

  WriteUninstaller "$INSTDIR\Desinstalar.exe"
  WriteRegStr HKCU "${UNINSTKEY}" "DisplayName" "${APPNAME}"
  WriteRegStr HKCU "${UNINSTKEY}" "Publisher" "${COMPANY}"
  WriteRegStr HKCU "${UNINSTKEY}" "DisplayIcon" "$INSTDIR\icon.ico"
  WriteRegStr HKCU "${UNINSTKEY}" "UninstallString" '"$INSTDIR\Desinstalar.exe"'
SectionEnd

Section "Uninstall"
  Delete "$DESKTOP\${APPNAME}.lnk"
  RMDir /r "$SMPROGRAMS\${APPNAME}"
  RMDir /r "$INSTDIR"
  DeleteRegKey HKCU "${UNINSTKEY}"
SectionEnd
