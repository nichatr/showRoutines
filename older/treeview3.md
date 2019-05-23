1. initialize()
    1. treview
    2. routines = []
    3. previousRoutine = currentRoutine = ""

2. read inputFile (1 line)
    1. if eof goto xxxx (show treeview)
    2. if inputLine = blanks goto 2

3. check if valid inputLine
    1. foundPos = inStr(inputLine, "|__", matchcase=false, startpos=1)
    2. if foundPos = 0 goto 2   ; not valid line

4. get current routine
    1. currentRoutine = substr(inputLine, foundpos+3)
    2. currentLevel = (foundPos + 1) / 3    ; 1,2,3...

5. write to appropriate node
    1. if (previousRoutine = "" )
        1. routines.push(currentRoutine)
        2. add currentRoutine to treeview      ; first node

    2. if (currentLevel = routines.maxIndex())
        1. add currentRoutine to routines.maxIndex() in treeview      ; sibling node

    3. if (currentLevel > routines.maxIndex())
        1. routines.push(previousRoutine)
        2. add currentRoutine to routines.maxIndex() in treview       ; child node

    4. if (currentLevel < routines.maxIndex())
        1. routines.pop(previousRoutine)
        2. add currentRoutine to routines.maxIndex() in treview       ; child node
        
    5. previousRoutine = currentRoutine
    6. goto 2

6. show treeview

7. destroy treeview

OK -> TODO: fold/unfold recursively current node
OK -> TODO: fold/unfold all nodes with level = selected item's level
OK -> TODO: move all fold/unfold in context menu
OK -> TODO: find text in nodes (ctrl F)
OK -> TODO: navigate through next/prev (F-keys)
not OK -> TODO: highlight all found: not possible, omly one node can be selected.

; TODO: show found string count
; TODO: add listview to the right of treeview.

-------------------------------------------------------------------------

