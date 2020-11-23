#SingleInstance, Force
SetWorkingDir, %A_ScriptDir%

global parsingSteps := [ "File"
  , "Data"
  , "Input"
  , "Calc"]

global parsingRegex := [ "im)^[FH]"  ; |F|H|
  , "im)^D"
  , "im)^I"
  , "im)^C"]

path := A_ScriptDir . "\..\data\"
fileCode := "PGROUTR2-TRIMMED.rpgle"
fullFileCode := path . fileCode
language := "rpg"
FileEncoding, CP1253

global allCode := []
global allSections := ""
global codeSections := []
global currentRoutine := "MAIN"
global routineName
global calledRoutines := [], calledStmts := []
global foundINZSR := False
global currentStep := 1

main()
ExitApp
  ;---------------------------------------------------------------
  ; parse the file.
  ;---------------------------------------------------------------
main() {

  parseCode()

  ; update the section [procedure-division] ending stmt = last code stmt.
  if (foundINZSR)
    addINZSR()

  addMainSections()
  saveSections(codeSections)

  ; match non-comment line containing "environment division."
  ; ^[^\*]\s*environment\s+division\s*\.

  filename := A_ScriptDir . "\codeCalls_RPG.txt"
  if FileExist(filename)
    FileDelete, %filename%

  FileEncoding, UTF-8
  FileAppend, %allSections%, %filename%

}
  ;---------------------------------------------------------------
  ; 
  ;---------------------------------------------------------------
parseCode() {
  global

  ; read all code one line at a time and parse.
  Loop, Read, %fullFileCode%
  {
    allCode.push(A_LoopReadLine)
    
    ; if it is comment/spaces don't parse this.
    if (RegExMatch(A_LoopReadLine, "im)^.\*.*$") || Trim(A_LoopReadLine) = "")  ; |any 1 char|*|any chars up to EOL| (must consume the whole line!)
      Continue  ; parse next stmt

    current_code_line := A_Index  ; save index to use in inner loops.

    ;----------------------------------------
    ; if main sections (1-5) not parsed yet: parse any found.
    ;----------------------------------------
    if (currentStep <= 4) {
      Loop, % 5 - currentStep
      {
        if (RegExMatch(A_LoopReadLine, parsingRegex[A_Index])) {
          if (currentStep > 1)
            codeSections[currentStep - 1].endStmt := current_code_line - 1

          newSection := {}
          newSection.name := parsingSteps[currentStep]
          newSection.startStmt := currentStep == 1 ? 1 : (A_Index - 1)
          newSection.callingStmt := 0
          
          ; ignore [procedure division], it is only used as a marker to start processing routines.
          if (currentStep < 5)
            codeSections.push(newSection)
          
          currentStep ++
        }
      Continue  ; parse next stmt
    }
    }



    if (currentStep <= 4)
      Continue  ; parse next stmt
    
    ; all 5 main sections are parsed.
    ; parse routines.

    ;-----------------------------------
    ; check for routine call [EXSR|CAS routine-name]
    ;-----------------------------------
    if (RegExMatch(A_LoopReadLine, "im)(?<=EXSR\s{6})[\w]+", matchedString) || RegExMatch(A_LoopReadLine, "im)(?<=CAS\.{21})[\w]+", matchedString)) {
      StringUpper, matchedString, matchedString
      
      ; found routine call, save name/stmt if not already saved.
      routineName := matchedString
      if (!searchCalledRoutines(routineName)) {
        calledRoutines.push(routineName)
        calledStmts.push(A_Index)
      }
      Continue  ; parse next stmt
    }

    ;-----------------------------------
    ; check for beginning of routine [routine-name BEGSR]
    ;-----------------------------------
    if (RegExMatch(A_LoopReadLine, "im)[\w]+(?=\s+BEGSR)", matchedString)) {
      StringUpper, matchedString, matchedString
      startStmt := A_Index  ; keep first stmt of current routine.
      currentRoutine := matchedString ; keep routine name.
      calledRoutines := []
      calledStmts := []

      ; mark if exists routine *INZSR to attach it to MAIN at the end.
      if (matchedString == "*INZSR")
        foundINZSR := True
      
      Continue  ; parse next stmt
    }

    ;--------------------------------
    ; check for end of routine [ENDSR]
    ;--------------------------------
    if (RegExMatch(A_LoopReadLine, "im)\s(?:endsr)(?![\w-])")) {
      endStmt := A_Index
      
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
      Continue  ; parse next stmt
    }

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

  Loop, % parsingSteps.MaxIndex() - 1 { ; skip [Calc-section]
    
    newSection := {}
    newSection.name := "MAIN"
    newSection.startStmt := 1
    newSection.endStmt := 1
    newSection.callingStmt := 0
    newSection.calledSection := parsingSteps[A_Index]

    codeSections.InsertAt(A_Index, newSection)
  }
}
  ;---------------------------------------------------------------
  ; attach *INZSR to MAIN routine.
  ;---------------------------------------------------------------
addINZSR() {
  global

  newSection := {}
  newSection.name := "MAIN"
  newSection.startStmt := codeSections[1].startStmt
  newSection.endStmt := codeSections[1].endStmt
  newSection.callingStmt := codeSections[1].startStmt
  newSection.calledSection := "*INZSR"

  codeSections.InsertAt(1, newSection)  ; add at the beginning of the array.

}
  ;---------------------------------------------------------------
  ; 
  ;---------------------------------------------------------------
saveSections(codeSections) {
  global
  
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
