#SingleInstance, Force
SetWorkingDir, %A_ScriptDir%

global RpgParsingGroups := [ "File", "Data", "Input", "Calc"]

global RpgParsingRegex := [ "im)^[FH]", "im)^D", "im)^I", "im)^C"]

global allCode, allSections, mainSections, codeSections, currentRoutine, routineName, calledRoutines, calledStmts, foundINZSR, currentGroup

  ;---------------------------------------------------------------
  ; parse the file.
  ;---------------------------------------------------------------
parseRpg() {
  global

  FileEncoding, CP1253

  mainRpg()

  ; update the section [procedure-division] ending stmt = last code stmt.
  addRpgMainSections()
  saveRpgSections(codeSections)

  outputFile := fullFileRoutines
  if FileExist(outputFile)
    FileDelete, %outputFile%

  FileEncoding, UTF-8
  FileAppend, %allSections%, %outputFile%

}
  ;---------------------------------------------------------------
  ; parse the rpg code.
  ; populate: allCode[]= code lines, 
  ; 
  ;---------------------------------------------------------------
mainRpg() {
  global
  mainSections := []
  codeSections := []
  calledRoutines := []
  calledStmts := []
  foundINZSR := False
  currentRoutine := fileCode  ; "MAIN"
  currentGroup := 1
  firstRoutine := True
  startStmt := 0
  firstExecutableStmt := 0

  ; read all code one line at a time and parse.
  Loop, % allCode.MaxIndex()
  {
    current_code := allCode[A_Index]
    ; if it is comment/spaces don't parse this.
    if (RegExMatch(current_code, "im)^.\*.*$") || Trim(current_code) = "")  ; |any 1 char|*|any chars up to EOL| (must consume the whole line!)
      Continue  ; parse next stmt

    current_line := A_Index  ; save index to use in inner loops.

    ;---------------------------------------------------------
    ; if main sections (1-4) not parsed yet: parse any found.
    ;---------------------------------------------------------
    if (currentGroup <= 4) {
      searchIndex := currentGroup

      Loop, % 5 - currentGroup  ; search 4 groups
      {
        if (RegExMatch(current_code, RpgParsingRegex[searchIndex])) {
          if (!RpgisEmptyOrEmptyStringsOnly(codeSections))
            codeSections[codeSections.MaxIndex()].endStmt := current_line ; - 1

          newSection := {}
          newSection.name := RpgParsingGroups[searchIndex]
          newSection.startStmt := RpgisEmptyOrEmptyStringsOnly(codeSections) ? 1 : current_line ; (current_line - 1)
          newSection.callingStmt := 0
          
          ; ignore [Calc], it is only used as a marker to start processing routines.
          if (searchIndex < 4) {
            mainSections.push(RpgParsingGroups[searchIndex])
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

    if (currentGroup <= 4)
      Continue  ; parse next stmt
    
    ; all 4 main sections are parsed: parse routines.

    ;-------------------------------------------------
    ; check for routine call [EXSR|CAS routine-name]
    ;-------------------------------------------------
    if (RegExMatch(current_code, "im)(?<=EXSR\s{6})[\w]+", matchedString) 
        || RegExMatch(current_code, "im)(?<=CAS\.{2})[\w]+", matchedString)) {
      StringUpper, matchedString, matchedString
      
      ; found routine call, save name/stmt if not already saved.
      routineName := matchedString
      if (!searchRpgCalledRoutines(routineName)) {
        calledRoutines.push(routineName)
        calledStmts.push(current_line)
      }
      Continue  ; parse next stmt
    }
    ;-----------------------------------------------------
    ; check for beginning of routine [routine-name BEGSR]
    ;-----------------------------------------------------
    if (RegExMatch(current_code, "im)[\w]+(?=\s+BEGSR)", matchedString))
       || (RegExMatch(current_code, "im)\s+(?<=begsr\s+)[\w]+", matchedString)) {
      if (firstRoutine) { ; if it is the first routine, write the main routine which does not have BEGSR/ENDSR
        processRpgENDSR()
        firstRoutine := False
      }

      processRpgBEGSR()
      Continue  ; parse next stmt
    }
    ;----------------------------------
    ; check for end of routine [ENDSR]
    ;----------------------------------
    if (RegExMatch(current_code, "im)\s(?:endsr)(?![\w-])")) {
      endStmt := current_line
      processRpgENDSR()
      Continue  ; parse next stmt
    }
  }
}
  ;---------------------------------------------------------------
  ; process beginning of routine.
  ;---------------------------------------------------------------
processRpgBEGSR() {
  global
  StringUpper, matchedString, matchedString
  startStmt := current_line  ; keep first stmt of current routine.
  currentRoutine := matchedString ; keep routine name.
  calledRoutines := []
  calledStmts := []

  ; mark if exists routine *INZSR to attach it to MAIN at the end.
  if (matchedString == "*INZSR")
    foundINZSR := True
}
  ;---------------------------------------------------------------
  ; process end of routine.
  ;---------------------------------------------------------------
processRpgENDSR() {
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
searchRpgCalledRoutines(routineName) {
  Loop, % calledRoutines.MaxIndex() {
    if (routineName == calledRoutines[A_Index])
      return A_Index
  }
  return 0
}
  ;---------------------------------------------------------------
  ; insert the main sections at the beginning of the array
  ;---------------------------------------------------------------
addRpgMainSections() {
  global

  declarationsSection := CONST_DECLARATIONS
  endStmt := 0

  Loop, % mainSections.MaxIndex()
  {
    newSection := {}
    newSection.name := declarationsSection
    newSection.startStmt := 1
    newSection.endStmt := 1
    newSection.callingStmt := 0
    newSection.calledSection := mainSections[A_Index]
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
  ; attach *INZSR to MAIN routine.
  ;---------------------------------------------------------------
addINZSR() {
  global

  newSection := {}
  newSection.name := fileCode ; "MAIN"
  newSection.startStmt := codeSections[1].startStmt
  newSection.endStmt := codeSections[1].endStmt
  newSection.callingStmt := codeSections[1].startStmt
  newSection.calledSection := "*INZSR"

  codeSections.InsertAt(1, newSection)  ; add at the beginning of the array.

}
  ;---------------------------------------------------------------
  ; 
  ;---------------------------------------------------------------
saveRpgSections(codeSections) {
  global
  allSections := ""
  
  Loop, % codeSections.MaxIndex() {

    line := Format("{:05}", A_Index) . ", " 
            . Format("{:04}", codeSections[A_Index].startStmt) . ", " 
            . Format("{:04}",codeSections[A_Index].endStmt) . ", "
            . Format("{:04}",codeSections[A_Index].callingStmt) . ","
            . Format("{:-30}",codeSections[A_Index].name) . ","
            . codeSections[A_Index].calledSection
            . "`n"
    allSections .= line
  }
}
  ;---------------------------------------------------------------
  ; check if an array is empty.
  ;---------------------------------------------------------------
RpgisEmptyOrEmptyStringsOnly(inputArray) {
	for each, value in inputArray {
		if !(value == "") {
			return false ;one of the values is not an empty string therefore the array is not empty or empty strings only
		}
	}
	return true ;all the values have passed the test or no values where inside the array
}