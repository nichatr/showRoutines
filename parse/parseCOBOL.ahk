#SingleInstance, Force
SetWorkingDir, %A_ScriptDir%

parsingSteps := [ "IDENTIFICATION"
                , "ENVIRONMENT"
                , "DATA"
                , "WORKING-STORAGE"
                , "LINKAGE"
                , "PROCEDURE"]

parsingRegex := [ "im)^[^\*]\s*identification\s+division\s*\."  ; |not *|0..space(s)|identification|1..space(s)|division|0..space(s)|.|
                , "im)^[^\*]\s*environment\s+division\s*\."
                , "im)^[^\*]\s*data\s+division\s*\."
                , "im)^[^\*]\s*working-storage\s+section\s*\."
                , "im)^[^\*]\s*linkage\s+section\s*\."
                , "im)^[^\*]\s*procedure\s+division\s*"
                , "im)^[^\*]\s*copy\s+mainb\s*\."]

life400StandardRoutines := [ "0900-RESTART"
                           , "1000-INITIALISE"
                           , "2000-READ-FILE"
                           , "2500-EDIT"
                           , "3000-UPDATE"
                           , "3500-COMMIT"
                           , "3600-ROLLBACK"
                           , "4000-CLOSE" ]

path := A_ScriptDir . "\..\data\"
fileCode := "ZWFCON2_TRIMMED.CBLLE"        ; "B9Y36.cblle"  ; "ZWFCON2 copy.CBLLE"
fullFileCode := path . fileCode
language := "cobol"
FileEncoding, CP1253

global allCode := []
global allSections := ""
global codeSections := []
global currentRoutine := "MAIN"
global routineName
global calledRoutines := [], calledStmts := []
global firstRoutine

foundMAINB := False ; when true add standard sections 1000-,2000-,3000-,4000-
checkForMAINB := True ; when true check if [COPY MAINB.] exists, but after first procedure division's section is found stop checking.

currentStep := 1
firstRoutine := True

; read all code one line at a time and parse.
Loop, Read, %fullFileCode%
{
  allCode.push(A_LoopReadLine)
  
  ; if it is comment/spaces don't parse this.
  if (RegExMatch(A_LoopReadLine, "im)^\s*\*.*$") || Trim(A_LoopReadLine) = "")  ; (must consume the whole line!)
    Continue  ; parse next stmt

  ;----------------------------------------
  ; if main sections (1-7) not parsed yet: parse current section.
  ;----------------------------------------
  if (currentStep <= 6 && RegExMatch(A_LoopReadLine, parsingRegex[currentStep])) {
    if (currentStep > 1) {
      codeSections[currentStep - 1].endStmt := A_Index - 1
    }

    newSection := {}
    newSection.name := parsingSteps[currentStep]
    newSection.startStmt := currentStep == 1 ? 1 : (A_Index - 1)
    newSection.callingStmt := 0
    
    ; ignore [procedure division], it is only used as a marker to start processing routines.
    if (currentStep < 6)
      codeSections.push(newSection)
    
    currentStep ++
    Continue  ; parse next stmt
  }

  if (currentStep <= 6)
    Continue  ; parse next stmt
  
  ; all 6 main sections are parsed.
  ; parse routines.

  ;----------------------------------------
  ; check if exists [COPY MAINB.] --> it is a Life400 batch program, so standard routines must be added.
  ;----------------------------------------
  if (checkForMAINB && RegExMatch(A_LoopReadLine, parsingRegex[7])) {
    checkForMAINB := False
    foundMAINB := True
    addLife400BatchRoutines(A_Index)
    firstRoutine := False
    Continue  ; parse next stmt
  }

  ;-----------------------------------
  ; check for routine call [PERFORM routine-name]
  ;-----------------------------------
  if (RegExMatch(A_LoopReadLine, "im)(?<=perform\s)[\-\w]+", matchedString)) {
    StringUpper, matchedString, matchedString
    if (matchedString == "VARYING" || matchedString == "UNTIL")
      Continue  ; parse next stmt
    
    ; found routine call, save name/stmt if not already saved.
    routineName := matchedString
    if (!searchCalledRoutines(routineName)) {
      calledRoutines.push(routineName)
      calledStmts.push(A_Index)
    }
    Continue  ; parse next stmt
  }

  ;-----------------------------------
  ; check for beginning of routine [routine-name SECTION.]
  ;-----------------------------------
  if (RegExMatch(A_LoopReadLine, "im)[\w\-]+(?=\s+SECTION\s*\.)", matchedString)) {
    startStmt := A_Index  ; keep first stmt of current routine.
    if (!firstRoutine)
      currentRoutine := matchedString ; keep routine name.
    else {
      currentRoutine := "MAIN"
      firstRoutine := False
    }

    calledRoutines := []
    calledStmts := []
    Continue  ; parse next stmt
  }

  ;--------------------------------
  ; check for end of routine [EXIT. or GOBACK.]
  ;--------------------------------
  if (RegExMatch(A_LoopReadLine, "im)\s+(?:exit|goback)\s*\.")) {
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

; update the section [procedure-division] ending stmt = last code stmt.
addMainSections()
saveSections(codeSections)

; match non-comment line containing "environment division."
; ^[^\*]\s*environment\s+division\s*\.

filename := A_ScriptDir . "\codeCalls_COBOL.txt"
if FileExist(filename)
  FileDelete, %filename%

FileEncoding, UTF-8
FileAppend, %allSections%, %filename%

ExitApp

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

  Loop, % parsingSteps.MaxIndex() - 1 { ; skip [procedure division]
    
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
            . Format("{:04}", codeSections[A_Index].startStmt) . ", " 
            . Format("{:04}",codeSections[A_Index].endStmt) . ", "
            . Format("{:04}",codeSections[A_Index].callingStmt) . ","
            . Format("{:-30}",codeSections[A_Index].name) . ","
            . codeSections[A_Index].calledSection
            . "`n"
    allSections .= line
  }
}