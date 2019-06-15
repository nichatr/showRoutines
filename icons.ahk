IniRead, valueOfX, %A_ScriptDir%\showRoutines.ini, settings, winX
IniRead, valueOfY, %A_ScriptDir%\showRoutines.ini, settings, winY
IniRead, valueOfWidth, %A_ScriptDir%\showRoutines.ini, settings, winWidth
IniRead, valueOfHeight, %A_ScriptDir%\showRoutines.ini, settings, winHeight


; menu bar

Loop {
    Menu, FileMenu, Add, icon %A_index%, MenuHandler
    Menu, FileMenu, Icon, icon %A_index%, shell32.dll, %A_index%

} until A_index >= 160


; Menu, FileMenu, Add, Open file, MenuHandler
; Menu, FileMenu, Add, Script Icon, MenuHandler
; Menu, FileMenu, Add, Suspend Icon, MenuHandler
; Menu, FileMenu, Add, Pause Icon, MenuHandler
; Menu, FileMenu, Icon, Open file, shell32.dll, 1
; Menu, FileMenu, Icon, Script Icon, shell32.dll, 2
; Menu, FileMenu, Icon, Suspend Icon, shell32.dll, 3
; Menu, FileMenu, Icon, Pause Icon, shell32.dll, 4

Gui, font, s20
Menu, MyMenuBar, Add, &File, :FileMenu
Gui, Menu, MyMenuBar
Gui, Add, Button, gExit, Exit This Example
Gui, Show, X%valueOfX% Y%valueOfY% W%valueOfWidth% H%valueOfHeight%, %fileCode%
return

MenuHandler:
if (A_ThisMenuItem = "Open file")
    msgbox, % "open file..."

return

Exit:
ExitApp