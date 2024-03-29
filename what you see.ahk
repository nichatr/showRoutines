; initial declarations
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
  ;   A_Args[2] = source code file   = outfile.cbl
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
  global currThread ; keeps all routines in the current thread in order to avoid circular dependencies
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
  global exportedRoutines, exportDescriptions
  global MaxLevel, includeDescriptions, MyRadioGroup, ExportedFilename
  global winX, winY ; main window position
  global winWidth, winHeight ; main window size
  global LVX, LVY,LVWidth, LVHeight
  global from_line_number, to_line_number
  global gui_offset, gui_height, gui_width
  global letterColor, fontSize, fontColor, codeEditor
  global subGui2_W, subGui2_H
  global subGui3_W, subGui3_H
  global subGui4_W, subGui4_H
  global gCurrentLevel   ; holds the fold level or 0 if none.
  global targetX, targetY, targetWidth, targetHeight  ; main window coordinates
  global ExportSelected, nodesToExport, ExportWhatYouSee

initialize()
mainProcess()
  return

mainProcess() {
  setup()
  populateRoutines()
  populateCode()
  loadTreeview()
  saveRoutines(".\data\allRoutines.txt", header, true)
  updateStatusBar()
  showGui()
  }

showGui() {
  global
	OnMessage(0x232, "Move_window") ; to move children guis with the parent
  processLevel(2)
  updateStatusbar()
  Gui, 1:Show, X%winX% Y%winY% W%winWidth% H%winHeight%, %fileCode%
  return
  }
  ;---------------------------------------------------------------------
  ; show help window
  ;---------------------------------------------------------------------
showHelp() {
  Gui, 2:Destroy
  subGui2_W := 420
  subGui2_H := 220
  WinGetPos, targetX, targetY, targetWidth, targetHeight, A
  newX := targetX + (targetWidth - subGui2_W) / 2
  newY := targetY + (targetHeight - subGui2_H) / 2

  Gui, 2:+AlwaysOnTop -Caption +Owner1
  Gui, 2:Add,GroupBox,xm+5 y+20 w%subGui2_W% h%subGui2_H%, Function keys
  Gui, 2:Add,Text,xm+10 yp+20 w400,
    (
      
    F1 = show help 
    F2 = export tree 

    F3/F4 = fold/unfold all 
    F5/F6 = fold/unfold current node recursively 
    F7/F8 = fold/unfold current level
    shift F1..F12 = fold level 2..13

    F9/F10 = search next/previous
    F11 = toggle bookmark for export

    ctrl right cursor = increase tree width
    ctrl left cursor = decrease tree width

    )
  Gui, 2:Add, button, xm+10 y+20 g2Close,Close
  Gui, 2:show, x%newX% y%newY%, Gui 2
  HWND_GUI2 := WinExist(A)
  return
  }
2Escape:
2GuiEscape:
2Close:
  Gui, 2:Destroy
  return
  ;---------------------------------------------------------------------
  ; show export window
  ;---------------------------------------------------------------------
showExport() {
  inputFilename := fileRoutines
  outputFormat := "txt"

  Gui, 3:Destroy
  global subGui3_W, subGui3_H

  subGui3_W := 420
  subGui3_H := 180
  WinGetPos, targetX, targetY, targetWidth, targetHeight, A
  newX := targetX + (targetWidth - subGui3_W) / 2
  newY := targetY + (targetHeight - subGui3_H) / 2

  Gui, 3:+AlwaysOnTop -Caption +Owner1
  Gui, 3:Add,GroupBox,xm+5 y+10 w%subGui3_W% h%subGui3_H%, Export
  
  ; filename
  Gui, 3:Add,Text,xm+20 yp+40, Exported filename
  Gui, 3:Add,Edit, vExportedFilename xp+90 yp-5 w300, exported_%inputFilename%
  ; Gui, 3:Add,Edit, vExportedFilename xp+90 yp-5 w300, %scriptDir%\data\%inputFilename%

  ; max level
  Gui, 3:Add,Text,xm+20 yp+35, Max level to export
  Gui, 3:Add,Edit, vMaxLevel xp+100 yp-5 w40 +Number
  Gui, 3:Add, UpDown, Range2-999, 999

  ; include descriptions?
  Checked1 := exportDescriptions == "true" ? "Checked" : ""
  Gui, 3:Add, Checkbox, vincludeDescriptions g3IncludeDescriptions xm+20 yp+35 %Checked1% ,   Include routines descriptions

  ; output format
  Gui, 3:Add, Text, xm+20 yp+30, Output format
  Gui, 3:Add, Radio, Group g3Check vMyRadioGroup Checked xp+80 yp, txt
  Gui, 3:Add, Radio, g3Check xp+50 yp, json
  Gui, 3:Add, Radio, g3Check xp+50 yp, xml

  ; Export, Close buttons
  Gui, 3:Add, button, xm+60 ym+190 w50 g3ExportAll, All
  Gui, 3:Add, button, xp+50 ym+190 w50 g3ExportSelected vExportSelected, Selected
  Gui, 3:Add, button, xp+50 ym+190 w80 g3ExportWhatYouSee vExportWhatYouSee, What you see
  Gui, 3:Add, button, xp+130 g3Close, Close

  if (nodesToExport.MaxIndex()>0)
    GuiControl, 3:Enable, ExportSelected
  else
    GuiControl, 3:Disable, ExportSelected

  ; show window
  Gui, 3:show, x%newX% y%newY%, Gui 3
  HWND_GUI3 := WinExist(A)
  return
  }

  ;---------------------------------------------------------------------
  ; checkbox <include descriptions> handler
  ;---------------------------------------------------------------------
3IncludeDescriptions:
  Gui, 3:Submit, NoHide

  if (includeDescriptions = 1)  ; checked
    exportDescriptions := "true"
  else
    exportDescriptions := "false"
  return

  ;---------------------------------------------------------------------
  ; radiogroup <exrpot type> handler
  ;---------------------------------------------------------------------
3Check:
  Gui, 3:Submit, NoHide

  if (MyRadioGroup = 1)
    outputFormat := "txt"
    outputFormat := "txt"

  if (MyRadioGroup = 2)
    outputFormat := "json"
  if (MyRadioGroup = 3)
    outputFormat := "xml"
  Return

  ;---------------------------------------------------------------------
  ; button <All> handler
  ;---------------------------------------------------------------------
3ExportAll:
  Gui, 3:Submit, NoHide
  if (MaxLevel < 2 or MaxLevel > 999) {
    MsgBox, max level must be between 2 and 999
    return
  }
  if (trim(ExportedFilename) = "") {
    MsgBox, filename cannot be empty
    return
  }

  exportedString := exportTreeview()
  saveExportedString(exportedString)
  goto 3Close

  ;---------------------------------------------------------------------
  ; button <Selected> handler
  ;---------------------------------------------------------------------
3ExportSelected:
  Gui, 3:Submit, NoHide
  exportedString := exportNodes()
  saveExportedString(exportedString)
  goto 3Close

  ;---------------------------------------------------------------------
  ; button <WhatYouSee> handler
  ;---------------------------------------------------------------------
3ExportWhatYouSee:
  Gui, 3:Submit, NoHide
  Gui, 1:Default  ; necessary to use the TV_* functions on the gui 1 treeview!
  exportedString := exportWhatYouSee()
  saveExportedString(exportedString)
  goto 3Close

  ;---------------------------------------------------------------------
  ; <close> handler
  ;---------------------------------------------------------------------
3Escape:
3GuiEscape:
3Close:
  Gui, 3:Destroy
  return
  ;---------------------------------------------------------------------
  ; save created export into file and open it.
  ;---------------------------------------------------------------------
saveExportedString(exportedString) {
  if (exportedString <> "") {
    filename := ".\data\" . ExportedFilename
    if FileExist(filename)
      FileDelete, %filename%
    FileAppend, %exportedString%, %filename%
    openNotepad(filename)
  } else
    MsgBox, No bookmark to export.
}

 ;--------------------------------------------
  ; show window with editable settings
  ;--------------------------------------------
showSettings() {
	static font_size, font_color, tree_step, window_color, control_color, showOnlyRoutine, showOnlyRoutineFlag, MyRadioGroup, checked1, checked2
	win_title := "Settings"
	
	IniRead, font_size, showRoutines.ini, font, size
	IniRead, font_color, showRoutines.ini, font, color
	IniRead, tree_step, showRoutines.ini, position, treeviewWidthStep
	IniRead, window_color, showRoutines.ini, backgroundColor, window
	IniRead, control_color, showRoutines.ini, backgroundColor, control
	IniRead, showOnlyRoutine, showRoutines.ini, general, showOnlyRoutine
	
	IniRead, codeEditor, showRoutines.ini, general, codeEditor
	if (codeEditor == "code") {
		checked1 := "checked1"
		checked2 := "checked0"
	} else {
		checked1 := "checked0"
		checked2 := "checked1"
	}
	
	if (WinExist(win_title))
		Gui, 4:Destroy
	
	Loop:
    ;------
    ; Font
    ;------
  Gui, 4:Add, GroupBox, x+5 y+10 w160 h100 , Font
	
	Gui, 4:Add, Text, xm+20 ym+40 +0x200, Size
	Gui, 4:Add, Edit, vfont_size xm+50 ym+35 w40 +Number, %font_size%
	Gui, 4:Add, UpDown, Range7-20, %font_size%
	
	Gui, 4:Add, Text, xm+20 ym+70 w60 +0x200, Color
	Gui, 4:Add, Edit, vfont_color xm+50 ym+65 w50, %font_color%
	
	Gui, 4:Add, Progress, w25 h20 xs110 ys61 c%font_color%, 100
	
    ;-----------------
    ; background color
    ;-----------------
	Gui, 4:Add, GroupBox, w170 h100 x+50 ys section, Background Color
	
	Gui, 4:Add, Text, w50 xs15 ys36 +0x200, Window
	Gui, 4:Add, Edit, vwindow_color w50 xs60 ys31, %window_color%
	Gui, 4:Add, Progress, w25 h20 xs120 ys31 c%window_color%, 100
	
	Gui, 4:Add, Text, w50 xs15 ys66 +0x200, Controls
	Gui, 4:Add, Edit, vcontrol_color w50 xs60 ys61, %control_color%
	Gui, 4:Add, Progress, w25 h20 xs120 ys61 c%control_color%, 100
	
    ;-----------------
    ; other settings
    ;-----------------
	Gui, 4:Add, Text,  xm+5 yp+60 +0x200 section, Tree width +/-
	Gui, 4:Add, Edit, vtree_step w50 xp+80 yp-5 +Number, %tree_step%
	Gui, 4:Add, UpDown, Range10-200, %tree_step%
	
	Gui, 4:Add, Text, xm+5 yp+40, Code editor
	Gui, 4:Add, Radio, Group g4check vMyRadioGroup %checked1% xp+80 yp, vscode
	Gui, 4:Add, Radio, g4check %checked2% xp+70 yp, notepad++
	
	checked := showOnlyRoutine == "false" ? "" : "Checked"
	Gui, 4:Add, Checkbox, vshowOnlyRoutineFlag %checked% xs200 ys, Show only selected routine
	
    ;---------------------------------------------
    ; buttons to save, cancel, load default values
    ;---------------------------------------------
	Gui, 4:Add, Button, x70 y220 w80, Save
	Gui, 4:Add, Button, x160 y220 w80 default, Cancel
	Gui, 4:Add, Button, x250 y220 w80, Default
	
	4show:
	Gui, 4:+AlwaysOnTop -Caption +Owner1
  ; Gui, 4:+Resize -SysMenu +ToolWindow
	showSubGui(400, 250, win_title)
	Return
	
	4Check:
	gui, 4:submit, nohide
        ; GuiControlGet, MyRadioGroup
	if (MyRadioGroup = 1)
		codeEditor := "code"
	if (MyRadioGroup = 2)
		codeEditor := "notepad++"
	Return
	
	4ButtonSave:
	Gui, 4:Submit, NoHide
	
	if (font_size < 7 or font_size > 20) {
		msgbox, % "Font size must be between 6 and 20"
		Goto, 4show
	} else
		
	if (tree_step < 10 or tree_step > 200) {
		msgbox, % "Step must be between 10 and 200"
		Goto, 4show
	} else {
		Progress, zh0 fs10, % "Settings saved"
            ; Sleep, 200
		Progress, off
		
		IniWrite, %font_size%, showRoutines.ini, font, size
		IniWrite, %font_color%, showRoutines.ini, font, color
		if (tree_step > 0)
			IniWrite, %tree_step%, showRoutines.ini, position, treeviewWidthStep
		IniWrite, %window_color%, showRoutines.ini, backgroundColor, window
		IniWrite, %control_color%, showRoutines.ini, backgroundColor, control
		
		showOnlyRoutine := showOnlyRoutineFlag ? "true" : "false"
		IniWrite, %showOnlyRoutine%, showRoutines.ini, general, showOnlyRoutine
		
		IniWrite, %codeEditor%, showRoutines.ini, general, codeEditor
		
		Goto, 4GuiClose
	}
	
	Goto, 4show
	
        ; Load the default values (again from ini file).
	4ButtonDefault:
	{
		IniRead, treeviewWidth, showRoutines.ini, default, treeviewWidth
		IniRead, font_size, showRoutines.ini, default, fontsize
		IniRead, font_color, showRoutines.ini, default, fontcolor
		IniRead, tree_step, showRoutines.ini, default, treeviewWidthStep
		IniRead, window_color, showRoutines.ini, default, windowcolor
		IniRead, control_color, showRoutines.ini, default, controlcolor
		IniRead, codeEditor, showRoutines.ini, default, codeEditor
		
		Gui, 4:Destroy
		Goto, Loop
	}
	
	4GuiEscape:
        ;Reload
	
	4GuiClose:
	4ButtonCancel:
	Gui, 4:Destroy
	Return
  }

  ;--------------------------------------------
  ; show window with editable settings
  ;--------------------------------------------
showSubGui(subGui_W, subGui_H, subGui_Title) {
	WinGetPos, targetX, targetY, targetWidth, targetHeight, A
	newX := targetX + (targetWidth - subGui_W) / 2
	newY := targetY + (targetHeight - subGui_H) / 2
  subGui4_W := subGui_W
  subGui4_H := subGui_H
	Gui, 4:Show, x%newX% y%newY% w%subGui_W% h%subGui_H%, Gui 4 ; %subGui_Title%
  }
  ;---------------------------------------------------------------------
  ; open exported routines in editor beside main window
  ;---------------------------------------------------------------------
openNotepad(filename) {
  x := targetX + targetWidth - 10
  y := targetY
  RunWait, notepad++.exe -nosession -ro  -x%x% -y%y% "%filename%"
  }
  ;---------------------------------------------------------------------
  ; move secondary windows
  ;---------------------------------------------------------------------
Move_window() {
  global
  IfWinExist, Gui 2 
    {
    WinGetPos, targetX, targetY, targetWidth, targetHeight, A
    newX := targetX + (targetWidth - subGui2_W) / 2
    newY := targetY + (targetHeight - subGui2_H) / 2
    Gui, 2:show, x%newX% y%newY%, Gui 2
    }
  
  IfWinExist, Gui 3 
    {
    WinGetPos, targetX, targetY, targetWidth, targetHeight, A
    newX := targetX + (targetWidth - subGui3_W) / 2
    newY := targetY + (targetHeight - subGui3_H) / 2
    Gui, 3:show, x%newX% y%newY%, Gui 3
    }
  
  IfWinExist, Gui 4 
    {
    WinGetPos, targetX, targetY, targetWidth, targetHeight, A
    newX := targetX + (targetWidth - subGui4_W) / 2
    newY := targetY + (targetHeight - subGui4_H) / 2
    Gui, 4:show, x%newX% y%newY%, Gui 4
    }
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
	
    ; set default filenames when run from my home.
	if (user ="SYSTEM_HOME") {
    ; fileSelector(path, "(*.txt)")
		fileRoutines := "B9Y36.txt"
		fileCode := "B9Y36.cbl"
	}
	
  ; otherwise get filenames from params.
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
    ;   move file.txt & file.cbl.txt from ieffect folder to .\data
		
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
				
        ; cut .txt from filename.cbl.txt
				OLDfileCode := fileCode
				FoundPos := InStr(fileCode, ".cbl.txt" , CaseSensitive:=false)
				if (foundPos > 0) {
					fileCode := SubStr(fileCode, 1, foundPos-1) . ".cbl"
				}
				Progress, zh0 fs10, % "Trying to move file " . pathIeffect . fileCode . " to folder/file " . path
				FileMove, %pathIeffect%%OLDfileCode% ,  %path%%fileCode% , 1     ; 1=ovewrite
				if (ErrorLevel <> 0) {
					msgbox, % "Cannot move file " . pathIeffect . OLDfileCode . " to folder " . path
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
  nodesToExport := []
	levels_LastIndex := 0
	fullFileRoutines := path . fileRoutines
	fullFileCode := path . fileCode
	
    ; read last saved values
	IniRead, TreeViewWidth, %A_ScriptDir%\%scriptNameNoExt%.ini, position, treeviewWidth
  IniRead, winX, %A_ScriptDir%\%scriptNameNoExt%.ini, position, winX
  IniRead, winY, %A_ScriptDir%\%scriptNameNoExt%.ini, position, winY
  IniRead, winWidth, %A_ScriptDir%\%scriptNameNoExt%.ini, position, winWidth
  IniRead, winHeight, %A_ScriptDir%\%scriptNameNoExt%.ini, position, winHeight  

	IniRead, valueOfFontsize, %A_ScriptDir%\%scriptNameNoExt%.ini, font, size
	IniRead, valueOfFontcolor, %A_ScriptDir%\%scriptNameNoExt%.ini, font, color
	IniRead, valueOfwindow_color, %A_ScriptDir%\%scriptNameNoExt%.ini, backgroundColor, window
	IniRead, valueOfcontrol_color, %A_ScriptDir%\%scriptNameNoExt%.ini, backgroundColor, control
	IniRead, codeEditor, %A_ScriptDir%\%scriptNameNoExt%.ini, general, codeEditor
	
  if (TreeViewWidth = 0)
    TreeViewWidth := 600

	ListBoxWidth := winWidth - TreeViewWidth - 30    ; 1000 - TreeViewWidth - 30
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
	
	Gui, 1:Font, c%fontColor% s%fontSize%, Courier New
	Gui, 1:Color, %window_color%, %control_color%
	
	Gui, 1:+Resize +Border
	Gui, 1:Add, Text, x5 y10 , Search for routine:
	Gui, 1:Add, Edit, r1 vMyEdit_routine x+5 y5 w150
	Gui, 1:Add, Text, x%search2_x% y10 , Search inside code:
	Gui, 1:Add, Edit, r1 vMyEdit_code x+5 y5 w150
	
	Gui, 1:Add, Button, x+1 Hidden Default, OK    ; hidden button to catch enter key! x+1 = show on same line with textbox
	
	Gui, 1:Add, TreeView, vMyTreeView w%TreeViewWidth% r15 x5 gMyTreeView AltSubmit
    ; Gui, Add, TreeView, vMyTreeView r80 w%TreeViewWidth% x5 gMyTreeView AltSubmit ImageList%ImageListID% ; Background%color1% ; x5= 5 pixels left border
	
	Gui, 1:Add, ListBox, r100 vMyListBox w%ListBoxWidth% x+5, click any routine from the tree to show the code|double click any routine to open in default editor
	Gui, 1:add, StatusBar, Background c%control_color%
    ; Gui, add, StatusBar, Background c%window_color%
	
  ; define the context menu.
	Menu, MyContextMenu, Add, Fold all `tF3, contextMenuHandler
	Menu, MyContextMenu, Add, Unfold all `tF4, contextMenuHandler
	Menu, MyContextMenu, Add, Fold recursively `tF5, contextMenuHandler
	Menu, MyContextMenu, Add, Unfold recursively `tF6, contextMenuHandler
	Menu, MyContextMenu, Add, Fold same level `tF7, contextMenuHandler
	Menu, MyContextMenu, Add, Unfold same level `tF8, contextMenuHandler
  Menu, MyContextMenu, Add, Fold level 2..13 `tshift F1..F12, contextMenuHandler
  Menu, MyContextMenu, Disable, Fold level 2..13 `tshift F1..F12
  Menu, MyContextMenu, Add, 
  Menu, MyContextMenu, Add, Toggle bookmark for export `tF11, contextMenuHandler
  Menu, MyContextMenu, Add, Search next `tF9, contextMenuHandler
  Menu, MyContextMenu, Add, Search previous `tF10, contextMenuHandler

  ; file submenu
	Menu, FileMenu, Add, &Open file, MenuHandler
	Menu, FileMenu, Icon, &Open file, shell32.dll, 4
	
	Menu, FileMenu, Add, Save position, MenuHandler
	Menu, FileMenu, Disable, Save position
	
	Menu, FileMenu, Add, Export tree as..., MenuHandler
	Menu, FileMenu, Icon, Export tree as..., shell32.dll, 259
	
	Menu, FileMenu, Add, &Exit, MenuHandler
	Menu, FileMenu, Icon, &Exit, shell32.dll, 123
	
  ; edit submenu
  Menu, EditMenu, Add, Toggle bookmark for export `tF11, contextMenuHandler
  Menu, EditMenu, Add
  Menu, EditMenu, Add, Search next `tF9, contextMenuHandler
  Menu, EditMenu, Add, Search previous `tF10, contextMenuHandler

  ; view submenu
  Menu, ViewMenu, Add, Fold all `tF3, contextMenuHandler
  Menu, ViewMenu, Add, Unfold all `tF4, contextMenuHandler
  Menu, ViewMenu, Add, Fold recursively `tF5, contextMenuHandler
  Menu, ViewMenu, Add, Unfold recursively `tF6, contextMenuHandler
  Menu, ViewMenu, Add, Fold same level `tF7, contextMenuHandler
  Menu, ViewMenu, Add, Unfold same level `tF8, contextMenuHandler

  ; settings submenu
	Menu, SettingsMenu, Add, &Settings, MenuHandler
	Menu, SettingsMenu, Icon, &Settings, shell32.dll, 317
	
  ; help submenu
  Menu, HelpMenu, Add, &Help `tF1, MenuHandler

  ; define the menu bar.
	Menu, MyMenuBar, Add, &File, :FileMenu
  Menu, MyMenuBar, Add, &Edit, :EditMenu
  Menu, MyMenuBar, Add, &View, :ViewMenu
	Menu, MyMenuBar, Add, &Settings, :SettingsMenu
  Menu, MyMenuBar, Add, &Help, :HelpMenu
	
	Gui, 1:Menu, MyMenuBar
	Gui, 1:Add, Button, gExit, Exit This Example
	Menu, Tray, Icon, icons\shell32_16806.ico                      ;shell32.dll, 85
	return
  }
  ;---------------------------------------
  ; define shortcut keys
  ;---------------------------------------
#IfWinActive ahk_class AutoHotkeyGUI
  global searchText

  ^left::     ;{ <-- decrease treeview
  changeTreeviewWidth("-")
  return

  ^right::    ;{ <-- increase treeview
  changeTreeviewWidth("+")
  return

  F1::
  showHelp()  ;{ <-- help
  return

  F2::
  showExport()  ;{ <-- export
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

  F9::        ;{ <-- find next
  GuiControlGet, searchText, ,MyEdit_routine  ;get search text from input field
  if (searchText <> "")
    searchItemInRoutine(searchText, "next")
  return

  F10::        ;{ <-- find previous
  GuiControlGet, searchText, ,MyEdit_routine  ;get search text from input field
  if (searchText <> "")
    searchItemInRoutine(searchText, "previous")
  return

  F11::       ;{ <-- Toggle bookmark for export
  toggleBookmark()
  return

  +F1::
  processLevel(2)
  return

  +F2::
  processLevel(3)
  return

  +F3::
  processLevel(4)
  return

  +F4::
  processLevel(5)
  return

  +F5::
  processLevel(6)
  return

  +F6::
  processLevel(7)
  return

  +F7::
  processLevel(8)
  return

  +F8::
  processLevel(9)
  return

  +F9::
  processLevel(10)
  return

  +F10::
  processLevel(11)
  return

  +F11::
  processLevel(12)
  return

  +F12::
  processLevel(13)
  return

#IfWinActive
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
	
    ; doubleclick an item: open code in default editor and position to selected routine.
	if (A_GuiEvent = "DoubleClick") {
		statements := []
		routineName := ""
		sourceCode := ""
		IniRead, showOnlyRoutine, showRoutines.ini, general, showOnlyRoutine
		
		TV_GetText(routineName, TV_GetSelection())   ; get item text
		statements := findRoutineFirstStatement(routineName)
		statement := statements[1]
    		
		WinGetPos, X_main, Y_main, Width_main, Height_main, A
		actWin := WinExist("A")
		GetClientSize(actWin, Width_main, Height_main)
    x := X_main + Width_main
    y := Y_main
		
		if (showOnlyRoutine == "false")
			if (codeEditor == "notepad++")
				RunWait, notepad++.exe -lcobol -nosession -ro -n%statement% -x%x% -y%y% "%fullFileCode%"
		else
			RunWait, "C:\Program Files\Microsoft VS Code\Code.exe" --new-window --goto "%fullFileCode%:%statement%"
		else {
			filename := path . "tempfile" . ".cbl"
			FileDelete, %filename%
			count := statements[2] - statements[1]
			line_number := statements[1]
			
			while (line_number <= statements[2]) {
				sourceCode .= allcode[line_number] . (line_number < statements[2] ? "`n" : "")
				line_number ++
			}
			FileAppend, %sourceCode%, %filename%
            ; msgbox, %filename%
			if (codeEditor == "notepad++")
				RunWait, notepad++.exe -lcobol -nosession -ro -x%x% -y%y% "%filename%"
			else
				RunWait, "C:\Program Files\Microsoft VS Code\Code.exe" --new-window "%filename%"
		}

		
		; Sleep, 300  ; wait to open
        ; position besides main window
		; if (codeEditor == "notepad++")
		; 	WinMove, ahk_class notepad++, , X_main + Width_main , Y_main
        ; else
        ;     WinMove, ahk_exe Code.exe, , X_main + Width_main , Y_main
	}
	
    ; spacebar an item: load the routine code.
	if (A_GuiEvent = "K" and A_EventInfo = 32) {
        ; msgbox, % "[" A_EventInfo "]"   ; A_EventInfo contains the ascii character as number
	}
	
	return
  }
  ;-----------------------------------------------------------
  ; set status bar text
  ;-----------------------------------------------------------
updateStatusBar(currentRoutine := "MAIN") {
  ; first find the routine names from the bookmarks
  index1 := findBookmark(nodesToExport[1])
  routine1 := itemLevels[index1, 3]
  index2 := findBookmark(nodesToExport[2])
  routine2 := itemLevels[index2, 3]
  bookmarks := routine1 <> "" ? ("[" . routine1 . "]" . (routine2 <> "" ? "---" . "[" . routine2 . "]" : "")) : (routine2 <> ? "[" . routine2 . "]" : "")

  SB_SetText("Routines:" . allRoutines.MaxIndex() . " | Current level: " . gCurrentLevel . " | Bookmarks:" . bookmarks)

  ; SB_SetText("Routines:" . allRoutines.MaxIndex() . " | Statements:" . allCode.MaxIndex()
  ; . " | File:" . fileCode . " | Current routine:" . currentRoutine)
  }
  ;---------------------------------------------------------------------
  ; Expand/shrink the TreeView in response to user's resizing of window.
  ;---------------------------------------------------------------------
GuiSize:
  {
	if (A_EventInfo = 1)  ; The window has been minimized. No action needed.
		return

	gui_height := A_GuiHeight
	gui_width := A_GuiWidth
  gui_offset := 60

  ; Otherwise, the window has been resized or maximized. Resize the controls to match.
  GuiControl, Move, MyTreeView, % "H" . (A_GuiHeight - gui_offset) . " W" . TreeViewWidth ; -30 for StatusBar and margins.
	
	GuiControl, Move, MyListBox, % "X" . LVX . " H" . (A_GuiHeight - gui_offset ) . " W" . (A_GuiWidth - TreeViewWidth - 10) ; width = total - treeview - (3 X 5) margins.
  ; GuiControl, Move, MyListBox, % "X" . LVX . " H" . (A_GuiHeight - 30) . " W" . (A_GuiWidth - TreeViewWidth - 15) ; width = total - treeview - (3 X 5) margins.
	
	return
  }
    ;----------------------------------------------------------------
    ; on app close save to INI file last position & size.
    ;----------------------------------------------------------------
GuiClose:  ; Exit the script when the user closes the TreeView's GUI window.
  exitApplication()
  return
  ;-----------------------------------------------------------
  ; Handle enter key (such as clicking). 
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

    ;-----------------------------------------------------------
    ; Handle menu bar actions
    ;-----------------------------------------------------------
MenuHandler:
  if (A_ThisMenuItem = "&Open file") {
    if (!fileSelector(path, "(*.txt)"))
      return
    Gui, 1:Destroy
    mainProcess()
    return
  }

  if (A_ThisMenuItem = "Export tree as...") {
    showExport()
    return
  }
  
  if (A_ThisMenuItem = "&Settings") {
    showSettings()
    return
  }
      
  if (A_ThisMenuItem = "&Help `tF1") {
    showHelp()
    return
  }

  if (A_ThisMenuItem = "&Exit") {
    exitApplication()
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
  
  if (A_ThisMenuItem = "Search next `tF9") {
    GuiControlGet, searchText, ,MyEdit_routine  ;get search text from input field
    if (searchText <> "")
      searchItemInRoutine(searchText, "next")
    return
  }
  if (A_ThisMenuItem = "Search previous `tF10") {
    GuiControlGet, searchText, ,MyEdit_routine  ;get search text from input field
    if (searchText <> "")
     searchItemInRoutine(searchText, "previous")
    return
  }
   
  if (A_ThisMenuItem = "Toggle bookmark for export `tF11") {
    toggleBookmark()
  }

  return
  ;---------------------------------------------------------------------
  ; Exit the application  
  ;---------------------------------------------------------------------
exitApplication() {
  saveSettings()
  Gui, 1:Destroy
  ExitApp
  }
  ;---------------------------------------------------------------------
  ; save settings to ini  
  ;---------------------------------------------------------------------
saveSettings() {
  
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
  }
  ;---------------------------------------------------------------------
  ; get actual gui size 
  ;---------------------------------------------------------------------
GetClientSize(hWnd, ByRef w := "", ByRef h := "")
  {
	VarSetCapacity(rect, 16)
	DllCall("GetClientRect", "ptr", hWnd, "ptr", &rect)
	w := NumGet(rect, 8, "int")
	h := NumGet(rect, 12, "int")
  }
  ;--------------------------------------------
  ; resize when ctrl+left or ctrl+right pressed
  ;--------------------------------------------
changeTreeviewWidth(type) {
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
	
	
    ; if no selected item, select root.
	if (selectedItemId = 0)
		selectedItemId := itemLevels[1, 1]
	
	GuiControl, +Redraw, MyTreeView
	TV_Modify(selectedItemId, "VisFirst")     ;re-select old item & make it visible!
  gCurrentLevel := 999
  updateStatusbar()
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
	TV_Modify(selectedItemId, "VisFirst")     ;re-select old item
  gCurrentLevel := 999
  updateStatusbar()
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
	
	TV_Modify(selectedItemId, "VisFirst")     ;re-select old item & make it visible!
  gCurrentLevel := 999
  updateStatusbar()
  }

  ;-----------------------------------------------------------
  ; show specific level
  ;-----------------------------------------------------------
processLevel(selected_level) {
  global
  current_index := 0
  GuiControl, -Redraw, MyTreeView
  TV_Modify(itemLevels[1, 1], "Expand")

  ; find all nodes with same level and fold.
  Loop {
    current_index += 1
      
    if (current_index > levels_LastIndex)    ; if end of array items, exit
      Break
      
    if (itemLevels[current_index, 2] >= selected_level)
      TV_Modify(itemLevels[current_index, 1], "-Expand")
    else
      TV_Modify(itemLevels[current_index, 1], "Expand")
  }

  GuiControl, +Redraw, MyTreeView
  TV_Modify(itemLevels[1, 1], "VisFirst")
  gCurrentLevel := selected_level
  updateStatusbar()
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

  ; check if new routine exists in this thread: if it exists don't process it again.
  threadIndex := searchArray(currRoutine.routineName)
  if (threadIndex > 0)
    return
  
  currentLevel ++
  currThread.push(currRoutine.routineName)  ; add new routine to this thread.
	itemId := addToTreeview(currRoutine.routineName, currentLevel, parentID)
	
	Loop, % currRoutine.calls.MaxIndex() {
		
        ; search array allRoutines[] for the current routine item.
		calledId := searchRoutine(currRoutine.calls[A_Index])

		if (calledId > 0 and currRoutine <> allRoutines[calledId]) {
			processRoutine(allRoutines[calledId], itemId)     ; write children
		}
	}

  value := currThread.pop()
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
  ; toggle on/off bookmark
  ;---------------------------------------------------------------------
toggleBookmark() {
  selectedNode := TV_GetSelection()
  
  if (selectedNode = "") 
    return

  ; if already exists in bookmarks: remove and unbold
  Loop, % nodesToExport.MaxIndex() {
    if (selectedNode = nodesToExport[A_Index]) {
      nodesToExport.RemoveAt(A_Index)
      TV_Modify(selectedNode, "-Bold")
      updateStatusbar()
      return
    }
  }

  ; if doesn't exist in bookmarks: add and bold
  nodesToExport.push(selectedNode)
  TV_Modify(selectedNode, "Bold")

  ; if more than 2 items are bookmarked: remove first
  if (nodesToExport.MaxIndex() > 2) {
    TV_Modify(nodesToExport[1], "-Bold")
    nodesToExport.RemoveAt(1)
  }
  updateStatusbar()
  }
  ;-------------------------------------------------------------------------------
  ; export nodes to text file
  ; (returns the created string)
  ;-------------------------------------------------------------------------------
exportNodes() {
  global
  exportedRoutines := []
  exportedString := ""

  if (nodesToExport.MaxIndex() = 0)
    return ""

  ; set first node.
  bookmark1 := nodesToExport[1]
  index1 := findBookmark(bookmark1)

  ; set last node: 
  if (nodesToExport.MaxIndex() > 1) {
    bookmark2 := nodesToExport[2]
    index2 := findBookmark(bookmark2)
    }
  else {  ; if not set find last sub node of the selected node.
    index2 := findLastSubnode(index1)
    bookmark2 := itemLevels[index2, 1]
  }
  
  if (index1 = 0 or index2 = 0)
    return ""

  ; swap bookmarks so the first is processed first.
  current_Index := index1
  if (index1 > index2) {
    tempBookmark := bookmark1
    bookmark1 := bookmark2
    bookmark2 := tempBookmark
    current_Index := index2
  }

  itemID := bookmark1

  ; make starting node as having level 1:
  ; offset := itemLevels[current_Index, 2] - 1
  offset := 0

  Loop {
    exportRoutine(itemLevels[current_Index, 3], itemLevels[current_Index, 2] - offset)
    if (itemLevels[current_Index,1] = bookmark2)   ; stop when reaching the ending node.
      break
    current_Index++
  } until (current_Index > itemLevels.MaxIndex())   ; stop when reaching end of array.

  Loop, % exportedRoutines.MaxIndex() {
    exportedString .= exportedRoutines[A_Index]
  }
  
  return exportedString
  }
  ;-------------------------------------------------------------------------------
  ; return the index inside itemLevels of a bookmark
  ;-------------------------------------------------------------------------------
findBookmark(bookmark) {
  Loop, % itemLevels.MaxIndex() {
    if (bookmark = itemLevels[A_Index, 1])
      return A_Index
  }
  return 0
  }
  ;-------------------------------------------------------------------------------
  ; find the itemID of the last sub node of a bookmark
  ;-------------------------------------------------------------------------------
findLastSubnode(index) {
  if (index < 1 or index > itemLevels.MaxIndex())
    return 0

  currentLevel := itemLevels[index, 2]

  Loop, % itemLevels.MaxIndex() - index {
    index++
    if (currentLevel >= itemLevels[index, 2])
      return --index
  }
  return index
  }
  ;-------------------------------------------------------------------------------
  ; export what you see (not folded nodes) to text file
  ; (returns the created string)
  ;-------------------------------------------------------------------------------
exportWhatYouSee() {
  global
  if (allRoutines.MaxIndex() <= 0)    ; no called routines
    return ""

  exportedRoutines := []
  exportedString := ""

  ItemID := TV_GetNext()  ; get first item (root)
  if (ItemID=0)
    return
  
  ; export root node.
  currentLevel := 1
  exportRoutine(allRoutines[1].routineName, currentLevel)
  ItemID := TV_GetNext(ItemID, "F")
  
  ; loop through treeview and select only unfolded nodes (with "expanded" attribute).
  Loop
  {
    if not ItemID  ; exit if end of tree.
      break
    
    currentIndex := searchItemId(itemID)
    if (currentIndex = 0)
      break

    currentRoutine := itemLevels[currentIndex, 3]
    currentLevel := itemLevels[currentIndex, 2]

    exportRoutine(currentRoutine, currentLevel)

    if (TV_Get(ItemID, "Expanded"))
      ItemID := TV_GetNext(ItemID, "F")

    ; if folded, find next node with level <= current node's level.
    else {
      ItemID := 0
      while (currentIndex < itemLevels.MaxIndex()) {
        currentIndex ++
        if (itemLevels[currentIndex, 2] <= currentLevel) {
          ItemID := itemLevels[currentIndex, 1]
          break
        }
      }
    }
  }

  Loop, % exportedRoutines.MaxIndex() {
    exportedString .= exportedRoutines[A_Index]
  }
  
  return exportedString
  }
  ;-------------------------------------------------------------------------------
  ; export treview to text file
  ; (returns the created string)
  ;-------------------------------------------------------------------------------
exportTreeview() {
  if (allRoutines.MaxIndex() <= 0)    ; no called routines
    return ""
  
  exportedRoutines := []
  currThread  := [] 
  exportedString := ""

  ; first item is always = "MAIN" (the parent routine of all)
  currRoutine := allRoutines[1]
  if (MaxLevel < 2 or MaxLevel > 999)
    MaxLevel := 999

  processRoutine_for_Export(currRoutine, MaxLevel)

  Loop, % exportedRoutines.MaxIndex() {
    exportedString .= exportedRoutines[A_Index]
  }
  
  return exportedString
  }
  ;-------------------------------------------------------------------------------
  ; process one routine
  ;-------------------------------------------------------------------------------
processRoutine_for_Export(currRoutine, MaxLevel=999) {
  static currentLevel
    
  ; check if new routine exists in this thread: if it exists don't process it again.
  threadIndex := searchArray(currRoutine.routineName)
  if (threadIndex > 0)
    return

  currentLevel ++
  if (currentLevel > MaxLevel) {
    currentLevel --
    return
  }
  currThread.push(currRoutine.routineName)  ; add new routine to this thread.

  exportRoutine(currRoutine.routineName, currentLevel)

  Loop, % currRoutine.calls.MaxIndex() {

    ; search array allRoutines[] for the current routine item.
    calledId := searchRoutine(currRoutine.calls[A_Index])
    if (calledId > 0 and currRoutine <> allRoutines[calledId]) {
        processRoutine_for_Export(allRoutines[calledId], MaxLevel)     ; write children
      }
    }

    value := currThread.pop() ; at end remove current routine from thread
    currentLevel --
  }
  ;-------------------------------------------------------------------------------
  ; export one routine to text file
  ;-------------------------------------------------------------------------------
exportRoutine(routineName, currentLevel) {
  prefix := "`n"
  count:= currentLevel - 1

  Loop, %count%
    prefix .= "  "

  if (count > 0)
    prefix .= "->"
  
  oneLine := prefix . " " . routineName

  exportedRoutines.push(oneLine)
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
  ;-------------------------------------------------------------------------------
  ; search if parameter exists in the parameter array.
  ;-------------------------------------------------------------------------------
searchArray(searchfor) {
  Loop, % currThread.MaxIndex() {
      if (searchfor = currThread[A_Index]) {
          return A_index
      }
  }
  return 0
  }
  ;-------------------------------------------------------------------------------
  ; search if parameter (itemId) exists in itemLevels array.
  ;-------------------------------------------------------------------------------
searchItemId(itemID) {
  Loop, % itemLevels.MaxIndex() {
      if (itemID = itemLevels[A_Index, 1]) {
          return A_index
      }
  }
  return 0
  }
    ;-----------------------------------------------------------------------
    ; read mpmdl001.cbl file and populate array with all code
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
	statements := [1, 1]
	
	if (routineName <> "") {
		calledId := searchRoutine(routineName)
		if (calledId > 0) {
			statements[1] := substr(allRoutines[calledId].startStmt, 1, 4)
			statements[2] := substr(allRoutines[calledId].endStmt, 1, 4)
		}
	}
	
	return statements
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
    ; msgbox, %  gui_height . "`n" . gui_offset
	GuiControl, Move, MyListBox, % "H" . (gui_height - gui_offset +5 ) ; width = total - treeview - (3 X 5) margins.
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
	FoundPos := InStr(FileName, ".cbl.txt" , CaseSensitive:=false)
	if (foundPos > 0) {
		Filename := SubStr(FileName, 1, foundPos-1) . ".txt"
		NameNoExt := SubStr(FileName, 1, foundPos-1)
	}
	
	fileRoutines := FileName
	fileCode := NameNoExt . ".cbl"
	return true
	
  ; msgbox, % fileRoutines . "`n" fileCode . "`n" . fullFileRoutines . "`n" . fullFileCode
  ; ExitApp
  }
  ;---------------------------------------------------------------------
  ; save array of routines to text file.
  ; not used (only for test)
  ;---------------------------------------------------------------------
saveRoutines(filename, header, delete) {
  if (delete) {
    if FileExist(filename)
      FileDelete, %filename%
  }
  FileAppend, `n%header% `n , %filename%

  Loop, % allRoutines.MaxIndex() {
    currentRoutine := allRoutines[A_Index]
    row := substr(currentRoutine.routineName . "                              ",1,30) . "`t: "

    Loop, % currentRoutine.calls.MaxIndex() {
      row .= currentRoutine.calls[A_Index] . " "
      }
    row .= "`n"
    FileAppend, %row%, %filename%
  }

  ; return
  row := "`n`nseq - node  - level - routine`n"
  row .= "-----------------------------------`n"

  Loop, % itemLevels.MaxIndex() {
    row .= A_Index . " : " itemLevels[A_Index, 1] . " - " . itemLevels[A_Index, 2] . " - " . itemLevels[A_Index,3] . "`n"
  }
    FileAppend, %row%, %filename%
  } 