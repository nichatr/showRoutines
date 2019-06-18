#SingleInstance force

showSettings()
return

showSettings() {

    ;------
    ; Font
    ;------
    Gui 2:Add, GroupBox, x+5 y+10 w140 h140 , Font

    Gui 2:Add, Text, xm+20 ym+40 +0x200, All
    Gui 2:Add, Edit, xm+50 ym+35 w60 +Number, 14
    Gui 2:Add, UpDown,  , 14

    Gui 2:Add, Text, xm+20 ym+70 w60 +0x200, Tree
    Gui 2:Add, Edit, xm+50 ym+65 w60 +Number, 15
    Gui 2:Add, UpDown, , 15

    Gui 2:Add, Text, xm+20 ym+100 w60 +0x200, Code
    Gui 2:Add, Edit, xm+50 ym+95 w60 +Number, 16
    Gui 2:Add, UpDown, , 16

    ;-----------------
    ; background color
    ;-----------------
    Gui 2:Add, GroupBox, w140 h140 x+50 ys section, Background Color

    Gui 2:Add, Text, w50 xs15 ys36 +0x200, All
    Gui 2:Add, Edit, w60 xs45 ys31, 3e4b28

    Gui 2:Add, Text, w50 xs15 ys66 +0x200, Tree
    Gui 2:Add, Edit, w60 xs45 ys61, FFFFFF

    Gui 2:Add, Text, w50 xs15 ys96 +0x200, Code
    Gui 2:Add, Edit, w60 xs45 ys91, ABFECD

    ;-----------------
    ; foreground color
    ;-----------------
    Gui 2:Add, GroupBox, w140 h140 x+50 ys section, Foreground Color

    Gui 2:Add, Text, w50 xs15 ys36 +0x200, All
    Gui 2:Add, Edit, w60 xs45 ys31, 3e4b28

    Gui 2:Add, Text, w50 xs15 ys66 +0x200, Tree
    Gui 2:Add, Edit, w60 xs45 ys61, FFFFFF

    Gui 2:Add, Text, w50 xs15 ys96 +0x200, Code
    Gui 2:Add, Edit, w60 xs45 ys91, ABFECD

    ;-----------------
    ; colored block
    ;-----------------
    Gui 2:Add, Progress, w50 h20 cABFECD , 100

    ;-----------------
    ; 
    ;-----------------
    Gui 2:Add, CheckBox, x42 y300 w120 h23 +Checked, Save on exit

    Gui 2:Show, x1300 w490 h420, Settings
    Return

    2GuiEscape:
        Reload
        return

    2GuiClose:
        Gui, 2:Destroy
        Return
}