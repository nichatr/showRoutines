/**
1. create installation:
  a. create showRoutines.exe
  b. create installer.exe

2. run installation:
  a. copy installer.exe to any temporary folder
  b. run installer.exe

*/

; https://github.com/wandersick/az-autohotkey-silent-setup.git

FileInstall, showRoutines.exe, showRoutines.exe

installPath := A_AppData . "\showRoutines"

; delete application folder if exists.
if (InStr(FileExist(installPath), "D")) {
  FileRemoveDir, %installPath%, 1 ; = recurse
}

; create application folder.
FileCreateDir, %installPath%

; move the application to it's folder.
FileMove,  %A_ScriptDir%\showRoutines.exe, %installPath%, 1  ; = overwrite

; extract the application files.
RunWait,  %installPath%\showRoutines.exe 1 2 3 4 5 1, %installPath% ; 5 dummy args + 1=install

FileCreateShortcut, %installPath%\showRoutines.exe, %A_Desktop%\showRoutines.lnk, %installPath%
