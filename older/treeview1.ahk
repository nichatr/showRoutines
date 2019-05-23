#SingleInstance force

global MyEdit1
global MyEdit2
global MyLabel

Gui, new,, myGui
Gui +Resize
Gui, Add, Edit, r1 vMyEdit1 w500, text of edit control
Gui, Add, Edit, r1 vMyEdit2 w450, text of edit control
gui, add, text, gMyLabel , zzzzzzzzzzz
Gui, Show

#a::
callrout()
return

callrout() {
    ; global MyEdit1
    ; GuiControl, Focus, MyLabel
    ControlGetFocus, outvar, A
    ControlGetPos, x, Y, Width, Height, %outvar%, A
    msgbox, % "outvar=" outvar   "`tX=" x "`tY=" y "`tw=" width "`th=" height
    
    ; GuiControl, Move, MyEdit1, w100
    Return
}

MyLabel:
ControlGet, OutputVar, Hwnd, , MyLabel
msgbox, % OutputVar
; ControlGetPos, x, Y, Width, Height, %OutputVar%
; msgbox, % "outvar=" OutputVar   "`tX=" x "`tY=" y "`tw=" width "`th=" height
return