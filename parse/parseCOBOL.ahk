#SingleInstance, Force
SetWorkingDir, %A_ScriptDir%

global CobolParsingGroups := [ "IDENTIFICATION"
                , "ENVIRONMENT"
                , "DATA"
                , "WORKING-STORAGE"
                , "LINKAGE"
                , "PROCEDURE"]

global CobolParsingRegex := [ "im)^[^\*]\s*identification\s+division\s*\."  ; |not *|0..space(s)|identification|1..space(s)|division|0..space(s)|.|
                , "im)^[^\*]\s*environment\s+division\s*\."
                , "im)^[^\*]\s*data\s+division\s*\."
                , "im)^[^\*]\s*working-storage\s+section\s*\."
                , "im)^[^\*]\s*linkage\s+section\s*\."
                , "im)^[^\*]\s*procedure\s+division\s*"
                , "im)^[^\*]\s*copy\s+main[bg]\s*\."
                , "im)^[^\*]\s*copy\s+mainb\s*\."]

global life400_MAINB_routines := [ "0900-RESTART"
                           , "1000-INITIALISE"
                           , "2000-READ-FILE"
                           , "2500-EDIT"
                           , "3000-UPDATE"
                           , "3500-COMMIT"
                           , "3600-ROLLBACK"
                           , "4000-CLOSE" ]

global life400_MAING_routines := [ "1000-INITIALISE"
                           , "PRE-SCREEN-EDIT"
                           , "2000-SCREEN-EDIT"
                           , "3000-UPDATE"
                           , "4000-WHERE-NEXT" ]

global allCode, allSections, mainSections, codeSections, currentRoutine, routineName, calledRoutines, calledStmts, currentGroup

  ;---------------------------------------------------------------
  ; parse the file.
  ;---------------------------------------------------------------
parseCobol() {
  global

  FileEncoding, CP1253

  mainCobol()

  ; update the section [procedure-division] ending stmt = last code stmt.
  addCobolMainSections()
  saveCobolSections(codeSections)

  outputFile := fullFileRoutines
  if FileExist(outputFile)
    FileDelete, %outputFile%

  FileEncoding, UTF-8
  FileAppend, %allSections%, %outputFile%

}
  ;---------------------------------------------------------------
  ; parse the cobol code.
  ; populate: allCode[]= code lines, 
  ; 
  ;---------------------------------------------------------------
mainCobol() {
  global
  allSections := ""
  codeSections := []
  calledRoutines := []
  calledStmts := []
  checkFor_MAINB_MAING := True ; when true check if [COPY MAINB.] exists, but after first procedure division's section is found stop checking.
  found_MAINB_MAING := False
  currentRoutine := fileCode  ; "MAIN"
  currentGroup := 1
  firstRoutine := True
  startStmt := 0
  firstExecutableStmt := 0

  ; read all code one line at a time and parse.
  Loop, % allCode.MaxIndex()
  {
    current_code := allCode[A_Index]
    My_LoopReadLine := SubStr(current_code, 1, 69)  ; remove dummy string.

    ; if it is comment/spaces don't parse this.
    if (RegExMatch(My_LoopReadLine, "im)^\s*\*.*$") || Trim(My_LoopReadLine) = "")  ; (must consume the whole line!)
      Continue  ; parse next stmt

    current_line := A_Index  ; save index to use in inner loops.

    ;-----------------------------------------------------------------
    ; if main sections (1-6) not parsed yet: parse current section.
    ;-----------------------------------------------------------------
    if (currentGroup <= 6) {
      searchIndex := currentGroup

      Loop, % 7 - currentGroup  ; search 6 groups
      {
        if (RegExMatch(My_LoopReadLine, CobolParsingRegex[searchIndex])) {
          if (!CobolisEmptyOrEmptyStringsOnly(codeSections))
            codeSections[codeSections.MaxIndex()].endStmt := current_line ; - 1 TODO

          newSection := {}
          newSection.name := CobolParsingGroups[searchIndex]
          newSection.startStmt := CobolisEmptyOrEmptyStringsOnly(codeSections) ? 1 : current_line ; (current_line - 1) TODO
          newSection.callingStmt := 0
          
          ; ignore [procedure division], it is only used as a marker to start processing routines.
          if (searchIndex < 6) {
            codeSections.push(newSection)
          } else {
            startStmt := current_line  ; keep first stmt of main routine.
            firstExecutableStmt := current_line
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

    ;-----------------------------------------------------------------------------------------------------
    ; check if exists [COPY MAINB.] --> it is a Life400 batch program, so standard routines must be added.
    ;-----------------------------------------------------------------------------------------------------
    if (checkFor_MAINB_MAING && RegExMatch(My_LoopReadLine, CobolParsingRegex[7])) {
      checkFor_MAINB_MAING := False
      found_MAINB_MAING := True

      if (RegExMatch(My_LoopReadLine, CobolParsingRegex[8]))
        addLife400BatchRoutines(current_line)
      else
        addLife400ScreenRoutines(current_line)

      Continue  ; parse next stmt
    }

    ;------------------------------------------------
    ; check for routine call [PERFORM routine-name]
    ;------------------------------------------------
    if (RegExMatch(My_LoopReadLine, "im)(?<=\sperform\s)\s*[\-\w]+", matchedString)) { ; the [\s*] is required to catch multiple spaces between perform and routine name.
      StringUpper, matchedString, matchedString
      matchedString := Trim(matchedString)
      checkFor_MAINB_MAING := False

      ; ignore "fake" performs (perform varying | perform until)
      if (matchedString == "VARYING" || matchedString == "UNTIL")
        Continue  ; parse next stmt
      
      ; found routine call, save name/stmt if not already saved.
      routineName := matchedString
      if (!searchCobolCalledRoutines(routineName)) {
        calledRoutines.push(routineName)
        calledStmts.push(current_line)
      }
      Continue  ; parse next stmt
    }
    ;--------------------------------------------------------
    ; check for beginning of routine [routine-name SECTION.]
    ;--------------------------------------------------------
    if (RegExMatch(My_LoopReadLine, "im)[\w\-]+(?=\s+SECTION\s*\.)", matchedString)) {

      checkFor_MAINB_MAING := False

      ; if this section is "dummy" ignore it.
      if (firstRoutine && !found_MAINB_MAING && !calledRoutines.MaxIndex() > 0)
        Continue  ; parse next stmt

      processCobolBEGSR()
      Continue  ; parse next stmt
    }

    ;--------------------------------------------
    ; check for end of routine [EXIT. or GOBACK.]
    ;--------------------------------------------
    if (RegExMatch(My_LoopReadLine, "im)\s+(?:exit|goback|exit\s+program)\s*\.")) {
      endStmt := current_line
      processCobolENDSR()     
      Continue  ; parse next stmt
    }
  }
}
  ;---------------------------------------------------------------
  ; process beginning of routine.
  ;---------------------------------------------------------------
processCobolBEGSR() {
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
processCobolENDSR() {
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
searchCobolCalledRoutines(routineName) {
  Loop, % calledRoutines.MaxIndex() {
    if (routineName == calledRoutines[A_Index])
      return A_Index
  }
  return 0
}
  ;---------------------------------------------------------------
  ; insert the main sections at the beginning of the array
  ;---------------------------------------------------------------
addCobolMainSections() {
  global

  declarationsSection := CONST_DECLARATIONS
  endStmt := 0

  ; Loop, % CobolParsingGroups.MaxIndex() - 1  ; skip [procedure division]
  Loop, % CobolParsingGroups.MaxIndex()
  {
    newSection := {}
    newSection.name := declarationsSection
    newSection.startStmt := 1
    newSection.endStmt := 1
    newSection.callingStmt := 0
    newSection.calledSection := CobolParsingGroups[A_Index]
    endStmt := 0

    codeSections.InsertAt(A_Index, newSection)
  }

  ; attach declarations group to main program.
  newSection := {}
  newSection.name := fileCode ; "MAIN"
  newSection.startStmt := firstExecutableStmt
  newSection.endStmt := 1
  newSection.callingStmt := 0
  newSection.calledSection := declarationsSection

  codeSections.InsertAt(1, newSection)
  
}
  ;---------------------------------------------------------------
  ; add the Life400 batch program <standard routines>.
  ;---------------------------------------------------------------
addLife400BatchRoutines(stmt) {
  global

  Loop, % life400_MAINB_routines.MaxIndex() {

    newSection := {}
    newSection.name := currentRoutine
    newSection.startStmt := 1
    newSection.endStmt := 1
    newSection.callingStmt := stmt
    newSection.calledSection := life400_MAINB_routines[A_Index]

    codeSections.InsertAt(A_Index, newSection)  ; add at the beginning of the array.
  }

}
  ;---------------------------------------------------------------
  ; add the Life400 screen program <standard routines>.
  ;---------------------------------------------------------------
addLife400ScreenRoutines(stmt) {
  global

  Loop, % life400_MAING_routines.MaxIndex() {

    newSection := {}
    newSection.name := currentRoutine
    newSection.startStmt := 1
    newSection.endStmt := 1
    newSection.callingStmt := stmt
    newSection.calledSection := life400_MAING_routines[A_Index]

    codeSections.InsertAt(A_Index, newSection)  ; add at the beginning of the array.
  }

}
  ;---------------------------------------------------------------
  ; 
  ;---------------------------------------------------------------
saveCobolSections(codeSections) {
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
CobolisEmptyOrEmptyStringsOnly(inputArray) {
	for each, value in inputArray {
		if !(value == "") {
			return false ;one of the values is not an empty string therefore the array is not empty or empty strings only
		}
	}
	return true ;all the values have passed the test or no values where inside the array
}