#SingleInstance off     ;force
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
    ;--------------------------------------------------------------------------------------
    ; Version with:
    ;   listbox for showing code
    ;   parameter for input file
    ;   external ini file
    ;--------------------------------------------------------------------------------------
    ; parameters:
    ;   A_Args[1] = routine calls file = outfile.txt
    ;   A_Args[2] = source code file   = outfile.cblle.txt
    ;   A_Args[3] = path where above files created = z:\bussup\txt\\
    ;   A_Args[4] = use existing files or select = *NEW|*OLD|*SELECT (default)
    ;               *NEW = try to load above files
    ;               *OLD = use existing file found in showRoutines.ini
    ;               *SELECT = open file selector
    ;
    ;--------------------------------------------------------------------------------------
    ; 1. read text file CBTREEF5.TXT containing the output of program CBTREER5:
    ; 00001, 0886.00, 0913.00, 0899.00,MAIN                          ,INITIALIZE-ROUTINE            
    ; 00002, 0886.00, 0913.00, 0900.00,MAIN                          ,MAIN-ROUTINE                  
    ; 00003, 0916.00, 0940.00, 0000.00,INITIALIZE-ROUTINE            ,                              
    ; 00004, 0943.00, 0976.00, 0968.00,MAIN-ROUTINE                  ,RFCONLIF-ROUTINE 
    ;    etc...
    ; 2. populate array of routines allRoutines[] with above data.
    ;--------------------------------------------------------------------------------------
    ; file cbtreef5.txt was created in AS400 with:
    ; cbtree_2 ....
    ; cpyf qtemp/cbtreef5  dcommon/cbtreef5 *replace
    ; CVTDBF FROMFILE(DCOMMON/CBTREEF5) TOSTMF('/output/bussup/txt/cbtreef5') TOFMT(*FIXED) FIXED(*CRLF (*DBF) (*DBF) *SYSVAL *COMMA)
    ;--------------------------------------------------------------------------------------
global allRoutines  ; array of class "routine"
global allCode      ; array of source code to show
global tmpRoutine 
global fullFileRoutines, fileRoutines     ; text file with all routine calls, is the output from AS400.
global fullFileCode, fileCode         ; text file with source code.
global path
global itemLevels
global levels_LastIndex
global scriptNameNoExt
global TreeViewWidth, treeviewWidthStep
global ListBoxWidth
global MyTreeView, MyListBox, MyEdit_routine, MyEdit_code
global LVX, LVY,LVWidth, LVHeight
global from_line_number, to_line_number
global gui_offset
global letterColor, fontSize, fontColor

initialize()
mainProcess()
return

mainProcess() {
    setup()
    populateRoutines()
    populateCode()
    loadTreeview()
    updateStatusBar()
    showGui()
}

showGui() {
    global

    SplitPath, A_ScriptFullPath , scriptFileName, scriptDir, scriptExtension, scriptNameNoExt, scriptDrive
    ; read last saved win position & size
    IniRead, valueOfX, %A_ScriptDir%\%scriptNameNoExt%.ini, position, winX
    IniRead, valueOfY, %A_ScriptDir%\%scriptNameNoExt%.ini, position, winY
    IniRead, valueOfWidth, %A_ScriptDir%\%scriptNameNoExt%.ini, position, winWidth
    IniRead, valueOfHeight, %A_ScriptDir%\%scriptNameNoExt%.ini, position, winHeight
    
    IniRead, actualHeight, %A_ScriptDir%\%scriptNameNoExt%.ini, position, actualWinHeight
    gui_offset := actualHeight - valueOfHeight

    if (valueOfX < -7)
        valueOfX := -7
    if (valueOfY < 0)
        valueOfY := 0

    Gui, Show, X%valueOfX% Y%valueOfY% W%valueOfWidth% H%valueOfHeight%, %fileCode%
    return
}

updateStatusBar(currentRoutine := "MAIN") {
    SB_SetText("Routines:" . allRoutines.MaxIndex() . " | Statements:" . allCode.MaxIndex()
    . " | File:" . fileCode . " | Current routine:" . currentRoutine)
}
    ;---------------------------------------
    ; define shortcut keys
    ;---------------------------------------
#IfWinActive ahk_class AutoHotkeyGUI
    global searchText

    ^left::     ;{ <-- decrease treeview
    resizeTreeview("-")
    return

    ^right::    ;{ <-- increase treeview
    resizeTreeview("+")
    return

    F1::        ;{ <-- find next
    GuiControlGet, searchText, ,MyEdit_routine  ;get search text from input field
    searchItemInRoutine(searchText, "next")
    return

    F2::        ;{ <-- find previous
    GuiControlGet, searchText, ,MyEdit_routine  ;get search text from input field
    searchItemInRoutine(searchText, "previous")
    return

    F3::       ;{ <-- fold all routines 
    processAll("-Expand")
    return

    F4::        ;{ <-- unfold all routines 
    processAll("Expand")
    return

    F5::        ;{ <-- fold recursively current routine
    processChildren(TV_GetSelection(), "-Expand")
    return

    F6::        ;{ <-- unfold recursively current routine
    processChildren(TV_GetSelection(), "Expand")
    return

    F7::        ;{ <-- fold same level
    selected_itemID := TV_GetSelection()
    processSameLevel(selected_itemID, "-Expand")
    ; processSameLevel(TV_GetSelection(), "-Expand")
    return

    F8::        ;{ <-- unfold same level
    processSameLevel(TV_GetSelection(), "Expand")
    return

#IfWinActive

    ;------------------------------------------------------------------
    ; get file selection from user, using given path and file filter.
    ; populates global fields: fullFileRoutines, fullFileCode
    ;------------------------------------------------------------------
fileSelector(homePath, filter) {
    FileSelectFile, fullFileRoutines, 1, %homePath% , Select routines file, %filter%
            
    if (ErrorLevel = 1) {    ; cancelled by user
        return False
    }
    
    SplitPath, fullFileRoutines , FileName, Dir, Extension, NameNoExt, Drive
    FoundPos := InStr(FileName, ".cblle.txt" , CaseSensitive:=false)
    if (foundPos > 0) {
        Filename := SubStr(FileName, 1, foundPos-1) . ".txt"
        NameNoExt := SubStr(FileName, 1, foundPos-1)
    }

    fileRoutines := FileName
    fileCode := NameNoExt . ".cblle.txt"
    return true

    ; msgbox, % fileRoutines . "`n" fileCode . "`n" . fullFileRoutines . "`n" . fullFileCode
    ; ExitApp
}
    ;-----------------------------------------------------------
    ; find system script is running.
    ;-----------------------------------------------------------
getSystem() {
    StringLower, user, A_UserName
    if (user = "nu72oa")
        return "SYSTEM_WORK"
    Else
        return "SYSTEM_HOME"
}
    ;--------------------------------------------------
    ; check arguments, check run system, set filename,
    ; move/rename files if needed.
    ; called on first run only!
    ;--------------------------------------------------
initialize() {
    global
    SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
    SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

    params_exist = false
    user := ""
    path := A_ScriptDir . "\data\"
    fileRoutines := ""
    fileCode := ""
    
    ; the global variable scriptNameNoExt is used for accessing the .INI file from multiple places
    ; so it is defined at the beggining.
    SplitPath, A_ScriptFullPath , scriptFileName, scriptDir, scriptExtension, scriptNameNoExt, scriptDrive

    if (A_Args[1] <> "" and A_Args[2] <> "" and A_Args[3] <> ""  and A_Args[4] <> "")
        params_exist = true
    
    user := getSystem()
    
    if (user ="SYSTEM_HOME") {
        ; fileSelector(path, "(*.txt)")
        fileRoutines := "B9Y36.txt"
        fileCode := "B9Y36.cblle.txt"
    }

    if (user = "SYSTEM_WORK") {

        ; use existing files(*NEW/*OLD):
        ;   load the files either from showRoutines.ini or from arguments.

        if (trim(A_Args[4]) = "*NEW" or trim(A_Args[4]) = "*OLD") {

            IniRead, fileRoutines, %A_ScriptDir%\%scriptNameNoExt%.ini, files, fileRoutines
            IniRead, fileCode, %A_ScriptDir%\%scriptNameNoExt%.ini, files, fileCode

            ; routines calls file
            fileRoutines := params_exist ? A_Args[1] : fileRoutines
            ; routines code file
            fileCode := params_exist ? A_Args[2] : fileCode
        }

        ; use existing files(*no):
        ;   move file.txt & file.cblle.txt from ieffect folder to .\data

        if (trim(A_Args[4]) = "*NEW") {
            pathIeffect := parms_exist ? A_Args[3] : "z:\bussup\txt\"
            if (!FileExist(pathIeffect)) {
                msgbox, "Folder " . %pathIeffect% . " doesn't exist. Press enter and select file"
                fileRoutines := ""      ; clear in order next to show file selector!
            } else {
                Progress, zh0 fs10, % "Trying to move file " . pathIeffect . fileRoutines . " to folder " . path
                FileMove, %pathIeffect%%fileRoutines% , %path% , 1
                if (ErrorLevel <> 0) {
                    msgbox, % "Cannot move file " . pathIeffect . fileRoutines . " to folder " . path
                }
                Progress, Off
                Progress, zh0 fs10, % "Trying to move file " . pathIeffect . fileCode . " to folder " . path
                FileMove, %pathIeffect%%fileCode% ,  %path% , 1
                if (ErrorLevel <> 0) {
                    msgbox, % "Cannot move file " . pathIeffect . fileCode . " to folder " . path
                }
                Progress, Off
            }
        }
        
        ; use existing files(*select) or ini file has not corresponding entry: open file selector

        if (A_Args[4] = "*SELECT" or fileRoutines = "") {
            if (!fileSelector(path, "(*.txt)"))
                ExitApp
        }
    }

}
    ;--------------------------------------------
    ; set environment, populate data structures
    ;--------------------------------------------
setup() {
    global
    allRoutines := []
    allCode := []
    tmpRoutine  := {}
    itemLevels := []
    levels_LastIndex := 0
    fullFileRoutines := path . fileRoutines
    fullFileCode := path . fileCode

    ; read last saved values
    IniRead, valueOfHeight, %A_ScriptDir%\%scriptNameNoExt%.ini, position, winHeight
    IniRead, valueOfTreeviewWidth, %A_ScriptDir%\%scriptNameNoExt%.ini, position, treeviewWidth
    IniRead, valueOfFontsize, %A_ScriptDir%\%scriptNameNoExt%.ini, font, size
    IniRead, valueOfFontcolor, %A_ScriptDir%\%scriptNameNoExt%.ini, font, color
    IniRead, valueOfwindow_color, %A_ScriptDir%\%scriptNameNoExt%.ini, backgroundColor, window
    IniRead, valueOfcontrol_color, %A_ScriptDir%\%scriptNameNoExt%.ini, backgroundColor, control

    TreeViewWidth := valueOfTreeviewWidth ; 400
    ListBoxWidth := valueOfHeight - TreeViewWidth - 30    ; 1000 - TreeViewWidth - 30
    LVX := TreeViewWidth + 10
    search2_x := TreeViewWidth + 10

    if (valueOfFontsize >=6 and valueOfFontsize<=20)
        fontSize := valueOfFontsize
    else
        fontSize := 10

    VSCODE_LETTERS := "C4C4C4"
    VSCODE_EDIT_WIN := "232323"
    VSCODE_LEFT_WIN := "2E3132"
    VSCODE_HEAD := "3E3E3E"
    VSCODE_SELECTED_MENUITEM := "114970"

    if (valueOfFontcolor <> "")
        fontColor := valueOfFontcolor
    else
        fontColor := VSCODE_LETTERS

    if (valueOfwindow_color <> "")
        window_color := valueOfwindow_color
    else
        window_color := VSCODE_HEAD
    
    if (valueOfcontrol_color <> "")
        control_color := valueOfcontrol_color
    else
        control_color := VSCODE_EDIT_WIN

    Gui, Font, c%fontColor% s%fontSize%, Courier New
    Gui, Color, %window_color%, %control_color%

    Gui, +Resize +Border
    Gui, Add, Text, x5 y10 , Search for routine:
    Gui, Add, Edit, r1 vMyEdit_routine x+5 y5 w150
    Gui, Add, Text, x%search2_x% y10 , Search inside code:
    Gui, Add, Edit, r1 vMyEdit_code x+5 y5 w150

    Gui, Add, Button, x+1 Hidden Default, OK    ; hidden button to catch enter key! x+1 = show on same line with textbox
    
    Gui, Add, TreeView, vMyTreeView w%TreeViewWidth% r15 x5 gMyTreeView AltSubmit
    ; Gui, Add, TreeView, vMyTreeView r80 w%TreeViewWidth% x5 gMyTreeView AltSubmit ImageList%ImageListID% ; Background%color1% ; x5= 5 pixels left border

    Gui, Add, ListBox, r100 vMyListBox w%ListBoxWidth% x+5, click any routine from the tree to show the code|double click any routine to open in Notepad++
    Gui, add, StatusBar, Background c%control_color%
    ; Gui, add, StatusBar, Background c%window_color%

    Menu, MyContextMenu, Add, Fold all `tF3, contextMenuHandler
    Menu, MyContextMenu, Add, Unfold all `tF4, contextMenuHandler
    Menu, MyContextMenu, Add, Fold recursively `tF5, contextMenuHandler
    Menu, MyContextMenu, Add, Unfold recursively `tF6, contextMenuHandler
    Menu, MyContextMenu, Add, Fold same level `tF7, contextMenuHandler
    Menu, MyContextMenu, Add, Unfold same level `tF8, contextMenuHandler

    ; menu bar
    Menu, FileMenu, Add, &Open file, MenuHandler
    Menu, FileMenu, Icon, &Open file, shell32.dll, 4

    Menu, FileMenu, Add, Save position, MenuHandler
    Menu, FileMenu, Disable, Save position

    Menu, FileMenu, Add, Save tree as..., MenuHandler
    Menu, FileMenu, Icon, Save tree as..., shell32.dll, 259

    Menu, FileMenu, Add, &Exit, MenuHandler
    Menu, FileMenu, Icon, &Exit, shell32.dll, 123

    Menu, SettingsMenu, Add, &Settings, MenuHandler
    Menu, SettingsMenu, Icon, &Settings, shell32.dll, 317

    Menu, MyMenuBar, Add, &File, :FileMenu
    Menu, MyMenuBar, Add, &Settings, :SettingsMenu

    Gui, Menu, MyMenuBar
    Gui, Add, Button, gExit, Exit This Example
    Menu, Tray, Icon, icons\shell32_16806.ico                      ;shell32.dll, 85
    return
}
    ;-----------------------------------------------------------
    ; Handle enter key. 
    ;-----------------------------------------------------------
ButtonOK: 
    {
        GuiControlGet, searchText, ,MyEdit_routine  ;get search text from input field
        if (searchText <> "")
            searchItemInRoutine(searchText, "next")
        else {
            GuiControlGet, searchText, ,MyEdit_code  ;get search text from input field
            if (searchText <> "")
                item = searchItemInCode(searchText, "next")
                GuiControl, Choose, MyListBox, item
        }
        return
    }
    ;-----------------------------------------------------------
    ; Handle user actions (such as clicking). 
    ;-----------------------------------------------------------
MyTreeView:
    {
    global currentRoutine

    ; click an item: load routine code
    if (A_GuiEvent = "S") {
        TV_GetText(SelectedItemText, A_EventInfo)   ; get item text
        loadListbox(SelectedItemText)              ; load routine code
    }
    
    ; doubleclick an item: open code in Notepad++ and position to selected routine.
    if (A_GuiEvent = "DoubleClick") {
        TV_GetText(SelectedItemText, TV_GetSelection())   ; get item text
        statement := findRoutineFirstStatement(SelectedItemText)

        WinGetPos, X_main, Y_main, Width_main, Height_main, A
        actWin := WinExist("A")
        GetClientSize(actWin, Width_main, Height_main)

        RunWait, notepad++.exe -lcobol -nosession -ro -n%statement% "%fullFileCode%"
        ; RunWait, runNotepad.bat "%fullFileCode%", A_WorkingDir

        Sleep, 100
        ; position besides main window
        WinMove, ahk_class Notepad++, , X_main + Width_main , Y_main
    }

    ; spacebar an item: load the routine code.
    if (A_GuiEvent = "K" and A_EventInfo = 32) {
        ; msgbox, % "[" A_EventInfo "]"   ; A_EventInfo contains the ascii character as number
    }

    return
    }

GuiSize:  ; Expand/shrink the ListBox and TreeView in response to user's resizing of window.
    {
    if (A_EventInfo = 1)  ; The window has been minimized. No action needed.
        return

    ; Otherwise, the window has been resized or maximized. Resize the controls to match.
    GuiControl, Move, MyTreeView, % "H" . (A_GuiHeight - gui_offset) . " W" . TreeViewWidth ; -30 for StatusBar and margins.
    
    GuiControl, Move, MyListBox, % "X" . LVX . " H" . (A_GuiHeight - gui_offset + 10) . " W" . (A_GuiWidth - TreeViewWidth - 15) ; width = total - treeview - (3 X 5) margins.
    ; GuiControl, Move, MyListBox, % "X" . LVX . " H" . (A_GuiHeight - 30) . " W" . (A_GuiWidth - TreeViewWidth - 15) ; width = total - treeview - (3 X 5) margins.

    return
    }
    ;----------------------------------------------------------------
    ; Launched in response to a right-click or press of the Apps key.
    ;----------------------------------------------------------------
GuiContextMenu:
    {
    if (A_GuiControl <> "MyTreeView")  ; This check is optional. It displays the menu only for clicks inside the TreeView.
        return
    ; Show the menu at the provided coordinates, A_GuiX and A_GuiY. These should be used
    ; because they provide correct coordinates even if the user pressed the Apps key:
    Menu, MyContextMenu, Show, %A_GuiX%, %A_GuiY%
    return
    }

    ;----------------------------------------------------------------
    ; on app close save to INI file last position & size.
    ;----------------------------------------------------------------
GuiClose:  ; Exit the script when the user closes the TreeView's GUI window.
    
    if (fileRoutines = "ERROR")
        return
    if (fileCode = "ERROR")
        return

    ; on exit save position & size of window
    ; but if it is minimized skip this step.
    actWin := WinExist("A")
    WinGet, isMinimized , MinMax, actWin
    if (isMinimized <> -1) {
        WinGetPos, winX, winY, winWidth, winHeight, A

        ; save X, Y that are absolute values.
        IniWrite, %winX%, %A_ScriptDir%\%scriptNameNoExt%.ini, position, winX
        IniWrite, %winY%, %A_ScriptDir%\%scriptNameNoExt%.ini, position, winY
        
        ; save absolute values of W,H.
        IniWrite, %winWidth%, %A_ScriptDir%\%scriptNameNoExt%.ini, position, actualWinWidth
        IniWrite, %winHeight%, %A_ScriptDir%\%scriptNameNoExt%.ini, position, actualWinHeight

        GetClientSize(actWin, winWidth, winHeight)
        
        ; save client values of W,H (used by winmove)
        IniWrite, %winWidth%, %A_ScriptDir%\%scriptNameNoExt%.ini, position, winWidth
        IniWrite, %winHeight%, %A_ScriptDir%\%scriptNameNoExt%.ini, position, winHeight
    }

    if (treeviewWidth > 0)
        IniWrite, %treeviewWidth%, %A_ScriptDir%\%scriptNameNoExt%.ini, position, treeviewWidth

    if (fontSize > 0)
        IniWrite, %fontSize%, %A_ScriptDir%\%scriptNameNoExt%.ini, font, size

    ; if filenames are non blank save also.
    if (fileRoutines <> "")
        IniWrite, %fileRoutines%, %A_ScriptDir%\%scriptNameNoExt%.ini, files, fileRoutines
    if (fileCode <> "")
        IniWrite, %fileCode%, %A_ScriptDir%\%scriptNameNoExt%.ini, files, fileCode
    
    ExitApp

GetClientSize(hWnd, ByRef w := "", ByRef h := "")
    {
    VarSetCapacity(rect, 16)
    DllCall("GetClientRect", "ptr", hWnd, "ptr", &rect)
    w := NumGet(rect, 8, "int")
    h := NumGet(rect, 12, "int")
    }

    ;-----------------------------------------------------------
    ; Handle menu bar actions
    ;-----------------------------------------------------------
MenuHandler:
    if (A_ThisMenuItem = "&Open file") {
        if (!fileSelector(path, "(*.txt)"))
            return
        Gui, Destroy
        mainProcess()
        return
    }
    if (A_ThisMenuItem = "&Settings") {
        showSettings()
        return
    }
    if (A_ThisMenuItem = "&Exit") {
        Gui, Destroy
        ExitApp
    }

    return

    Exit:
    ExitApp

    ;-----------------------------------------------------------
    ; Handle context menu actions
    ;-----------------------------------------------------------
contextMenuHandler:

    if (A_ThisMenuItem = "Show routine code `tLeft click") {
        ; doesn't work!!!
        ; TV_GetText(SelectedItemText, TV_GetSelection())   ; get item text
        ; msgbox, % SelectedItemText . "----" . TV_GetSelection()
        ; loadListbox(SelectedItemText)              ; load routine code
    }
    if (A_ThisMenuItem = "Find next `tF1") {
        ; doesn't work!!!
        ; TV_GetText(SelectedItemText, TV_GetSelection())   ; get item text
        ; GuiControl, , MyEdit_routine , %SelectedItemText%   ; put it into search field
        ; searchItemInRoutine(searchText, "next")

        ; TV_GetText(SelectedItemText, A_EventInfo)   ; get item text
        ; msgbox, % SelectedItemText . "-----" . A_EventInfo
        ; GuiControl, , MyEdit_routine , %SelectedItemText%   ; put it into search field
        ; searchItemInRoutine(searchText, "next")
    }
    if (A_ThisMenuItem = "Find previous `tF2") {
        ; doesn't work!!!
        ; TV_GetText(SelectedItemText, A_EventInfo)   ; get item text
        ; GuiControl, , MyEdit_routine , %SelectedItemText%   ; put it into search field
        ; searchItemInRoutine(searchText, "previous")
        ; return
    }

    if (A_ThisMenuItem = "Fold all (F3)")
        processAll("-Expand")
    if (A_ThisMenuItem = "Unfold all (F4)")
        processAll("Expand")
    if (A_ThisMenuItem = "Fold recursively (F5)")
        processChildren(TV_GetSelection(), "-Expand")
    if (A_ThisMenuItem = "Unfold recursively (F6)")
        processChildren(TV_GetSelection(), "Expand")
    if (A_ThisMenuItem = "Fold same level (F7)")
        processSameLevel(TV_GetSelection(), "-Expand")
    if (A_ThisMenuItem = "Unfold same level (F8)")
        processSameLevel(TV_GetSelection(), "Expand")
    return
    ;--------------------------------------------
    ; show 2nd window with editable settings
    ;--------------------------------------------
showSettings() {
    static font_size, font_color, tree_step, window_color, control_color
    win_title := "Settings"

    IniRead, font_size, showRoutines.ini, font, size
    IniRead, font_color, showRoutines.ini, font, color
    IniRead, tree_step, showRoutines.ini, position, treeviewWidthStep
    IniRead, window_color, showRoutines.ini, backgroundColor, window
    IniRead, control_color, showRoutines.ini, backgroundColor, control

    if (WinExist(win_title))
        Gui, 2:Destroy

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
    Gui, 2:Add, Button, x160 y200 w80 default, Cancel
    Gui, 2:Add, Button, x250 y200 w80, Default

    show:
        Gui 2:+Resize -SysMenu +ToolWindow
        Gui 2:Show, x300 y540 w400 h250, %win_title%
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

            Goto, 2GuiClose
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

        Gui, 2:Destroy
        Goto, Loop
    }

    2GuiEscape:
        ;Reload

    2GuiClose:
    2ButtonCancel:
        Gui, 2:Destroy
        Return
}
    ;--------------------------------------------
    ; resize when ctrl+left or ctrl+right pressed
    ;--------------------------------------------
resizeTreeview(type) {
    global
    WinGetPos, winX, winY, winWidth, winHeight
    IniRead, treeviewWidthStep, %A_ScriptDir%\%scriptNameNoExt%.ini, position, treeviewWidthStep
    
    ControlGetPos, X, Y, Width, Height, SysTreeView321
    ControlGetPos, LVX, LVY, LVWidth, LVHeight, ListBox1

    ; msgbox, % "winWidth=" winWidth "`tWidth=" Width ; 1006

    if (type="+") {
        winWidth += treeviewWidthStep
        TreeViewWidth += treeviewWidthStep
    }
    if (type="-") {
        winWidth -= treeviewWidthStep
        TreeViewWidth -= treeviewWidthStep
    }

    LVX := TreeViewWidth + 10
    WinMove, , , , , %winWidth%

    return
}
    ;-----------------------------------------------------------
    ; hide/show all nodes.
    ;-----------------------------------------------------------
processAll(mode) {
    GuiControl, -Redraw, MyTreeView
    selectedItemId := TV_GetSelection()   ;get selected item
    ItemID := 0  ; Causes the loop's first iteration to start the search at the top of the tree.

    Loop
    {
        ;https://autohotkey.com/docs/commands/TreeView.htm#TV_GetNext
        ItemID := TV_GetNext(ItemID, "F")  ; Replace "F" with "Checked" to find all checkmarked items.
        if not ItemID  ; No more items in tree.
            break
        TV_Modify(ItemID, mode)
    }

    GuiControl, +Redraw, MyTreeView
    TV_Modify(selectedItemId, VisFirst)     ;re-select old item & make it visible!
}
    ;-----------------------------------------------------------
    ; hide/show all children nodes.
    ;-----------------------------------------------------------
processChildren(currentItemID, mode) {
    current_index := 0
    from_index := 0
    GuiControl, -Redraw, MyTreeView
    selectedItemId := TV_GetSelection()   ;get selected item

    Loop {
        current_index += 1
        
        if (current_index > levels_LastIndex)    ; if end of array items, exit
            Break
        
        if (itemLevels[current_index,1] = currentItemID)
        {
            from_index := current_index
            TV_Modify(itemLevels[current_index, 1], mode)
        }

        ; find first item with level <= selected item level (parent, sibling, other)
        if ((from_index > 0) and (current_index > from_index) and (itemLevels[current_index,2] <= itemLevels[from_index,2]))
            break
        
        if (from_index > 0)
            TV_Modify(itemLevels[current_index, 1], mode)
    }

    
    GuiControl, +Redraw, MyTreeView
    TV_Modify(selectedItemId, VisFirst)     ;re-select old item
}
    ;-----------------------------------------------------------
    ; hide/show all nodes with same level as selected node.
    ;-----------------------------------------------------------
processSameLevel(currentItemID, mode) {
    current_index := 0
    selected_index := 0
    selected_level := 0
    GuiControl, -Redraw, MyTreeView
    selectedItemId := TV_GetSelection()   ;get selected item

    ; find level of selected item.
    Loop {
        current_index += 1
        
        if (current_index > levels_LastIndex)    ; if end of array items, exit
            Break
        
        ; find same id to get level.
        if (itemLevels[current_index, 1] = currentItemID) {
            selected_index := current_index
            selected_level := itemLevels[current_index, 2]
            break
        }
    }

    current_index := 0
    ; find all nodes with same level and fold/unfold.
    Loop {
        current_index += 1
        
        if (current_index > levels_LastIndex)    ; if end of array items, exit
            Break
        
        ; find same id to get level.
        if (itemLevels[current_index, 2] = selected_level) {
            TV_Modify(itemLevels[current_index, 1], mode)
        }
    }

    GuiControl, +Redraw, MyTreeView

    TV_Modify(selectedItemId, VisFirst)     ;re-select old item & make it visible!
}
    ;-----------------------------------------------------------
    ; search the text entered in MyEdit_routine control
    ;-----------------------------------------------------------
searchItemInRoutine(searchText, direction) {

    global
    static found := false

    ; if no search term: return
    if (trim(searchText) = "") {
        ; ControlFocus, Edit1     ;focus on search input field
        return
    }

    ControlFocus, SysTreeView321        ;focus on treeview

    current_index := 0
    selected_index := 0
    selectedItemId := TV_GetSelection()   ;get selected item id
    if (selectedItemId = 0)
        selectedItemId := itemLevels[1, 1]

    ; find selected item index
    Loop {
        current_index += 1
        if (current_index > levels_LastIndex)    ; if end of array items, exit
            Break    
        ; find same id to get index.
        if (itemLevels[current_index, 1] = selectedItemId) {
            selected_index := current_index
            break
        }        
    }

    if (selected_index = 0)     ; not found in array
        return

    Loop {
        if (direction = "next") {
            current_index += 1
            if (current_index > levels_LastIndex) {   ; if end of array items, exit
                current_index := 1
                if (found = false) {
                    msgbox, end of search
                    Break
                }
            }
        } else {
            current_index -= 1
            if (current_index < 1) {   ; if begin of array items, exit
                current_index := levels_LastIndex
                if (found = false) {
                    msgbox, end of search
                    Break
                }
            }           
        }
        ; check if search text exists in current node.
        foundPos := InStr(itemLevels[current_index, 3], searchText, CaseSensitive:=false, 1)
        if (foundPos > 0) {
            TV_Modify(itemLevels[current_index, 1])     ;select found node
            found := true
            break
        }        
    }
}
    ;-----------------------------------------------------------
    ; search the text entered in MyEdit_code control
    ;-----------------------------------------------------------
searchItemInCode(searchText, direction) {
    line_number := from_line_number
    itemNumber := 1

    while (line_number <= to_line_number) {
        FoundPos := InStr(allcode[line_number], searchText, CaseSensitive:=false)
        if (foundPos > 0) {
            ; msgbox, % "Found"
            ; Control, Choose, itemNumber, MyListBox
            ; ControlFocus, MyListBox
            ; GuiControl, Choose, MyListBox, itemNumber
            ; GuiControl, +Redraw, MyListBox
            return itemNumber
        }
        line_number ++
        itemNumber ++
    }
    return 0
    ; msgbox, % "Not found"
}
    ;---------------------------------------------------------------------
    ; recursively write routines array to a text file for testing.
    ;---------------------------------------------------------------------
    ; 1. process 1st item (MAIN)
    ;       1.1. write caller as parent node
    ;       1.2. for each called:
    ;           1.2.1. find called in routines array
    ;           1.2.2. make above called parent
    ;           1.2.3. goto 1.1
    ;
    ; 2. iterate (recursively) through array items with caller=MAIN until all processed:
    ; 3. create a parent node for each caller routine.
    ; 4. add a child node for each called routine.
    ;       repeat 5 until no called routine found.
    ; 5. repeat 1.
    ;---------------------------------------------------------------------
loadTreeview() {
    if (allRoutines.MaxIndex() <= 0)    ; no called routines
        return

    ; first item is always = "MAIN" (the parent routine of all)
    currRoutine := allRoutines[1]
    processRoutine(currRoutine)
}
    ;---------------------------------------------------------------------
    ; recursively write routines array to a text file for testing.
    ; currRoutine = item in allRoutines[]
    ; parentID = the parent node (in a treeview)
    ;---------------------------------------------------------------------
processRoutine(currRoutine, parentID=0) {
    static currentLevel
    currentLevel ++

    itemId := addToTreeview(currRoutine.routineName, currentLevel, parentID)

    ; itemId := TV_Add(currRoutine.routineName, parentID, "Icon4 Expand")
    ; itemId := TV_Add(currRoutine.routineName "(" . currentLevel . ")", parentID, "Icon4 Expand")

    Loop, % currRoutine.calls.MaxIndex() {

        ; search array allRoutines[] for the current routine item.
        calledId := searchRoutine(currRoutine.calls[A_Index])
        if (calledId > 0) {
            processRoutine(allRoutines[calledId], itemId)     ; write children
        }
    }
    currentLevel --
}
    ;---------------------------------------
    ; add a node to treeview
    ;---------------------------------------
addToTreeview(routineName, currentLevel, parentRoutine) {
    currentId := TV_add(routineName, parentRoutine, "Expand")
    ; currentId := TV_add(routineName, parentRoutine, "Icon138 Expand")
    ; currentId := TV_add(routineName, parentRoutine, "Icon4 Expand")
    
    ; save routine level for later tree traversal.
    levels_LastIndex += 1
    itemLevels[levels_LastIndex, 1] := currentId
    itemLevels[levels_LastIndex, 2] := currentLevel
    itemLevels[levels_LastIndex, 3] := routineName

    return currentId
}
    ;---------------------------------------------------------------------
    ; search if parameter exists in allRoutines array.
    ;---------------------------------------------------------------------
searchRoutine(routineName) {
    Loop, % allRoutines.MaxIndex() {
        if (routineName = allRoutines[A_Index].routineName) {
            return A_index
        }
    }
    return 0
}
    ;-----------------------------------------------------------------------
    ; read mpmdl001.cblle file and populate array with all code
    ;-----------------------------------------------------------------------
populateCode() {
    Loop, Read, %fullFileCode%
    {
        allCode.push(A_LoopReadLine)
    }
}
    ;-----------------------------------------------------------------------
    ; find the statement in the code that routine begins.
    ;-----------------------------------------------------------------------
findRoutineFirstStatement(routineName) {
    from_line_number := 1
    
    if (routineName <> "") {
        calledId := searchRoutine(routineName)
        if (calledId > 0)
            from_line_number := substr(allRoutines[calledId].startStmt, 1, 4)
    }
    
    return from_line_number
}
    ;-----------------------------------------------------------------------
    ; load listbox with the routine code (source)
    ;-----------------------------------------------------------------------
loadListbox(routineName) {
    global
    from_line_number := 0
    to_line_number := 0
    sourceCode := ""
    
    calledId := searchRoutine(routineName)
    if (calledId > 0) {
        from_line_number := substr(allRoutines[calledId].startStmt, 1, 4)
        to_line_number := substr(allRoutines[calledId].endStmt, 1, 4)
    } else {
        from_line_number := 3103
        to_line_number := 3117
    }

    line_number := from_line_number
    while (line_number <= to_line_number) {
        sourceCode .= allcode[line_number] . "|"
        line_number ++
    }

    updateStatusBar(SelectedItemText)
    GuiControl, -Redraw, MyListBox
    GuiControl,,MyListBox, |
    GuiControl,,MyListBox, %sourceCode%
    GuiControl, +Redraw, MyListBox
}
    ;-------------------------------------------------------
    ; read cbtreef5.txt file and populate routines array
    ;-------------------------------------------------------
populateRoutines() {
    Loop, Read, %fullFileRoutines%
    {
        tmpRoutine := parseLine(A_LoopReadLine)     ; parse line into separate fields.

        if (trim(tmpRoutine.IDNUM) = "")     ; if blank ignore line
            continue
        
        caller := searchRoutine(tmpRoutine.ROUCALLER)      ; check if caller routine is already saved in array

        ; if caller routine doesn't exist create it.
        if (caller = 0)
            createRoutineItem(tmpRoutine)

        ; if caller routine exists: add the new called routine to the array of called routines.
        else {
            if (!updateRoutineItem(caller, tmpRoutine))     
                msgbox, % "Failed to update called routine " . tmpRoutine.ROUCALLED
        }

        ; break
    }
}
    ;---------------------------------------------------------------------
    ; creates an array item with the caller and called routine.
    ;---------------------------------------------------------------------
createRoutineItem(tmpRoutine) {
    routine1 := new routine

    routine1.routineName    := tmpRoutine.ROUCALLER
    ;routine1.routineName    := tmpRoutine.ROUCALLED
    ;routine1.calledBy       := tmpRoutine.ROUCALLER
    routine1.startStmt      := tmpRoutine.STMFIRST
    routine1.endStmt        := tmpRoutine.STMLAST
    routine1.callingStmt    := tmpRoutine.STMCALL
    routine1.calls          := []
    
    ; add called routine only when exists
    ; (in case of routine without calls the array of called routines remains blank)
    if (tmpRoutine.ROUCALLED <> "")
        routine1.calls.push(tmpRoutine.ROUCALLED)

    allRoutines.push(routine1)
}
    ;---------------------------------------------------------------------
    ; creates an array item with the caller and called routine.
    ;---------------------------------------------------------------------
updateRoutineItem(caller, tmpRoutine) {
    if (caller = 0) or (caller > allRoutines.MaxIndex())
        return False
    
    allRoutines[caller].calls.push(tmpRoutine.ROUCALLED)
    return True
}
    ;---------------------------------------------------------------------
    ; parse line into separate fields.
    ;---------------------------------------------------------------------
parseLine(inputLine) {
    array1      := StrSplit(inputLine, ",")
    tmpRoutine  := {}
    tmpRoutine.IDNUM       := trim(array1[1])
    tmpRoutine.STMFIRST    := trim(array1[2])
    tmpRoutine.STMLAST     := trim(array1[3])
    tmpRoutine.STMCALL     := trim(array1[4])
    tmpRoutine.ROUCALLER   := trim(array1[5])
    tmpRoutine.ROUCALLED   := trim(array1[6])
    return tmpRoutine
}
    ;---------------------------------------------------------------------
    ; routines data model.
    ;---------------------------------------------------------------------
class routine {
    routineName := ""
    calledBy := ""
    startStmt := ""
    endStmt := ""
    callingStmt := ""
    calls := []
}