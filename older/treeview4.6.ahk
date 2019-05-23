;--------------------------------------------------------------------------------------
; Version with text instead of listview and constant input file.
;
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
; DONE: use treeview in place of txt file for recursive process.
; DONE: create treeview4.3.ahk new version of treeview4.2.ahk.
; DONE: remove routine write_toFile_sequentially.
; DONE: in routine write_toFile_recursively instead of writting to text file call routine to write to treeview.
; DONE: add all UI logic from treeview3.ahk:
;   DONE: itemLevels[] array must be populated in order to function search/fold properly
;   DONE: current routine level = is only known inside processRoutine() (static var?)
; DONE: add listview right to treeview with currently selected routine source.
; DONE: in array of called routines store the actual statement
;--------------------------------------------------------------------------------------
; TODO: show the actual statement number.
; TODO: replace listview with text in order to compress the lines.
;--------------------------------------------------------------------------------------

global allRoutines  ; array of class "routine"
global allCode      ; array of source code to show
global tmpRoutine 
global filenameRoutines     ; text file with all routine calls, is the output from AS400.
global filenameCode         ; text file with source code.
global itemLevels
global levels_LastIndex

initialize()
populateRoutines()
populateCode()
loadTreeview()

Gui, Show
; Gui, guicode:show
return

;---------------------------------------
; define shortcut keys
;---------------------------------------
#IfWinActive ahk_class AutoHotkeyGUI
; #IfWinActive ahk_exe AutoHotkey.exe
    global searchText

    !q::
    Reload
    return

    !a::
    WinGetActiveTitle, Title
    MsgBox, The active window is "%Title%".
    return

    ^f::    ; ctrl F = F1 = search forward
    GuiControlGet, searchText, ,MyEdit  ;get search text from input field
    searchItem(searchText, "next")
    return

    F1::
    GuiControlGet, searchText, ,MyEdit  ;get search text from input field
    searchItem(searchText, "next")
    return

    F2::
    GuiControlGet, searchText, ,MyEdit  ;get search text from input field
    searchItem(searchText, "previous")
    return

    F3::
    processAll("-Expand")
    return

    F4::
    processAll("Expand")
    return

    F5::
    processChildren(TV_GetSelection(), "-Expand")
    return

    F6::
    processChildren(TV_GetSelection(), "Expand")
    return

    F7::
    processSameLevel(TV_GetSelection(), "-Expand")
    return

    F8::
    processSameLevel(TV_GetSelection(), "Expand")
    return

#IfWinActive

;---------------------------------------
; initialize variables (global)
;---------------------------------------
initialize() {
    allRoutines := []
    allCode := ""
    tmpRoutine  := {}
    itemLevels := []
    levels_LastIndex := 0
    path := ""

    ; file to process (routine calls)
    txtFileRoutines := "cbtreef5.txt"
    ; file to process (routines code)
    txtFileCode := "MPMDL001.CBLLE"

    user := getSystem()

    if (user = "SYSTEM_WORK")
        path := "H:\MY DATA\temp\projects\tree cobol program\"
    if (user ="SYSTEM_HOME")
        path := "D:\_files\nic\pc-setups\AutoHotkey macros\cbtree\" 
    filenameRoutines := path . txtFileRoutines
    filenameCode := path . txtFileCode

    ; UI init
    global TreeViewWidth := 400
    global TextWidth := 700 - TreeViewWidth - 30
    global MyTreeView, MyText, MyEdit

    ; Create an ImageList and put some standard system icons into it:
    ImageListID := IL_Create(5)
    Loop 5 
        IL_Add(ImageListID, "shell32.dll", A_Index)

    Gui new,, %txtFileCode%    
    Gui +Resize
    Gui, Add, Edit, r1 vMyEdit w150             ; text box, r1= 1 row
    Gui, Add, Button, x+1 Hidden Default, OK    ; hidden button to catch enter key! x+1 = show on same line with textbox
    Gui, Add, TreeView, vMyTreeView r80 w%TreeViewWidth% x5 gMyTreeView AltSubmit ImageList%ImageListID% ; x5= 5 pixels left border
    Gui, Add, Text, vMyText  w%TextWidth% x+5, Routine name: (click any routine to show the code)

    Menu, MyContextMenu, Add, Find next (F1), contextMenuHandler
    Menu, MyContextMenu, Add, Find previous (F2), contextMenuHandler
    Menu, MyContextMenu, Add, Show routine code (Left click), contextMenuHandler
    Menu, MyContextMenu, Add    ; blank line
    Menu, MyContextMenu, Add, Fold all (F3), contextMenuHandler
    Menu, MyContextMenu, Add, Unfold all (F4), contextMenuHandler
    Menu, MyContextMenu, Add, Fold recursively (F5), contextMenuHandler
    Menu, MyContextMenu, Add, Unfold recursively (F6), contextMenuHandler
    Menu, MyContextMenu, Add, Fold same level (F7), contextMenuHandler
    Menu, MyContextMenu, Add, Unfold same level (F8), contextMenuHandler
}
;-----------------------------------------------------------
; Handle enter key. 
;-----------------------------------------------------------
ButtonOK:
{
    GuiControlGet, searchText, ,MyEdit  ;get search text from input field
    searchItem(searchText, "next")
    
    ; Gui, Submit, NoHide
    ; send {F1}
    return
}
;-----------------------------------------------------------
; Handle user actions (such as clicking). 
;-----------------------------------------------------------
MyTreeView:
{
    ; click an item: load routine code
    if (A_GuiEvent = "S") {
        TV_GetText(SelectedItemText, A_EventInfo)   ; get item text
        loadText(SelectedItemText)                  ; load routine code into text control
    }
    
    ; doubleclick an item: search the treeview
    if (A_GuiEvent = "DoubleClick") {
        TV_GetText(SelectedItemText, A_EventInfo)   ; get item text
        GuiControl, , MyEdit , %SelectedItemText%   ; put it into search field
        searchItem(searchText, "next")
    }

    ; spacebar an item: load the routine code.
    if (A_GuiEvent = "K" and A_EventInfo = 32) {
        msgbox, % "[" A_EventInfo "]"   ; A_EventInfo contains the ascii character as number
    }



    return
}

GuiSize:  ; Expand/shrink the Text and TreeView in response to user's resizing of window.
{
    if (A_EventInfo = 1)  ; The window has been minimized. No action needed.
        return
    ; Otherwise, the window has been resized or maximized. Resize the controls to match.
    GuiControl, Move, MyTreeView, % "H" . (A_GuiHeight - 30)  ; -30 for StatusBar and margins.
    GuiControl, Move, MyText, % "H" . (A_GuiHeight - 30) . " W" . (A_GuiWidth - TreeViewWidth - 15) ; width = total - treeview - (3 X 5) margins.
    
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

GuiClose:  ; Exit the script when the user closes the TreeView's GUI window.
    ExitApp

    ;-----------------------------------------------------------
    ; Handle context menu actions
    ;-----------------------------------------------------------
contextMenuHandler:
    if (A_ThisMenuItem = "Find next") 
        gosub findNext
    if (A_ThisMenuItem = "Find previous")
        gosub findPrevious
    if (A_ThisMenuItem = "Show routine code (spacebar)") {
        TV_GetText(SelectedItemText, A_EventInfo)   ; get item text
        ;loadListview(SelectedItemText)
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
findNext:
findPrevious:
    return

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
    
    ; global
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

    ; global
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
; search the text entered in MyEdit control
;-----------------------------------------------------------
searchItem(searchText, direction) {

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
        foundPos := InStr(itemLevels[current_index, 3], searchText, false, 1)
        if (foundPos > 0) {
            TV_Modify(itemLevels[current_index, 1])     ;select found node
            found := true
            break
        }        
    }
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
    currentId := TV_add(routineName, parentRoutine, "Icon4 Expand")
    
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
;-----------------------------------------------------------------------
; read mpmdl001.cblle file and populate listview with one routine's code
;-----------------------------------------------------------------------
populateCode() {
    FileRead, allCode, %filenameCode%
}
;-----------------------------------------------------------------------
; load text control with the routine code (source)
;-----------------------------------------------------------------------
loadText(routineName) {
    GuiControl, -Redraw, MyText
    from_line_number := 0
    to_line_number := 0
    foundStartPos := 0
    foundEndPos := 0

    ; find the routine and the start/end statements inside the source.
    calledId := searchRoutine(routineName)
    if (calledId > 0) {
        from_line_number := substr(allRoutines[calledId].startStmt, 1, 4)
        to_line_number := substr(allRoutines[calledId].endStmt, 1, 4)
    } else {
        from_line_number := 3103
        to_line_number := 3117
    }

    ; find start line number 
    foundStartPos := InStr(allCode, from_line_number, false, 1) ;false=case insensitive, 1=from position
    if (foundStartPos > 0) {
        foundEndPos := InStr(allCode, to_line_number, false, foundStartPos)
    }

    GuiControl, Text, MyText, % substr(allCode, foundStartPos, foundEndPos - foundStartPos + 1)
    GuiControl, +Redraw, MyText
    Gui, Font, s08, Courier New
    GuiControl, Font, MyText
}
;-------------------------------------------------------
; read cbtreef5.txt file and populate routines array
;-------------------------------------------------------
populateRoutines() {
    Loop, Read, %filenameRoutines%
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