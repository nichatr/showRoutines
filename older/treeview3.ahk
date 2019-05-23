#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

; FileDelete, test1.txt    ; TODO: delete
initialize()
loadTreeview()

Gui, Show
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
; load treeview
;---------------------------------------
loadTreeview() {

    global

    Loop, Read, % filename 
    {
        inputLine := Substr(A_LoopReadLine, 2)       ; ignore first blank!
        foundPos := searchRoutine(inputLine)
        if (foundPos = 0)
            Continue

        currentRoutine := Substr(inputLine, foundPos+3)
        currentLevel := Round((foundPos + 1) / 3, 0)              ;1,2,3...

        ; first routine
        if (previousRoutine = "" ) {
            currentId := addToTreeview(currentRoutine, 0)  ;first node
            parentItemIDs.Push(0)

            index ++
        }
        ; same level
        else if (currentLevel = index) {
            currentId := addToTreeview(currentRoutine, parentItemIDs[index])    ;sibling
        }
        ; down one level (subroutine)
        else if (currentLevel > index) {
            parentItemIDs.Push(currentId)
            index ++
            currentId := addToTreeview(currentRoutine, parentItemIDs[index])    ;child
        }
        ; up x levels
        else if (currentLevel < index) {
            Loop, % index - currentLevel
            {
                parentItemIDs.Pop()
                index --
            }
            currentId := addToTreeview(currentRoutine, parentItemIDs[index])   ;child
        }

        previousRoutine := currentRoutine
        previousId := currentId
    }

}
;---------------------------------------
; add a node to treeview
;---------------------------------------
addToTreeview(routineName, parentRoutine) {
    global
    currentId := TV_add(routineName, parentRoutine, "Icon4 Expand")
    
    ; save routine level for later tree traversal.
    levels_LastIndex += 1
    itemLevels[levels_LastIndex, 1] := currentId
    itemLevels[levels_LastIndex, 2] := currentLevel
    itemLevels[levels_LastIndex, 3] := routineName
    ; msgbox, %currentLevel%
    ; outText :=  "Index=" levels_LastIndex ", routineName=" routineName ", currentId=" currentId ", level=" currentLevel "`n"
    ; FileAppend,  % outText, test.txt

    return currentId
}
;----------------------------------------------------------------
; validate line (return true if contains routine, else false)
;----------------------------------------------------------------
searchRoutine(line) {
    foundPos := InStr(line, "|__", false, 1)
    return foundPos
}
;---------------------------------------
; initialize variables (global)
;---------------------------------------
initialize() {
    global parentItemIDs := []
    global itemLevels := []
    global index := 0
    global levels_LastIndex := 0

    global previousRoutine := ""
    global currentRoutine := ""
    global previousId := 0
    global currentId := 0
    
    global foundPos := 0
    global currentLevel := 0

    ; file to process
    global filename

    user := getSystem()
    if (user = "SYSTEM_WORK") {
        filename := "H:\MY DATA\programs\AutoHotkey\AutoHotkeyPortable\experimental\MPMDL001_converted.txt"
    }
    if (user ="SYSTEM_HOME") {
        filename := "D:\_files\nic\pc-setups\AutoHotkey macros\cbtree\MPMDL001_converted.txt"
    }

    global inputLine := ""
    global searchText := ""

    global TreeViewWidth := 400
    global MyTreeView, MyEdit
    Gui +Resize
    
    ; Create an ImageList and put some standard system icons into it:
    ImageListID := IL_Create(5)
    Loop 5 
        IL_Add(ImageListID, "shell32.dll", A_Index)
    
    Gui, Add, Edit, r1 vMyEdit w150
    Gui, Add, Button,  Default, OK    ; hidden button to catch enter key!
    ; Gui, Add, Button, Hidden Default, OK    ; hidden button to catch enter key!
    Gui, Add, TreeView, vMyTreeView r80 w%TreeViewWidth% gMyTreeView ImageList%ImageListID%
    Menu, MyContextMenu, Add, find next (F1), contextMenuHandler
    Menu, MyContextMenu, Add, find previous (F2), contextMenuHandler
    Menu, MyContextMenu, Add, fold all (F3), contextMenuHandler
    Menu, MyContextMenu, Add, unfold all (F4), contextMenuHandler
    Menu, MyContextMenu, Add, fold recursively (F5), contextMenuHandler
    Menu, MyContextMenu, Add, unfold recursively (F6), contextMenuHandler
    Menu, MyContextMenu, Add, fold same level (F7), contextMenuHandler
    Menu, MyContextMenu, Add, unfold same level (F8), contextMenuHandler
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
    ; click an item: for future use
    if (A_GuiEvent = "S") {
    }
    
    ; doubleclick an item: search the treeview
    if (A_GuiEvent = "DoubleClick") {
        TV_GetText(SelectedItemText, A_EventInfo)   ; get item text
        GuiControl, , MyEdit , %SelectedItemText%   ; put it into search field
        searchItem(SelectedItemText, "next")
    }

    return
}

GuiSize:  ; Expand/shrink the ListView and TreeView in response to user's resizing of window.
{
    if (A_EventInfo = 1)  ; The window has been minimized. No action needed.
        return
    ; Otherwise, the window has been resized or maximized. Resize the controls to match.
    GuiControl, Move, MyTreeView, % "H" . (A_GuiHeight - 30) . " W" . (A_GuiWidth - 30) ; -30 for StatusBar and margins.
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
    if (A_ThisMenuItem = "find next") 
        gosub findNext
    if (A_ThisMenuItem = "find previous")
        gosub findPrevious

    if (A_ThisMenuItem = "fold all (F3)")
        processAll("-Expand")
    if (A_ThisMenuItem = "unfold all (F4)")
        processAll("Expand")
    if (A_ThisMenuItem = "fold recursively (F5)")
        processChildren(TV_GetSelection(), "-Expand")
    if (A_ThisMenuItem = "unfold recursively (F6)")
        processChildren(TV_GetSelection(), "Expand")
    if (A_ThisMenuItem = "fold same level (F7)")
        processSameLevel(TV_GetSelection(), "-Expand")
    if (A_ThisMenuItem = "unfold same level (F8)")
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
    
    global
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
            ; msgbox, % "current_index=" current_index "`nitemLevels[current_index,1]=" itemLevels[current_index,1] "`ncurrentItemID=" currentItemID
        }

        ; find first item with level <= selected item level (parent, sibling, other)
        if ((from_index > 0) and (current_index > from_index) and (itemLevels[current_index,2] <= itemLevels[from_index,2]))
        {
            ; msgbox, % "current_index=" current_index "`n...from_index=" from_index
            break
        }
        
        if (from_index > 0)
        {
            TV_Modify(itemLevels[current_index, 1], mode)
            ; outText := % "from_index=" from_index ", routineName=" itemLevels[current_index,3] ", currentId=" itemLevels[current_index,1] ", level=" itemLevels[current_index,2] "`n"
            ; FileAppend,  % outText, test1.txt
        }
    }

    
    GuiControl, +Redraw, MyTreeView
    TV_Modify(selectedItemId, VisFirst)     ;re-select old item
}
;-----------------------------------------------------------
; hide/show all nodes with same level as selected node.
;-----------------------------------------------------------
processSameLevel(currentItemID, mode) {

    global
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

