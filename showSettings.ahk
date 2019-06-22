#SingleInstance force

showSettings()
return

showSettings() {
    static font_size, font_color, tree_step, window_color, control_color, treeviewWidth

    IniRead, font_size, showRoutines.ini, font, size
    IniRead, font_color, showRoutines.ini, font, color
    IniRead, tree_step, showRoutines.ini, position, treeviewWidthStep
    IniRead, window_color, showRoutines.ini, backgroundColor, window
    IniRead, control_color, showRoutines.ini, backgroundColor, control

    Loop:
    ;------
    ; Font
    ;------
    Gui 2:Add, GroupBox, x+5 y+10 w160 h100 , Font

    Gui 2:Add, Text, xm+20 ym+40 +0x200, Size
    Gui 2:Add, Edit, vfont_size xm+50 ym+35 w40 +Number, %font_size%
    Gui 2:Add, UpDown, Range7-20, %font_size%

    Gui 2:Add, Text, xm+20 ym+70 w60 +0x200, Color
    Gui 2:Add, Edit, vfont_color xm+50 ym+65 w50, %font_color%

    Gui 2:Add, Progress, w25 h20 xs110 ys61 c%font_color%, 100

    ;-----------------
    ; background color
    ;-----------------
    Gui 2:Add, GroupBox, w170 h100 x+50 ys section, Background Color

    Gui 2:Add, Text, w50 xs15 ys36 +0x200, Window
    Gui 2:Add, Edit, vwindow_color w50 xs60 ys31, %window_color%
    Gui 2:Add, Progress, w25 h20 xs120 ys31 c%window_color%, 100

    Gui 2:Add, Text, w50 xs15 ys66 +0x200, Controls
    Gui 2:Add, Edit, vcontrol_color w50 xs60 ys61, %control_color%
    Gui 2:Add, Progress, w25 h20 xs120 ys61 c%control_color%, 100

    ;-----------------
    ; other settings
    ;-----------------
    Gui 2:Add, Text,  xm+5 yp+70 +0x200, Tree width change step
    Gui 2:Add, Edit, vtree_step w50 xp+120 yp-5 +Number, %tree_step%
    Gui 2:Add, UpDown, Range10-200, %tree_step%

    ;-----------------
    ; 
    ;-----------------
    Gui, 2:Add, Button, x70 y200 w80, Save
    Gui, 2:Add, Button, x160 y200 w80, Cancel
    Gui, 2:Add, Button, x250 y200 w80, Default

    show:
        Gui 2:+Resize -SysMenu +ToolWindow
        Gui 2:Show, x300 y540 w400 h250, Settings
        Return

    2GuiEscape:
        Reload
        return

    2GuiClose:
        Gui, 2:Destroy
        Return
    
    2ButtonSave:
        gui 2:Submit, NoHide
        
        if (font_size < 7 or font_size > 20) {
            msgbox, % "Font size must be between 6 and 20"
            Goto, show
        } else
        
        if (tree_step < 10 or tree_step > 200) {
            msgbox, % "Step must be between 10 and 200"
            Goto, show
        } else {
            Progress, zh0 fs10, % "Settings saved"
            Sleep, 500
            Progress, off
            
            IniWrite, %font_size%, showRoutines.ini, font, size
            IniWrite, %font_color%, showRoutines.ini, font, color
            if (tree_step > 0)
                IniWrite, %tree_step%, showRoutines.ini, position, treeviewWidthStep
            IniWrite, %window_color%, showRoutines.ini, backgroundColor, window
            IniWrite, %control_color%, showRoutines.ini, backgroundColor, control

            Gui, 2:Destroy
            return
        }
        
        Goto, show

        ; Load the default values (again from ini file).
    2ButtonDefault:
    {
        IniRead, treeviewWidth, showRoutines.ini, default, treeviewWidth
        IniRead, font_size, showRoutines.ini, default, fontsize
        IniRead, font_color, showRoutines.ini, default, fontcolor
        IniRead, tree_step, showRoutines.ini, default, treeviewWidthStep
        IniRead, window_color, showRoutines.ini, default, windowcolor
        IniRead, control_color, showRoutines.ini, default, controlcolor

        ; font_size := 9
        ; font_color := "C4C4C4"
        ; window_color := "3E3E3E"
        ; control_color := "232323"
        ; tree_step := 100

        Gui, 2:Destroy
        Goto, Loop
    }

    2ButtonCancel:
        Gui, 2:Destroy
        Return
}