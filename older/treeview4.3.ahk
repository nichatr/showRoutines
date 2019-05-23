;--------------------------------------------------------------------------------------
; 1. read text file CBTREEF5.TXT containing the output of program CBTREER5:
;    00001  0886.00  0899.00 MAIN                           INITIALIZE-ROUTINE            
;    00002  0886.00  0900.00 MAIN                           MAIN-ROUTINE                  
;    00003  0916.00  0000.00 INITIALIZE-ROUTINE                             
;    etc...
; 2. populate array of routines allRoutines[] with above data.
;--------------------------------------------------------------------------------------
; file cbtreef5.txt was created in AS400 with:
; cbtree_2 ....
; cpyf qtemp/cbtreef5  dcommon/cbtreef5 *replace
; CVTDBF FROMFILE(DCOMMON/CBTREEF5) TOSTMF('/output/bussup/txt/cbtreef5') TOFMT(*FIXED) FIXED(*CRLF (*DBF) (*DBF) *SYSVAL *COMMA)                   
;--------------------------------------------------------------------------------------
; File test_sequential.txt : created by write_toFile_sequentially
; File text_recursive.txt : created by write_toFile_recursively
;--------------------------------------------------------------------------------------
; TODO: in array of called routines store the actual statement
; DONE: use treeview in place of txt file for recursive process.
; DONE: create treeview4.3.ahk new version of treeview4.2.ahk.
;   DONE: remove routine write_toFile_sequentially.
;   DONE: in routine write_toFile_recursively instead of writting to text file call routine to write to treeview.
;   TODO: add all UI logic from treview3.ahk.
;   TODO: show the actual statement number.
;--------------------------------------------------------------------------------------

global allRoutines  ; array of class "routine"
global tmpRoutine 
global filename     ; text file with all routine calls, is the output from AS400.

initialize()
populateRoutines()
loadTreeview()

Gui, Show
return

;---------------------------------------
; initialize variables (global)
;---------------------------------------
initialize() {
    allRoutines := []
    tmpRoutine  := {}

    ; file to process
    txtFile := "cbtreef5.txt"

    user := getSystem()

    if (user = "SYSTEM_WORK") {
        filename := "H:\MY DATA\temp\projects\tree cobol program\" . txtFile
    }
    if (user ="SYSTEM_HOME") {
        filename := "D:\_files\nic\pc-setups\AutoHotkey macros\cbtree\" . txtFile
    }

    ; UI init
    global TreeViewWidth := 400
    global MyTreeView
    Gui +Resize

    ; Create an ImageList and put some standard system icons into it:
    ImageListID := IL_Create(5)
    Loop 5 
        IL_Add(ImageListID, "shell32.dll", A_Index)
    
    Gui, Add, TreeView, vMyTreeView r80 w%TreeViewWidth% gMyTreeView ImageList%ImageListID%
}
;-----------------------------------------------------------
; Handle user actions (such as clicking). 
;-----------------------------------------------------------
MyTreeView:
{

    return
}
GuiClose:  ; Exit the script when the user closes the TreeView's GUI window.
    ExitApp
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
    spaces := "                              "
    itemId := TV_Add(currRoutine.routineName, parentID, "Icon4 Expand")

    Loop, % currRoutine.calls.MaxIndex() {

        ; search array allRoutines[] for the current routine item.
        calledId := searchRoutine(currRoutine.calls[A_Index])
        if (calledId > 0) {
            processRoutine(allRoutines[calledId], itemId)     ; write children
        }
    } 
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
;-------------------------------------------------------
; read cbtreef5.txt file and populate routines array
;-------------------------------------------------------
populateRoutines() {
    Loop, Read, %filename%
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
    tmpRoutine.STMCALL     := trim(array1[3])
    tmpRoutine.ROUCALLER   := trim(array1[4])
    tmpRoutine.ROUCALLED   := trim(array1[5])
    return tmpRoutine
}
;---------------------------------------------------------------------
; routines data model.
;---------------------------------------------------------------------
class routine {
    routineName := ""
    calledBy := ""
    startStmt := ""
    callingStmt := ""
    calls := []
}