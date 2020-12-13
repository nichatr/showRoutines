;--------------------------------------------------------------------------------------
  ; Version with:
  ;   listbox for showing code
  ;   parameter for input file
  ;   external ini file
  ; source must be saved as "UTF8 with BOM"
  ;--------------------------------------------------------------------------------------
  ; parameters:
  ;   A_Args[1] = routine calls file = outfile.txt
  ;   A_Args[2] = source code file   = outfile.XXXXX (XXXXX=RPGLE/CBLLE/CBL)
  ;   A_Args[3] = path where above files created = z:\bussup\txt\\
  ;   A_Args[4] = use existing files or select = *NEW|*OLD|*SELECT (default)
  ;               *NEW = try to load above files
  ;               *OLD = use existing file found in showRoutines.ini
  ;               *SELECT = open file selector
  ;   A_Args[5] = "*DISPLAY" show gui, "*EXPORT": load and export to html without showing gui.
  ;   A_Args[6] = "1" do not show gui, application is running for extracting the 'fileinstall' files.
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
; initial declarations
  #SingleInstance off     ;force
  #NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.

  ; used for building the executable.
  FileInstall, tree diagram in zTree.html, tree diagram in zTree.html
  FileInstall, tree diagram in CSS.html, tree diagram in CSS.html
  FileInstall, showRoutines.ini, showRoutines.ini
  FileInstall, showRoutines.bat, showRoutines.bat
  FileInstall, prism.js, prism.js
  FileInstall, prism.css, prism.css

  #Include %A_ScriptDir%\JSON\JSON.ahk  ; for converting to/from json
  #Include %A_ScriptDir%\XML\xml.ahk  ; for building html (xml)
  #Include %A_ScriptDir%\parse\parseCOBOL.ahk
  #Include %A_ScriptDir%\parse\parseRPG.ahk

  ; global declarations
  global allRoutines  ; array of class "routine"
  global allCode      ; array of source code to show
  global parseCode  ; true=parse code to create the text file with the routine calls.
  global language ; indicates the language: rpgle, cobol, clp.
  global currThread ; keeps all routines in the current thread in order to avoid circular dependencies
  global tmpRoutine 
  global fullFileRoutines, fileRoutines     ; text file with all routine calls, is the output from AS400.
  global fullFileCode, fileCode         ; text file with source code.
  global path
  global itemLevels, levels_LastIndex
  global saveOnExit ; declares if settings are saved on app exit.
  global openLevelOnStartup ; level to unfold on startup
  global scriptNameNoExt
  global TreeViewWidth, treeviewWidthStep
  global ListBoxWidth
  global MyTreeView, MyListBox, MyEdit_routine, MyEdit_code
  global exportedRoutines, exportDescriptions
  global exportOutputFormat, exportConnectorsType, exportMaxLevel, includeDescriptions, OutputFormatRadio, ConnectorsTypeRadio, EditorRadio, ExportedFilename
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
  global ExportSelected, nodesToExport, ExportWhatYouSee, exportInBatch
  global guiHWND

initialize()
mainProcess()
  return

mainProcess() {
  setup()
  populateCode()
  cleanCode(allCode, language)  ; trim line numbers, spaces, dates.

  if (language="rpg")
    parseRPG()
  else
    parseCOBOL()


  ; if (parseCode) {
  ;   Switch language
  ;   {
  ;     Case "rpg":
  ;       parseRPG()
  ;     Case "cobol":
  ;       parseCOBOL()
  ;   }
  ; }

  populateRoutines()
  loadTreeview()
  ; file_to_save := A_ScriptDir . "\data\allRoutines.txt"
  ; saveRoutines(file_to_save, header, true)
  updateStatusBar()
  if (!exportInBatch)
    showGui()
  else {
    exportInBatch()
    ExitApp
    }
  }
showGui() {
  global
	OnMessage(0x232, "Move_window") ; to move children guis with the parent
  processLevel(openLevelOnStartup)
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
    Alt F2 = settings

    F3/F4 = fold/unfold all 
    F5/F6 = fold/unfold current node recursively 
    F7/F8 = fold/unfold current level
    shift F1..F12 = fold level 2..13

    F9/F10 = search next/previous
    F11 = toggle bookmark for export

    ctrl right cursor = increase tree width
    ctrl left cursor = decrease tree width

    click a routine left to show the code right
    double-click a routine left to open code in editor

    )
  Gui, 2:Add, button, xm+10 y+20 Default g2Close, Close
  Gui, 2:show, x%newX% y%newY%, Gui 2
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

  Gui, 3:Destroy
  global subGui3_W, subGui3_H

  subGui3_W := 420
  subGui3_H := 350
  WinGetPos, targetX, targetY, targetWidth, targetHeight, A
  newX := targetX + (targetWidth - subGui3_W) / 2
  newY := targetY + (targetHeight - subGui3_H) / 2

  Gui, 3:+AlwaysOnTop -Caption +Owner1
  Gui, 3:Add,GroupBox,xm+5 y+10 w%subGui3_W% h%subGui3_H%, Export
  
  ; filename
  SplitPath, inputFilename , FileName, Dir, Extension, NameNoExt, Drive
  ExportedFilename := "exported_" . NameNoExt     ; . ".html"
  Gui, 3:Add,Text,xm+20 yp+40, Exported filename
  Gui, 3:Add,Edit, vExportedFilename xp+90 yp-5 w300, %ExportedFilename%
  ; Gui, 3:Add,Edit, vExportedFilename xp+90 yp-5 w300, %scriptDir%\data\%inputFilename%

  ; max level
  Gui, 3:Add,Text,xm+20 yp+35, Max level to export
  Gui, 3:Add,Edit, vexportMaxLevel xp+100 yp-5 w60 +Number
  Gui, 3:Add, UpDown, Range2-999, %exportMaxLevel%

  ; include descriptions?
  CheckedExportDescriptions := exportDescriptions == "true" ? "Checked" : ""
  Gui, 3:Add, Checkbox, vincludeDescriptions g3IncludeDescriptions xp+100 yp+5 %CheckedExportDescriptions% Disabled,   Include routines descriptions

  ; output format
  CheckedHTML1 := exportOutputFormat == "html1" ? "Checked" : ""
  CheckedHTML2 := exportOutputFormat == "html2" ? "Checked" : ""
  CheckedTXT := exportOutputFormat == "txt" ? "Checked" : ""
  CheckedJSON := exportOutputFormat == "json" ? "Checked" : ""

  ; connectors type
  CheckedUnicode := exportConnectorsType == "Unicode" ? "Checked" : ""
  CheckedAS400 := exportConnectorsType == "AS400" ? "Checked" : ""

  Gui, 3:Add, GroupBox, xm+20 y120 w150 h150, Output format
  Gui, 3:Add, Radio, Group g3Check vOutputFormatRadio %CheckedHTML1% xp+15 yp+30, folding tree
  Gui, 3:Add, Radio, g3Check xp yp+25 %CheckedHTML2%, boxed tree
  Gui, 3:Add, Radio, g3Check xp yp+25 %CheckedTXT%, txt
  Gui, 3:Add, Radio, g3Check xm+35 yp+25 %CheckedJSON%, json

  Gui, 3:Add, GroupBox, xp+150 y120 w150 h60, Connectors (only for txt)
  Gui, 3:Add, Radio, Group g3Check vConnectorsTypeRadio %CheckedUnicode% xp+15 yp+30, Unicode
  Gui, 3:Add, Radio, g3Check xp+70 yp %CheckedAS400%, AS400
  ; Gui, 3:Add, Radio, g3Check vAS400 xp+70 yp %CheckedAS400%, AS400


  ; Export, Close buttons
  Gui, 3:Add, button, xm+30 ym+300 w80 g3ExportAll default, All
  Gui, 3:Add, button, xp+90 ym+300 w80 g3ExportSelected vExportSelected, Selected
  Gui, 3:Add, button, xp+90 ym+300 w80 g3ExportWhatYouSee vExportWhatYouSee, What you see
  Gui, 3:Add, button, xp+90 w80 g3Close, Cancel

  if (nodesToExport.MaxIndex()>0)
    GuiControl, 3:Enable, ExportSelected
  else
    GuiControl, 3:Disable, ExportSelected

  ; show window
  Gui, 3:show, x%newX% y%newY% h%subGui3_H%, Gui 3
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

  if (OutputFormatRadio = 1) {
    exportOutputFormat := "html1"
    ; connectorsDisplayMode("Disable")
  }

  if (OutputFormatRadio = 2) {
    exportOutputFormat := "html2"
    ; connectorsDisplayMode("Disable")
  }

  if (OutputFormatRadio = 3) {
    exportOutputFormat := "txt"
    ; connectorsDisplayMode("Enable")
  }

  if (OutputFormatRadio = 4) {
    exportOutputFormat := "json"
    ; connectorsDisplayMode("Disable")
  }

  if (ConnectorsTypeRadio = 1)
    exportConnectorsType := "Unicode"

  if (ConnectorsTypeRadio = 2)
    exportConnectorsType := "AS400"
  
  Return

  ;---------------------------------------------------------------------
  ; button <All> handler
  ;---------------------------------------------------------------------
3ExportAll:
  Gui, 3:Submit, NoHide
  if (exportMaxLevel < 2 or exportMaxLevel > 999) {
    MsgBox, max level must be between 2 and 999
    return
  }
  if (trim(ExportedFilename) = "") {
    MsgBox, filename cannot be empty
    return
  }

  expandAll := true
  exportedString := exportNodes(expandAll)
  saveExportedString(exportedString)
  goto 3Close

  ;---------------------------------------------------------------------
  ; button <Selected> handler
  ;---------------------------------------------------------------------
3ExportSelected:
  Gui, 3:Submit, NoHide
  Gui, 1:Default  ; necessary to use the TV_* functions on the gui 1 treeview!exportMarked
  if (trim(ExportedFilename) = "") {
    MsgBox, filename cannot be empty
    return
  }
  if (exportOutputFormat = "txt") {
    MsgBox, Export selected nodes does not work with .TXT
    return
  }
  exportedString := exportMarked()
  saveExportedString(exportedString)
  goto 3Close

  ;---------------------------------------------------------------------
  ; button <WhatYouSee> handler
  ;---------------------------------------------------------------------
3ExportWhatYouSee:
  Gui, 3:Submit, NoHide
  Gui, 1:Default  ; necessary to use the TV_* functions on the gui 1 treeview!
  if (trim(ExportedFilename) = "") {
    MsgBox, filename cannot be empty
    return
  }
  expandAll := false
  exportedString := exportNodes(expandAll)
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
  ; enable or disable groupbox with connectors type.
  ;---------------------------------------------------------------------
connectorsDisplayMode(mode) {
  if (mode = "Disable") {
    GuiControl, Disable, ConnectorsTypeRadio
    GuiControl, Disable, AS400
  } else {
    GuiControl, Enable, ConnectorsTypeRadio
    GuiControl, Enable, AS400
  }
  }
  ;---------------------------------------------------------------------
  ; export in html format with default options (without "export gui")
  ;---------------------------------------------------------------------
exportInBatch() {
  ; filename to export = "exported_inputFilename.html"
  SplitPath, fileRoutines , FileName, Dir, Extension, NameNoExt, Drive
  ExportedFilename := "exported_" . NameNoExt . ".html"
  exportDescriptions := "true"
  exportOutputFormat := "html1"
  exportConnectorsType := "Unicode"
  expandAll := true
  exportedString := exportNodes(expandAll)
  saveExportedString(exportedString)
  }
  ;---------------------------------------------------------------------
  ; save created export into file and open it.
  ;---------------------------------------------------------------------
saveExportedString(exportedString) {
  global
  if (exportedString = "") {
    MsgBox, Nothing to export.
    return
  }

  ; json format needs no processing.
  if (exportOutputFormat = "json" or exportOutputFormat = "txt") {
    OutputVar := exportedString
    extension := exportOutputFormat
  }
  
  ; html1 format uses specific template.
  else if (exportOutputFormat = "html1") {
    FileRead, templateContents, %A_ScriptDir%\tree diagram in zTree.html
    if ErrorLevel {
      MsgBox, Template file not found (\tree diagram in zTree.html)
      return
    }

    Loop, % allCode.MaxIndex() {
      stringCode .= allCode[A_Index] . "`r" ; `n adds another <br> --> 2 linefeeds!
    }

    ; transformation will be done by Prism.
    ; Transform, stringCode, HTML, %stringCode% ; convert into html string
    ; the <pre><code> tags are inside the template's body already. The addition of the code is done dynamically with $().html()

    ; replace dummy strings with actual data.
    SplitPath, fileRoutines , FileName, Dir, Extension, NameNoExt, Drive
    templateContents := RegExReplace(templateContents, "TITLE", NameNoExt . ": routine calls")
    OutputVar := RegExReplace(templateContents, "var zNodes = \[\]", "var zNodes = " . exportedString)
    ; enclose the code in backticks for multiline functionality.
    OutputVar := RegExReplace(OutputVar, "var myCode = ````", "var myCode = ``" . stringCode . "``")
    OutputVar := RegExReplace(OutputVar, "cobol", language)
    extension := "html"
  }

  ; html2 format uses specific template.
  else if (exportOutputFormat = "html2") {
    FileRead, templateContents, %A_ScriptDir%\tree diagram in CSS.html
    if ErrorLevel {
      MsgBox, Template file not found (\tree diagram in CSS.html)
      return
    }

    ; replace dummy strings with actual data.
    SplitPath, fileRoutines , FileName, Dir, Extension, NameNoExt, Drive
    templateContents := RegExReplace(templateContents, "TITLE", NameNoExt . ": routine calls")
    ; below regex was taken from https://stackoverflow.com/questions/6109882/regex-match-all-characters-between-two-strings
    ; it replaces all dummy text between <body>..</body> with the actual content.
    OutputVar := RegExReplace(templateContents, "\<body\>(?s)(.*)\<\/body\>", "<body>" . exportedString . "</body>")
    extension := "html"
  }

  filename := A_ScriptDir . "\data\" . ExportedFilename . "." . extension
  if FileExist(filename)
    FileDelete, %filename%

  FileEncoding, UTF-8
  FileAppend, %OutputVar%, %filename%
  Run, %filename%
  }
  ;---------------------------------------------------------------
  ; remove line numbers, spaces and date from each line of code.
  ;---------------------------------------------------------------
cleanCode(allCode, language) {
  /*--------------------------------------------------------------------------- 
    convert ahk array of objects into one string, each item separated by \r.
    but first, for each statement, remove:
    COBOL:
    example line: [ 0881.00       *                                                  ]
    example line: [ 0882.00            MOVE LSAA-BUPAREC           TO BUPA-DATA-AREA.]
      -the line numbers at the begining
      -the first space, the next 6 spaces.
      -the date at the end.
      -the spaces from the right only.
    RPG:
    example line: [ 0187.00     C                   EXSR      R_PROC_SUBR     ]
      -the line numbers at the begining
      -the first space, the next 5 spaces + 1 char (H,F,D,I,C,O)
      -the date at the end.
      -the spaces from the right only.
    CLP:
      -the date at the end.
      -the spaces from the right only.
  -----------------------------------------------------------------------------
  */
  stringCode := ""
  if (language = "rpg") {
    Loop, % allCode.MaxIndex() {
      line := RegExReplace(allCode[A_index], "^.\d{4}\.\d{2}.{5}","") ; remove (1 char) + (9999.99) + (5 chars) at BOL
      line := RegExReplace(line, "\d{6}.?$","") ; remove (999999) + (0/1) char at EOL
      line := RegExReplace(line, "\\","\\") ; replace backslash with double backslash to show correctly!
      
      allCode[A_index] := line
      }
  }
  else if (language = "clp") {
    line := RegExReplace(allCode[A_index], "\d{6}.?$","") ; remove (999999) + (0/1) char at EOL
    allCode[A_index] := line
    }
  else {  ; otherwise it is considered as cobol (default language).
    Loop, % allCode.MaxIndex() {
      line := RegExReplace(allCode[A_index], "^.\d{4}\.\d{2}.{6}","") ; remove (1 char) + (9999.99) + (6 chars) at BOL
      line := RegExReplace(line, "\d{6}.?$","") ; remove (999999) + (0/1) char at EOL
      line := RegExReplace(line, "\\","\\") ; replace backslash with double backslash to show correctly!

      allCode[A_index] := line
      }
    }
  
  }
  ;--------------------------------------------
  ; show window with editable settings
  ;--------------------------------------------
showSettings() {
	static font_size, font_color, tree_step, window_color, control_color, showOnlyRoutine, showOnlyRoutineFlag, OutputFormatRadio, checked1, checked2
	win_title := "Settings"
	
	IniRead, font_size, %A_ScriptDir%\%scriptNameNoExt%.ini, font, size
	IniRead, font_color, %A_ScriptDir%\%scriptNameNoExt%.ini, font, color
	IniRead, tree_step, %A_ScriptDir%\%scriptNameNoExt%.ini, position, treeviewWidthStep
	IniRead, window_color, %A_ScriptDir%\%scriptNameNoExt%.ini, backgroundColor, window
	IniRead, control_color, %A_ScriptDir%\%scriptNameNoExt%.ini, backgroundColor, control
	IniRead, showOnlyRoutine, %A_ScriptDir%\%scriptNameNoExt%.ini, general, showOnlyRoutine
	IniRead, openLevelOnStartup, %A_ScriptDir%\%scriptNameNoExt%.ini, general, openLevelOnStartup
	
	IniRead, codeEditor, %A_ScriptDir%\%scriptNameNoExt%.ini, general, codeEditor
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
	Gui, 4:Add, Radio, Group g4check vEditorRadio %checked1% xp+80 yp, vscode
	Gui, 4:Add, Radio, g4check %checked2% xp+70 yp, notepad++

	Gui, 4:Add, Text, xm+5 yp+40, On startup unfold level
  Gui, 4:Add,Edit, vopenLevelOnStartup xp+115 yp-5 w60 +Number
  Gui, 4:Add, UpDown, Range2-999, %openLevelOnStartup%
	
	checked := showOnlyRoutine == "false" ? "" : "Checked"
	Gui, 4:Add, Checkbox, vshowOnlyRoutineFlag %checked% xs200 ys, Show only selected routine
	
    ;---------------------------------------------
    ; buttons to save, cancel, load default values
    ;---------------------------------------------
	Gui, 4:Add, Button, x70 y260 w80, Save
	Gui, 4:Add, Button, x160 y260 w80 default, Cancel
	Gui, 4:Add, Button, x250 y260 w80, Default
	
	4show:
	Gui, 4:+AlwaysOnTop -Caption +Owner1
  ; Gui, 4:+Resize -SysMenu +ToolWindow
	showSubGui(400, 300, win_title)
	Return
	
	4Check:
	gui, 4:submit, nohide
        ; GuiControlGet, EditorRadio
	if (EditorRadio = 1)
		codeEditor := "code"
	if (EditorRadio = 2)
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
		
		IniWrite, %font_size%, %A_ScriptDir%\%scriptNameNoExt%.ini, font, size
		IniWrite, %font_color%, %A_ScriptDir%\%scriptNameNoExt%.ini, font, color
		if (tree_step > 0)
			IniWrite, %tree_step%, %A_ScriptDir%\%scriptNameNoExt%.ini, position, treeviewWidthStep
		IniWrite, %window_color%, %A_ScriptDir%\%scriptNameNoExt%.ini, backgroundColor, window
		IniWrite, %control_color%, %A_ScriptDir%\%scriptNameNoExt%.ini, backgroundColor, control
		
		showOnlyRoutine := showOnlyRoutineFlag ? "true" : "false"
		IniWrite, %showOnlyRoutine%, %A_ScriptDir%\%scriptNameNoExt%.ini, general, showOnlyRoutine
		
		IniWrite, %codeEditor%, %A_ScriptDir%\%scriptNameNoExt%.ini, general, codeEditor
		IniWrite, %openLevelOnStartup%, %A_ScriptDir%\%scriptNameNoExt%.ini, general, openLevelOnStartup
		
		Goto, 4GuiClose
	}
	
	Goto, 4show
	
        ; Load the default values (again from ini file).
	4ButtonDefault:
	{
		IniRead, treeviewWidth, %A_ScriptDir%\%scriptNameNoExt%.ini, default, treeviewWidth
		IniRead, font_size, %A_ScriptDir%\%scriptNameNoExt%.ini, default, fontsize
		IniRead, font_color, %A_ScriptDir%\%scriptNameNoExt%.ini, default, fontcolor
		IniRead, tree_step, %A_ScriptDir%\%scriptNameNoExt%.ini, default, treeviewWidthStep
		IniRead, window_color, %A_ScriptDir%\%scriptNameNoExt%.ini, default, windowcolor
		IniRead, control_color, %A_ScriptDir%\%scriptNameNoExt%.ini, default, controlcolor
		IniRead, codeEditor, %A_ScriptDir%\%scriptNameNoExt%.ini, default, codeEditor
		
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
  exportInBatch := false
  
  if (A_Args[6] = "1")  ; if application is running for extracting the files, then exit.
    ExitApp

  if !FileExist(path) {
    FileCreateDir, %path%
  }

  ; the global variable scriptNameNoExt is used for accessing the .INI file from multiple places
  ; so it is defined at the beginning.
	SplitPath, A_ScriptFullPath , scriptFileName, scriptDir, scriptExtension, scriptNameNoExt, scriptDrive
	
	if (A_Args[1] != "" and A_Args[2] != "" and A_Args[3] != ""  and A_Args[4] != "")
		params_exist = true

  if (!params_exist) {
    if (!fileSelector(path))
      ExitApp ; if no file was selected exit application.
    Return  ; if file was selected return to calling routine.
  }

	fileRoutines := A_Args[1]
	fileCode := A_Args[2]
	
  ; StringLower, args1, A_Args[1]
  arg1 := A_Args[1]
  SplitPath, arg1, ,,, arg1noext

  ; decide if a <routine calls> file exists or not.
  if (A_Args[1] = "")
    parseCode := True
  ; <routine calls> derives from <code> file but instead the cbl/rpg extension is txt.
  else if (arg1noext = "_") {
    parseCode := True
    filename := A_Args[2]
    SplitPath, filename, file, dir, ext, fileNoExt, drive
    fileRoutines := fileNoExt . ".txt"
  }
  else
    parseCode := False

  ; use existing files(*no):
  ;   move file.txt & file.XXXXX (XXXXX=rpgle/cblle/cbl) from ieffect folder to .\data
  Loop, 1
  {
    if (trim(A_Args[4]) = "*NEW") {

      pathIeffect := A_Args[3]
      
      if (!FileExist(pathIeffect)) {
        msgbox, % "Folder " . pathIeffect . " doesn't exist. Perhaps a map drive is required. Please select an existing file"
        fileRoutines := ""      ; clear in order next to show file selector!
        fileCode := ""
        Break
      } 

      ; move <routine calls> file to work folder.
      if (!parseCode) {
        Progress, zh0 fs10, % "Trying to move file " . pathIeffect . fileRoutines . " to folder " . path
        FileMove, %pathIeffect%%fileRoutines% , %path% , 1  ; 1=overwrite file
        if (ErrorLevel <> 0) {
          msgbox, % "Cannot move file " . pathIeffect . fileRoutines . " to folder " . path
        }
        Progress, Off
      }
      
      ; move <code> file to work folder.
      Progress, zh0 fs10, % "Trying to move file " . pathIeffect . fileCode . " to folder/file " . path
      FileMove, %pathIeffect%%fileCode% ,  %path%, 1     ; 1=ovewrite file
      if (ErrorLevel <> 0) {
        msgbox, % "Cannot move file " . pathIeffect . fileCode . " to folder " . path
      }
      Progress, Off
    }
  }
		
    ; use existing files(*select) or ini file has not corresponding entry: open file selector
  
  if (A_Args[4] = "*SELECT" or fileCode = "") {
    if (!fileSelector(path))
      ExitApp
  }
  
  if (trim(A_Args[5]) = "*EXPORT")
    exportInBatch := true
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

  if !FileExist(fullFileCode) {
    ; msgbox, % line 799
    if (!fileSelector(path))
      ExitApp
  }

  ; find the language (used in export and open with notepad++).
	SplitPath, fullFileCode , codeFileName, codeDir, codeExtension, codeNameNoExt, codeDrive
  if (RegExMatch(codeExtension, "im)cbl"))
    language := "cobol"
  else if (RegExMatch(codeExtension, "i)rpg"))
    language := "rpg"
  ; else if (RegExMatch(codeExtension, "i)cl"))
  ;   language := "clp"
  else
    language := "cobol"
      
  ; get gui handle.
  Gui  +HwndguiHWND
  ; msgbox, % guiHWND
  
  ; read last saved values
	IniRead, TreeViewWidth, %A_ScriptDir%\%scriptNameNoExt%.ini, position, treeviewWidth
  IniRead, winX, %A_ScriptDir%\%scriptNameNoExt%.ini, position, winX
  IniRead, winY, %A_ScriptDir%\%scriptNameNoExt%.ini, position, winY
  IniRead, winWidth, %A_ScriptDir%\%scriptNameNoExt%.ini, position, winWidth
  IniRead, winHeight, %A_ScriptDir%\%scriptNameNoExt%.ini, position, winHeight  

  ; adjust the saved gui location/size according to current monitors.
  getMonitorsSizes(minLeft, maxRight, maxBottom)
  adjustGui_SizePosition(winX, winY, winWidth, winHeight, minLeft, maxRight, maxBottom)

  ; winX := 0
  ; winY := 0
  if (winHeight < 200)
    winHeight := 200
  if (winWidth < 250)
    winWidth := 250
  if (winWidth > 2500)
    winWidth := 2500

	IniRead, valueOfFontsize, %A_ScriptDir%\%scriptNameNoExt%.ini, font, size
	IniRead, valueOfFontcolor, %A_ScriptDir%\%scriptNameNoExt%.ini, font, color
	IniRead, valueOfwindow_color, %A_ScriptDir%\%scriptNameNoExt%.ini, backgroundColor, window
	IniRead, valueOfcontrol_color, %A_ScriptDir%\%scriptNameNoExt%.ini, backgroundColor, control

  IniRead, exportMaxLevel, %A_ScriptDir%\%scriptNameNoExt%.ini, export, exportMaxLevel
  IniRead, exportDescriptions, %A_ScriptDir%\%scriptNameNoExt%.ini, export, exportDescriptions
  IniRead, exportOutputFormat, %A_ScriptDir%\%scriptNameNoExt%.ini, export, exportOutputFormat
  IniRead, exportConnectorsType, %A_ScriptDir%\%scriptNameNoExt%.ini, export, exportConnectorsType

	IniRead, codeEditor, %A_ScriptDir%\%scriptNameNoExt%.ini, general, codeEditor
	IniRead, openLevelOnStartup, %A_ScriptDir%\%scriptNameNoExt%.ini, general, openLevelOnStartup
  IniRead, saveOnExit, %A_ScriptDir%\%scriptNameNoExt%.ini, general, saveOnExit
	
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
	
  if (openLevelOnStartup < 2 or openLevelOnStartup > 999)
    openLevelOnStartup := 999

	Gui, 1:Font, c%fontColor% s%fontSize%, Segoe
	; Gui, 1:Font, c%fontColor% s%fontSize%, Courier New
	Gui, 1:Color, %window_color%, %control_color%
	
	Gui, 1:+Resize +Border
	Gui, 1:Add, Text, x5 y10 , Search for routine:
	Gui, 1:Add, Edit, r1 vMyEdit_routine x+5 y5 w150
	Gui, 1:Add, Text, x%search2_x% y10 , Search inside code:
	Gui, 1:Add, Edit, r1 vMyEdit_code x+5 y5 w150
	
	Gui, 1:Add, Button, x+1 Hidden Default, OK    ; hidden button to catch enter key! x+1 = show on same line with textbox
	
	Gui, 1:Add, TreeView, vMyTreeView w%TreeViewWidth% r15 x5 gMyTreeView AltSubmit
    ; Gui, Add, TreeView, vMyTreeView r80 w%TreeViewWidth% x5 gMyTreeView AltSubmit ImageList%ImageListID% ; Background%color1% ; x5= 5 pixels left border
	
  ; change font to courier for the code section.
  Gui, 1:Font, c%fontColor% s%fontSize%, Courier New
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
	
  Menu, FileMenu, Add, Save settings, MenuHandler
  ; Menu, FileMenu, Disable, Save settings
	
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
  
  ; next icon is used only in the uncompiled script.
  ;@Ahk2Exe-IgnoreBegin
  if (!A_IsCompiled)
	  Menu, Tray, Icon, %A_ScriptDir%\shell32_16806.ico ;shell32.dll, 85
  ;@Ahk2Exe-IgnoreEnd
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

  !F2::
  showSettings()()  ;{ <-- settings
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

  F12::
    GuiControlGet, outputvar1, Pos, MyTreeView
    GuiControlGet, outputvar2, Pos, MyListBox
    output := "treview:`n"
    output .= "`tX=" . outputvar1X . "`tY=" . outputvar1Y . "`tW=" . outputvar1W . "`tH=" . outputvar1H
    output .= "`n"
    output .= "listbox:`n"
    output .= "`tX=" . outputvar2X . "`tY=" . outputvar2Y . "`tW=" . outputvar2W . "`tH=" . outputvar2H

    Msgbox, %output%
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
    return
	}
	
    ; doubleclick an item: open code in default editor and position to selected routine.
	if (A_GuiEvent = "DoubleClick") {
		statements := []
		routineName := ""
		sourceCode := ""
		IniRead, showOnlyRoutine, %A_ScriptDir%\%scriptNameNoExt%.ini, general, showOnlyRoutine
		
		TV_GetText(routineName, TV_GetSelection())   ; get item text
		statements := findRoutineFirstStatement(routineName)
		statement := statements[1]
    		
		WinGetPos, X_main, Y_main, Width_main, Height_main, A
		actWin := WinExist("A")
		GetClientSize(actWin, Width_main, Height_main)
    x := X_main + Width_main
    y := Y_main
		
    FileEncoding, CP1253 

		if (showOnlyRoutine == "false")
			if (codeEditor == "notepad++") {
				RunWait, notepad++.exe -l%language% -nosession -ro -n%statement% -x%x% -y%y% "%fullFileCode%"
      }
		else {
			RunWait, "C:\Program Files\Microsoft VS Code\Code.exe" --new-window --goto "%fullFileCode%:%statement%"
    }
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
				RunWait, notepad++.exe -l%language% -nosession -ro -x%x% -y%y% "%filename%"
			else
				RunWait, "C:\Program Files\Microsoft VS Code\Code.exe" --new-window "%filename%"
		}
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

  winHeight := A_GuiHeight
  ; msgbox, % A_GuiHeight - gui_offset

  ; Otherwise, the window has been resized or maximized. Resize the controls to match.
  GuiControl, Move, MyTreeView, % "H" . (A_GuiHeight - gui_offset) . " W" . TreeViewWidth ; -30 for StatusBar and margins.
	
  ; 0x100 = Include 0x100 in Options to turn on the LBS_NOINTEGRALHEIGHT style. This forces the ListBox to be exactly the height specified rather than a height that prevents a partial row from appearing at the bottom. This option also prevents the ListBox from shrinking when its font is changed
	GuiControl, Move, MyListBox, % 0x100 "X" . LVX . " H" . (A_GuiHeight - gui_offset ) . " W" . (A_GuiWidth - TreeViewWidth - 10) ; width = total - treeview - (2 X 5) margins.
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
	if (searchText != "")
		searchItemInRoutine(searchText, "next")
	else {
		GuiControlGet, searchText, ,MyEdit_code  ;get search text from input field
		if (searchText != "")
			item := searchItemInCode(searchText, "next")
    if (item > 0)
		  GuiControl, Choose, MyListBox, %item%
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
    if (!fileSelector(path))
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

  if (A_ThisMenuItem = "Save settings") {
    saveSettings()
    Progress, zh0 fs10, % "Settings saved"
    sleep, 500
    Progress, off
    return
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

  WinGet, isMinimized , MinMax, ahk_id %guiHWND%
  ; msgbox, % isMinimized "-------" guiHWND

  ; on exit save position & size of window
  ; but if it is minimized skip this step.
  if (isMinimized = -1 or saveOnExit != "true")
    Return

  ; on exit save position & size of window
  ; but if it is minimized skip this step.
  ; actWin := WinExist("A")
  ; WinGet, isMinimized , MinMax, actWin

  WinGetPos, winX, winY, winWidth, winHeight, ahk_id %guiHWND%
  
  ; save X, Y that are absolute values.
  IniWrite, %winX%, %A_ScriptDir%\%scriptNameNoExt%.ini, position, winX
  IniWrite, %winY%, %A_ScriptDir%\%scriptNameNoExt%.ini, position, winY
  
  ; save absolute values of W,H.
  IniWrite, %winWidth%, %A_ScriptDir%\%scriptNameNoExt%.ini, position, actualWinWidth
  IniWrite, %winHeight%, %A_ScriptDir%\%scriptNameNoExt%.ini, position, actualWinHeight
  
  GetClientSize(guiHWND, winWidth, winHeight)
  ; GetClientSize(actWin, winWidth, winHeight)
  
  ; save client values of W,H (used by winmove)
  IniWrite, %winWidth%, %A_ScriptDir%\%scriptNameNoExt%.ini, position, winWidth
  IniWrite, %winHeight%, %A_ScriptDir%\%scriptNameNoExt%.ini, position, winHeight

  if (treeviewWidth > 0)
  	IniWrite, %treeviewWidth%, %A_ScriptDir%\%scriptNameNoExt%.ini, position, treeviewWidth

  if (fontSize > 0)
	  IniWrite, %fontSize%, %A_ScriptDir%\%scriptNameNoExt%.ini, font, size

  ; if filenames are non blank save also.
  if (fileRoutines <> "")
    IniWrite, %fileRoutines%, %A_ScriptDir%\%scriptNameNoExt%.ini, files, fileRoutines
  if (fileCode <> "")
    IniWrite, %fileCode%, %A_ScriptDir%\%scriptNameNoExt%.ini, files, fileCode
  
  ; save export settings
  if (exportMaxLevel <> "")
    IniWrite, %exportMaxLevel%, %A_ScriptDir%\%scriptNameNoExt%.ini, export, exportMaxLevel
  if (exportDescriptions <> "")
    IniWrite, %exportDescriptions%, %A_ScriptDir%\%scriptNameNoExt%.ini, export, exportDescriptions
  if (exportOutputFormat <> "")
    IniWrite, %exportOutputFormat%, %A_ScriptDir%\%scriptNameNoExt%.ini, export, exportOutputFormat
  if (exportConnectorsType <> "")
    IniWrite, %exportConnectorsType%, %A_ScriptDir%\%scriptNameNoExt%.ini, export, exportConnectorsType


  ; timestamp
  FormatTime, currentTimestamp,, yyyy-MM-dd hh:mm:ss
  FileEncoding, CP1253 
  IniWrite, %currentTimestamp%, %A_ScriptDir%\%scriptNameNoExt%.ini, general, lastSavedTimestamp
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
  ;-------------------------------------------------
  ; find number of monitors and their sizes
  ; keep min left, max right, max bottom
  ;-------------------------------------------------
getMonitorsSizes(Byref minLeft := 0, ByRef maxRight := 0, ByRef maxBottom := 0) {
  minLeft := 0
  maxRight := 0
  maxBottom := 0
  sysget, monitorCount, MonitorCount
  Loop, %monitorCount%
    {
      SysGet, Mon%A_Index%, Monitor, %A_Index%
      if (Mon%A_Index%Left < minLeft)
        minLeft := Mon%A_Index%Left
      if (Mon%A_Index%Right > maxRight)
        maxRight := Mon%A_Index%Right
      if (Mon%A_Index%Bottom > maxBottom)
        maxBottom := Mon%A_Index%Bottom
    }
  }
  ;---------------------------------------------------------------------
  ; adjust gui size and position to real display(s)
  ;---------------------------------------------------------------------
adjustGui_SizePosition(Byref winX, Byref winY, Byref winWidth, Byref winHeight, Byref minLeft, Byref maxRight, Byref maxBottom) {
  
  ; if left, right, bottom are beyond boundaries adjust them.
  if (winX < minLeft - 7)
    winX := minLeft - 7
  if (winX > maxRight - winWidth)
    winX := maxRight - winWidth
  if (winY > maxBottom - winHeight - 30)
    winY := maxBottom - winHeight - 30

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
  currThread := []
	processRoutine(currRoutine)
  }
    ;---------------------------------------------------------------------
    ; recursively write routines array to a text file for testing.
    ; currRoutine = item in allRoutines[]
    ; parentID = the parent node (in a treeview)
    ; parentName
    ;---------------------------------------------------------------------
processRoutine(currRoutine, parentID=0, parentName="") {
	static currentLevel

  ; check if new routine exists in this thread: if it exists don't process it again.
  currentName := currRoutine.routineName

  ; if (currentName = "X3000-READ-T8Z38") {
    ;  MsgBox, % currentName
  ;  }

  threadIndex := searchArray(currentName)
  if (threadIndex > 0)
    return
  
  currentLevel ++

  currThread.push(currentName)  ; add new routine to this thread.
	itemId := addToTreeview(currRoutine, currentLevel, parentID, parentName)
	; itemId := addToTreeview(currentName, currentLevel, parentID, parentName)
	
	Loop, % currRoutine.calls.MaxIndex() {
		
        ; search array allRoutines[] for the current routine item.
		calledId := searchRoutine(currRoutine.calls[A_Index])

		if (calledId > 0 and currRoutine <> allRoutines[calledId]) {
			processRoutine(allRoutines[calledId], itemId, currentName)     ; write children
		}
	}

  value := currThread.pop()
	currentLevel --
  }
    ;---------------------------------------
    ; add a node to treeview
    ;---------------------------------------
addToTreeview(currRoutine, currentLevel, parentId, parentName) {
	currentId := TV_add(currRoutine.routineName, parentId, "Expand")
	
    ; save routine level for later tree traversal.
	levels_LastIndex += 1
  itemLevels[levels_LastIndex, 1] := currentId    ; current node's TV id
  itemLevels[levels_LastIndex, 2] := currentLevel ; current node's level
  itemLevels[levels_LastIndex, 3] := currRoutine.routineName  ; current node's TV text
  itemLevels[levels_LastIndex, 4] := parentId     ; parent node's TV id
  itemLevels[levels_LastIndex, 5] := parentName
  itemLevels[levels_LastIndex, 6] := "" ; used only in export to html2 (flowchart)

  followsSibling := false
  parentIndex := searchItemId(parentId)
  if (parentIndex > 0) {
    parentName := itemLevels[parentIndex, 3]
    callsIndex := searchRoutine(parentName)
    if (callsIndex > 0) {
      Loop, % allRoutines[callsIndex].calls.MaxIndex() - 1 {
        if (allRoutines[callsIndex].calls[A_Index] = currRoutine.routineName)
          followsSibling := true
      }
    }
  }
  itemLevels[levels_LastIndex, 7] := followsSibling  ; if it has a sibling after itself.
  itemLevels[levels_LastIndex, 8] := currRoutine.startStmt  ; routine starting stmt
  itemLevels[levels_LastIndex, 9] := currRoutine.endStmt  ; routine ending stmt
	
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
  ; export nodes to the requested format.
  ;-------------------------------------------------------------------------------
exportNodes(expandAll, index1=0, index2=0) {

  if (index1 = 0 or index2 = 0 or index1 > index2) {
    index1 := 1
    index2 := itemLevels.MaxIndex()
  }
  if (exportMaxLevel < 2 or exportMaxLevel > 999)
    exportMaxLevel := 999

  if (exportOutputFormat = "json" or exportOutputFormat = "html1")
    treeString := exportNodesAsHTML1(expandAll, index1, index2)

  if (exportOutputFormat = "txt")
    treeString := exportNodesAsTXT(expandAll, index1, index2)
  
  if (exportOutputFormat = "html2")
    treeString := exportNodesAsHTML2(expandAll, index1, index2)
  
  return treeString
  }
  ;-------------------------------------------------------------------------------
  ; export nodes to html/json string - show as treeview
  ;   expandAll = true : export all nodes
  ;   expandAll = false : export only the shown nodes
  ;   index1, index2 = from item to item
  ;-------------------------------------------------------------------------------
exportNodesAsHTML1(expandAll, index1, index2) {
  ; used only in showPrograms.ahk
  ; find max level when descriptions are to be exported.
  ; if (exportDescriptions = "true")
  ;   maxLevel := findexportMaxLevel(index1, index2) 
  nodesArray := []
  currIndex := index1

  while (currIndex <= index2) {

    ; ignore current node if it's level is greater than requested.
    if (itemLevels[currIndex, 2] > exportMaxLevel) {
      currIndex ++
      continue
    }

    if (expandAll = false) {
      if (TV_Get(itemLevels[currIndex, 1], "Expanded"))
        isOpen := "true"
      else
        isOpen := "false"
    } else
        isOpen := "true"
    
    newNode := {}
    newNode.open := isOpen
    newNode.id := itemLevels[currIndex, 1]
    newNode.pId := itemLevels[currIndex, 4]

    routineName := itemLevels[currIndex, 3]

    if (exportDescriptions = "true") {
      ; used only in showPrograms.ahk
      ; outputRoutineName := addDashesToRoutineName(routineName, itemLevels[currIndex, 2])
      ; outputRoutineName .= searchRoutineDescription(routineName)
      outputRoutineName := routineName
    } else
      outputRoutineName := routineName

    newNode.name := outputRoutineName
    newNode.start := itemLevels[currIndex, 8]
    newNode.end := itemLevels[currIndex, 9]

    nodesArray.push(newNode)
    currIndex ++
  }

  ; convert ahk array of objects into string (adds quotes).
  stringifiedArray := JSON.Dump(nodesArray)
  ; stringifiedArray := RegExReplace(stringifiedArray, """id"":", "id:")

  return stringifiedArray
  }
  ;-------------------------------------------------------------------------------
  ; export nodes to text file - show as treeview
  ;   expandAll = true : export all nodes / false : export only the shown nodes
  ;   index1, index2 = from item to item
  ;-------------------------------------------------------------------------------
exportNodesAsTXT(expandAll, index1, index2) {
  exportedRoutines := []
  exportedString := ""
  currIndex := index1
  currLine := 1
  prefix := ""

  connector1 := exportConnectorsType == "Unicode" ? "├──" : "|__"
  connector2 := exportConnectorsType == "Unicode" ? "└──" : "\__"
  connector3 := exportConnectorsType == "Unicode" ? "│  " : "|  "

  while (currIndex <= index2) {
  
    currentLevel := itemLevels[currIndex, 2]
    
    ; ignore current node if it's level is greater than requested.
    if (currentLevel > exportMaxLevel) {
      currIndex ++
      continue
    }

    ; calc prefix string length (before the |__routine ).
    prefixCount := (currentLevel - 1) * 3   ; 3 spaces for each previous level.
    if (currLine > 1) {
      prefix := SubStr(exportedRoutines[currLine - 1], 2, prefixCount)

      parentIndex := searchItemId(itemLevels[currIndex, 4])
      parentHasSibling := itemLevels[parentIndex, 7]
      ; if parent has sibling clear the last 2 chars and replace ├ with │
      if (parentHasSibling)
        prefix := SubStr(prefix, 1, StrLen(prefix) - 3) . connector3
      ; if parent hasn't sibling clear the last 3 chars
      else
        prefix := SubStr(prefix, 1, StrLen(prefix) - 3) . "   "
      
      ; add new line char
      prefix := "`n" . prefix
    }

    if (currentLevel > 1)
      if (itemLevels[currIndex, 7] = true)
        prefix .= connector1 ; has sibling after itself
      else
        prefix .= connector2 ; has no sibling after itself

    oneLine := prefix . itemLevels[currIndex, 3]  ; add routine name.

    exportedRoutines.push(oneLine)

    ; if requested only visible nodes
    ; and current node is folded, find next node with level <= current node's level.
    if (!expandAll and !TV_Get(itemLevels[currIndex, 1], "Expanded")) {
      found := false
      while (currIndex < itemLevels.MaxIndex()) {
        currIndex ++
        if (itemLevels[currIndex, 2] <= currentLevel) {
          found := true
          break
        }
      }
      if (found = false)
        currIndex ++
    } else {
      currIndex ++
    }

    currLine ++
  }
  
  ; exportedString := "1234567890123456789012345678901234567890123456789012345678901234567890`n"
  Loop, % exportedRoutines.MaxIndex() {
    exportedString .= exportedRoutines[A_Index]
  }
  
  return exportedString
  }
  ;-------------------------------------------------------------------------------
  ; export nodes to text pug file - show as flowchart
  ;   expandAll = true : export all nodes / false : export only the shown nodes
  ;   index1, index2 = from item to item
  ;-------------------------------------------------------------------------------
exportNodesAsPUG(expandAll, index1, index2) {
  exportedRoutines := []
  exportedString := ""
  currIndex := index1
  isRoot := True

  while (currIndex <= index2) {
  
    currentLevel := itemLevels[currIndex, 2]
    
    ; ignore current node if it's level is greater than requested.
    if (currentLevel > exportMaxLevel) {
      currIndex ++
      continue
    }

    ; for the root item create also the header.
    if (isRoot) {
      oneLine := "figure"
      exportedRoutines.push(oneLine)
      oneLine := "`n figcaption Example DOM structure diagram"
      exportedRoutines.push(oneLine)
      oneLine := "`n ul(class='tree')"
      exportedRoutines.push(oneLine)
      oneLine := "`n  li"
      exportedRoutines.push(oneLine)
      oneLine := "`n   code " . itemLevels[currIndex, 3]  ; add routine name.
      exportedRoutines.push(oneLine)
      previousLevel := itemLevels[currIndex, 2]
      
      isRoot := False
      currIndex ++
      continue  ; go to next item (node)
    }

    ; for the children create ul/li statements.
    currPos := 2 * currentLevel
    if (currentLevel > previousLevel) {
      oneLine := "`n" . Spaces(currPos - 1) . "ul"
      exportedRoutines.push(oneLine)
    }

    currPos ++
    oneLine := "`n" . Spaces(currPos - 1) . "li"
    exportedRoutines.push(oneLine)

    currPos ++
    oneLine := "`n" . Spaces(currPos - 1) . "code " . itemLevels[currIndex, 3]  ; add routine name.
    exportedRoutines.push(oneLine)

    previousLevel := currentLevel
    currIndex ++
  }
  
  Loop, % exportedRoutines.MaxIndex() {
    exportedString .= exportedRoutines[A_Index]
  }
  
  return exportedString
  }
  ;-------------------------------------------------------------------------------
  ; export nodes to html - show as flowchart
  ;   expandAll = true : export all nodes / false : export only the shown nodes
  ;   index1, index2 = from item to item
  ;-------------------------------------------------------------------------------
exportNodesAsHTML2(expandAll, index1, index2) {
  exportedString := ""
  currIndex := index1
  isRoot := True
  firstChild := True

  try
    ; create an XMLDOMDocument object
    ; set its top-level node
    xmlObj := new xml("<figure/>")
  catch pe ; catch parsing error(if any)
	  MsgBox, 16, PARSE ERROR
    , % "Exception thrown!!`n`nWhat: " pe.What "`nFile: " pe.File
    . "`nLine: " pe.Line "`nMessage: " pe.Message "`nExtra: " pe.Extra
  
  ; if root element is null then exit.
  if !xmlObj.documentElement
    return

  while (currIndex <= index2) {
  
    currentLevel := itemLevels[currIndex, 2]
    
    ; ignore current node if it's level is greater than requested.
    if (currentLevel > exportMaxLevel) {
      currIndex ++
      continue
    }

    ;------------------------------------------
    ; for the root item create also the header.
    ;------------------------------------------
    if (isRoot) {
      xmlObj.addElement("figcaption", "//figure", {name: "figcaption"}, "Example DOM structure diagram")
      xmlObj.addElement("ul", "figure", {class: "tree"})              ; <ul class="tree">
      nodeLI := xmlObj.addElement("li", "//ul")                         ; <li></li>
      xmlObj.addElement("code", "//li", itemLevels[currIndex, 3])     ; <code>root routine</code>
      itemLevels[currIndex, 6] := nodeLI  ; save root node object for later reference.

      ; write root's calls as ul/li.
      allRoutinesIndex := searchRoutine(itemLevels[currIndex, 3]) ; find the calls of current routine.
      if (allRoutinesIndex > 0) {
        Loop, % allRoutines[allRoutinesIndex].calls.MaxIndex() {
          ; if first call, write a ul under parent li.
          if (A_Index = 1) {
            nodeUL := xmlObj.addElement("ul", nodeLI)
            searchRoutine_fromIndex := currIndex + 1  ; next routine search : to avoid getting the wrong item when duplicates exist.
          }
          newnode:= xmlObj.addElement("li", nodeUL)
          calledRoutineName := allRoutines[allRoutinesIndex].calls[A_Index]            
          xmlObj.addElement("code", newnode, calledRoutineName)  ; write <code>called routine</code>
          index_in_itemLevels := searchRoutine_inItemLevels(searchRoutine_fromIndex, calledRoutineName, allRoutines[allRoutinesIndex].routineName )
          searchRoutine_fromIndex := index_in_itemLevels + 1  ; to avoid getting the wrong routine when duplicates exist : ignore previous items.
          itemLevels[index_in_itemLevels, 6] := newnode  ; save current li node for later reference.
        }
      }

      isRoot := False
      getNextIndex(currIndex, currentLevel, expandAll)
      ; currIndex ++
      continue  ; go to next item
    }

    ;-------------------------------------------
    ; for the children write the calls as ul/li.
    ;-------------------------------------------
    allRoutinesIndex := searchRoutine(itemLevels[currIndex, 3]) ; find the calls of current routine.
    if (allRoutinesIndex > 0) {

      ; if requested "export what you see" and node is folded: skip the called routines.
      if (!expandAll and !TV_Get(itemLevels[currIndex, 1], "Expanded")) {
        getNextIndex(currIndex, currentLevel, expandAll)
        continue  ; go to next item
      }

      Loop, % allRoutines[allRoutinesIndex].calls.MaxIndex() {

        ; if first call, write a ul under parent li.
        if (A_Index = 1) {
          if (itemLevels[currIndex, 6] == null) {
            msgbox, % "itemLevels[currIndex, 6] is null for currIndex =" . currIndex . "-" . itemLevels[currIndex, 5] . "`nallRoutinesIndex =" . allRoutinesIndex . "-" . itemLevels[currIndex, 3]
            currIndex ++
            continue
          }            
          nodeUL := xmlObj.addElement("ul", itemLevels[currIndex, 6]) ; nodeLI = parent's li
          searchRoutine_fromIndex := currIndex + 1  ; next routine search : to avoid getting the wrong item when duplicates exist.
        }
        newnode:= xmlObj.addElement("li", nodeUL)
        calledRoutineName := allRoutines[allRoutinesIndex].calls[A_Index]          
        xmlObj.addElement("code", newnode, calledRoutineName)  ; write <code>routine</code>
        index_in_itemLevels := searchRoutine_inItemLevels(searchRoutine_fromIndex, calledRoutineName, allRoutines[allRoutinesIndex].routineName)
        searchRoutine_fromIndex := index_in_itemLevels + 1  ; next routine search : to avoid getting the wrong item when duplicates exist.
        itemLevels[index_in_itemLevels, 6] := newnode  ; save current li node for later reference.                    
      }        
    }

    getNextIndex(currIndex, currentLevel, expandAll)
    ; currIndex ++
  }

  ; transform into xml and return for further processing.
  xmlObj.transformXML()
  return xmlObj.xml ; this contains the full xml
  }
  ;-------------------------------------------------------------------------------
  ; used when exporting only visible nodes.
  ;-------------------------------------------------------------------------------
getNextIndex(Byref currIndex, currentLevel, expandAll) {
  ; if requested only visible nodes
  ; and current node is folded, find next node with level <= current node's level.
  if (!expandAll and !TV_Get(itemLevels[currIndex, 1], "Expanded")) {
    found := false
    while (currIndex < itemLevels.MaxIndex()) {
      currIndex ++
      if (itemLevels[currIndex, 2] <= currentLevel) {
        found := true
        break
      }
    }
    if (found = false)
      currIndex ++
  } else {
    currIndex ++
  }
  }
  ;-------------------------------------------------------------------------------
  ; create a string with the given number of spaces
  ;-------------------------------------------------------------------------------
Spaces(count)
  {
    strSpaces := ""
    loop % count
      strSpaces .= A_Space
   return strSpaces
  }
  ;-------------------------------------------------------------------------------
  ; export nodes to text file
  ; (returns the created string)
  ;-------------------------------------------------------------------------------
exportMarked() {
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

  ; export selected nodes.
  expandAll := true
  exportedString := exportNodes(expandAll, index1, index2)
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
  ;---------------------------------------------------------------------
  ; search if parameter exists in itemLevels array.
  ;---------------------------------------------------------------------
searchRoutine_inItemLevels(searchRoutine_fromIndex, routineName, parentName) {
  index := searchRoutine_fromIndex
  while (index <= itemLevels.MaxIndex()) {
		if (routineName = itemLevels[index, 3] && parentName = itemLevels[index, 5]) {
			return index
		}
    index ++
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
    
  ; set encoding to windows-1253 otherwise greek text is not shown correctly.
  FileEncoding, CP1253
  
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
			statements[1] := allRoutines[calledId].startStmt
			statements[2] := allRoutines[calledId].endStmt
			; statements[1] := substr(allRoutines[calledId].startStmt, 1, 4)
			; statements[2] := substr(allRoutines[calledId].endStmt, 1, 4)
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
		from_line_number := allRoutines[calledId].startStmt
		to_line_number := allRoutines[calledId].endStmt
		; from_line_number := substr(allRoutines[calledId].startStmt, 1, 4)
		; to_line_number := substr(allRoutines[calledId].endStmt, 1, 4)
	} else {
		from_line_number := 3103
		to_line_number := 3117
	}
	
	line_number := from_line_number
	while (line_number <= to_line_number) {
		sourceCode .= allcode[line_number] . "|"
		line_number ++
	}
	
  GuiControlGet, MyTreeView, Pos  ; get treeview height and use it to the listbox.
  currenttH := MyTreeViewH
  ; if (MyTreeViewH != winHeight - 60)
  ;   Msgbox, % MyTreeViewH . "---" . winHeight

  ; msgbox, %currenttH%
  ; msgbox, %winHeight% . "---" . %MyTreeViewH%

	updateStatusBar(SelectedItemText)
	GuiControl, -Redraw, MyListBox
	GuiControl,,MyListBox, |
	GuiControl,,MyListBox, %sourceCode%
	GuiControl, +Redraw, MyListBox
	GuiControl, Move, MyListBox, % "H" . (winHeight - 60)
  }
    ;-------------------------------------------------------
    ; read cbtreef5.txt file and populate routines array
    ;-------------------------------------------------------
populateRoutines() {
	Loop, Read, %fullFileRoutines%
	{
		tmpRoutine := parseLine(A_LoopReadLine)     ; parse line into separate fields.
    if (A_Index = 1)
      tmpRoutine.STMLAST := allCode.MaxIndex()
		
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
	; calledBy := ""
	startStmt := ""
	endStmt := ""
	callingStmt := ""
	calls := []
  }
  ;------------------------------------------------------------------
  ; get file selection from user, using given path and file filter.
  ; populates global fields: fullFileRoutines, fullFileCode
  ;------------------------------------------------------------------
fileSelector(homePath) {
  filter := "(*.cbl*; *.rpg*)"
	FileSelectFile, fullFileCode, 1, %homePath% , Select routines file, %filter%
	
	if (ErrorLevel = 1) {    ; cancelled by user
		return False
	}
	
	SplitPath, fullFileCode , FileName, Dir, Extension, NameNoExt, Drive
  fileCode := FileName
  fileRoutines := NameNoExt . ".txt"
  parseCode := True

	return true
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
  row := "`t`t`t allRoutines[]`n`n"
  FileAppend, %row%, %filename%

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
  row := "`n`t`t`t itemLevels[]"
  row .= "`n`nseq -   node id -  level - routine              -   parent id - parent name         - has sibling - start stmt - end stmt`n"
  row .= "-----------------------------------------------------------------------------------------------------------------------------`n"

  Loop, % itemLevels.MaxIndex() {
    row .= Format("{:3}", A_Index) . " : " . Format("{:10}", itemLevels[A_Index, 1]) . " - " . Format("{:5}", itemLevels[A_Index, 2]) . " - " . Format("{:-20}", itemLevels[A_Index, 3]) . " - " . Format("{:10}", itemLevels[A_Index, 4]) . " - " . Format("{:-20}", itemLevels[A_Index, 5]) . " - " . Format("{:5}", itemLevels[A_Index, 7]) . " - " . Format("{:10}", itemLevels[A_Index, 8]) . " - " . Format("{:10}", itemLevels[A_Index, 9]) . "`n"
  }
    FileAppend, %row%, %filename%
  } 