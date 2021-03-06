#SingleInstance, Force
SetWorkingDir, %A_ScriptDir%

global parsingGroups := [ "IDENTIFICATION"
                , "ENVIRONMENT"
                , "DATA"
                , "WORKING-STORAGE"
                , "LINKAGE"
                , "PROCEDURE"]

global parsingRegex := [ "im)^[^\*]\s*identification\s+division\s*\."  ; |not *|0..space(s)|identification|1..space(s)|division|0..space(s)|.|
                , "im)^[^\*]\s*environment\s+division\s*\."
                , "im)^[^\*]\s*data\s+division\s*\."
                , "im)^[^\*]\s*working-storage\s+section\s*\."
                , "im)^[^\*]\s*linkage\s+section\s*\."
                , "im)^[^\*]\s*procedure\s+division\s*"
                , "im)^[^\*]\s*copy\s+mainb\s*\."]

global life400StandardRoutines := [ "0900-RESTART"
                           , "1000-INITIALISE"
                           , "2000-READ-FILE"
                           , "2500-EDIT"
                           , "3000-UPDATE"
                           , "3500-COMMIT"
                           , "3600-ROLLBACK"
                           , "4000-CLOSE" ]

global allCode, allSections, mainSections, codeSections, currentRoutine, routineName, calledRoutines, calledStmts, foundINZSR, currentGroup

path := A_ScriptDir . "\data\"
fileCode := "ZSAUTOQ_TRIMMED.CBL"
; fileCode := "ZWFCON2_TRIMMED.CBLLE"        ; "B9Y36.cblle"  ; "ZWFCON2 copy.CBLLE"
fullFileCode := path . fileCode
language := "cobol"
FileEncoding, CP1253

main()
ExitApp
  ;---------------------------------------------------------------
  ; parse the file.
  ;---------------------------------------------------------------
main() {

  parseCode()

  ; update the section [procedure-division] ending stmt = last code stmt.
  addMainSections()
  saveSections(codeSections)

  filename := A_ScriptDir . "\data\ZSAUTOQ_PARSED.txt"
  if FileExist(filename)
    FileDelete, %filename%

  FileEncoding, UTF-8
  FileAppend, %allSections%, %filename%

}
  ;---------------------------------------------------------------
  ; parse the cobol code.
  ; populate: allCode[]= code lines, 
  ; 
  ;---------------------------------------------------------------
parseCode() {
  global
  allCode := []
  allSections := ""
  codeSections := []
  calledRoutines := []
  calledStmts := []
  foundMAINB := False ; when true add standard sections 1000-,2000-,3000-,4000-
  checkForMAINB := True ; when true check if [COPY MAINB.] exists, but after first procedure division's section is found stop checking.
  currentRoutine := "MAIN"
  currentGroup := 1
  firstRoutine := True

; read all code one line at a time and parse.
  Loop, Read, %fullFileCode%
  {
    allCode.push(A_LoopReadLine)
    
    My_LoopReadLine := SubStr(A_LoopReadLine, 1, 69)  ; remove dummy string.

    ; if it is comment/spaces don't parse this.
    if (RegExMatch(My_LoopReadLine, "im)^\s*\*.*$") || Trim(My_LoopReadLine) = "")  ; (must consume the whole line!)
      Continue  ; parse next stmt

    current_line := A_Index  ; save index to use in inner loops.

    ;----------------------------------------
    ; if main sections (1-7) not parsed yet: parse current section.
    ;----------------------------------------
    if (currentGroup <= 6) {
      searchIndex := currentGroup

      Loop, % 7 - currentGroup  ; search 6 groups
      {
        if (RegExMatch(My_LoopReadLine, parsingRegex[searchIndex])) {
          if (!isEmptyOrEmptyStringsOnly(codeSections))
            codeSections[codeSections.MaxIndex()].endStmt := current_line ; - 1 TODO

          newSection := {}
          newSection.name := parsingGroups[searchIndex]
          newSection.startStmt := isEmptyOrEmptyStringsOnly(codeSections) ? 1 : current_line ; (current_line - 1) TODO
          newSection.callingStmt := 0
          
          ; ignore [procedure division], it is only used as a marker to start processing routines.
          if (searchIndex < 6) {
            mainSections.push(parsingGroups[searchIndex])
            codeSections.push(newSection)
          }
          
          currentGroup := searchIndex + 1
          Break  ; parse next stmt
        }
        searchIndex ++        
      }
    }

    if (currentGroup <= 6)
      Continue  ; parse next stmt

    ; all 6 main sections are parsed: parse routines.

    ;----------------------------------------
    ; check if exists [COPY MAINB.] --> it is a Life400 batch program, so standard routines must be added.
    ;----------------------------------------
    if (checkForMAINB && RegExMatch(My_LoopReadLine, parsingRegex[7])) {
      checkForMAINB := False
      foundMAINB := True
      addLife400BatchRoutines(current_line)
      ; firstRoutine := False
      Continue  ; parse next stmt
    }

    ;------------------------------------------------
    ; check for routine call [PERFORM routine-name]
    ;------------------------------------------------
    if (RegExMatch(My_LoopReadLine, "im)(?<=\sperform\s)\s*[\-\w]+", matchedString)) { ; the [\s*] is required to catch multiple spaces between perform and routine name.
      StringUpper, matchedString, matchedString
      matchedString := Trim(matchedString)

      ; ignore "fake" performs (perform varying | perform until)
      if (matchedString == "VARYING" || matchedString == "UNTIL")
        Continue  ; parse next stmt
      
      ; found routine call, save name/stmt if not already saved.
      routineName := matchedString
      if (!searchCalledRoutines(routineName)) {
        calledRoutines.push(routineName)
        calledStmts.push(current_line)
      }
      Continue  ; parse next stmt
    }
    ;--------------------------------------------------------
    ; check for beginning of routine [routine-name SECTION.]
    ;--------------------------------------------------------
    if (RegExMatch(My_LoopReadLine, "im)[\w\-]+(?=\s+SECTION\s*\.)", matchedString)) {

      ; if this section is "dummy" ignore it.
      if (firstRoutine && !calledRoutines.MaxIndex() > 0)
        Continue  ; parse next stmt

      ; if (firstRoutine) { ; if it is the first routine, write the main routine which does not have BEGSR/ENDSR
      ;   processENDSR()
      ;   firstRoutine := False
      ; }

      processBEGSR()
      Continue  ; parse next stmt
    }

    ;--------------------------------
    ; check for end of routine [EXIT. or GOBACK.]
    ;--------------------------------
    if (RegExMatch(My_LoopReadLine, "im)\s+(?:exit|goback)\s*\.")) {
      endStmt := current_line
      processENDSR()     
      Continue  ; parse next stmt
    }
  }
}
  ;---------------------------------------------------------------
  ; process beginning of routine.
  ;---------------------------------------------------------------
processBEGSR() {
  global
  firstRoutine := False
  StringUpper, matchedString, matchedString
  startStmt := current_line  ; keep first stmt of current routine.
  currentRoutine := matchedString ; keep routine name.
  calledRoutines := []
  calledStmts := []
}
  ;---------------------------------------------------------------
  ; process end of routine.
  ;---------------------------------------------------------------
processENDSR() {
  global
  if (calledRoutines.MaxIndex() > 0) {  ; save current routine with all routines called.
    Loop, % calledRoutines.MaxIndex() {
      
      newSection := {}
      newSection.name := currentRoutine
      newSection.startStmt := startStmt
      newSection.endStmt := endStmt
      newSection.callingStmt := calledStmts[A_Index]
      newSection.calledSection := calledRoutines[A_Index]
      
      codeSections.push(newSection)
    }
  } else {
      newSection := {}  ; save current routine with zero calls.
      newSection.name := currentRoutine
      newSection.startStmt := startStmt
      newSection.endStmt := endStmt
      newSection.callingStmt := 0
      newSection.calledSection := ""
      
      codeSections.push(newSection)
  }
}
  ;---------------------------------------------------------------
  ; search if a routine is already saved in the called routines array.
  ;---------------------------------------------------------------
searchCalledRoutines(routineName) {
  Loop, % calledRoutines.MaxIndex() {
    if (routineName == calledRoutines[A_Index])
      return A_Index
  }
  return 0
}
  ;---------------------------------------------------------------
  ; insert the main sections at the beginning of the array
  ;---------------------------------------------------------------
addMainSections() {
  global

  Loop, % parsingGroups.MaxIndex() - 1 { ; skip [procedure division]
    
    newSection := {}
    newSection.name := "MAIN"
    newSection.startStmt := 1
    newSection.endStmt := 1
    newSection.callingStmt := 0
    newSection.calledSection := parsingGroups[A_Index]

    codeSections.InsertAt(A_Index, newSection)
  }
}
  ;---------------------------------------------------------------
  ; add the Life400 batch program <standard routines>.
  ;---------------------------------------------------------------
addLife400BatchRoutines(stmt) {
  global

  Loop, % life400StandardRoutines.MaxIndex() {

    newSection := {}
    newSection.name := currentRoutine
    newSection.startStmt := 1
    newSection.endStmt := 1
    newSection.callingStmt := stmt
    newSection.calledSection := life400StandardRoutines[A_Index]

    codeSections.InsertAt(A_Index, newSection)  ; add at the beginning of the array.
  }

}
  ;---------------------------------------------------------------
  ; 
  ;---------------------------------------------------------------
saveSections(codeSections) {
  global
  
  Loop, % codeSections.MaxIndex() {

    line := Format("{:05}", A_Index) . ", " 
            . Format("{:06}", codeSections[A_Index].startStmt) . ", " 
            . Format("{:06}",codeSections[A_Index].endStmt) . ", "
            . Format("{:06}",codeSections[A_Index].callingStmt) . ","
            . Format("{:-30}",codeSections[A_Index].name) . ","
            . codeSections[A_Index].calledSection
            . "`n"

    ; line :=  Format("{:-30}",codeSections[A_Index].name) . ","
    ;         . codeSections[A_Index].calledSection
    ;         . "`n"
    allSections .= line
  }
}
  ;---------------------------------------------------------------
  ; check if an array is empty.
  ;---------------------------------------------------------------
isEmptyOrEmptyStringsOnly(inputArray) {
	for each, value in inputArray {
		if !(value == "") {
			return false ;one of the values is not an empty string therefore the array is not empty or empty strings only
		}
	}
	return true ;all the values have passed the test or no values where inside the array
}