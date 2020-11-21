#SingleInstance, Force
SetWorkingDir, %A_ScriptDir%

parsingSteps := [ "identification-division"
                , "environment-division"
                , "data-division"
                , "file-section"
                , "working-storage-section"
                , "linkage-section"
                , "procedure-division"]

parsingRegex := [ "im)^[^\*]\s*identification\s+division\s*\."
                , "im)^[^\*]\s*environment\s+division\s*\."
                , "im)^[^\*]\s*data\s+division\s*\."
                , "im)^[^\*]\s*file\s+section\s*\."
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
fileCode := "B9Y36.cblle"  ; "ZWFCON2 copy.CBLLE"
fullFileCode := path . fileCode
language := "cobol"
FileEncoding, CP1253

global allCode := []
global allSections := ""
global codeSections := []
global currentRoutine := "MAIN"
global routineName
global calledRoutines := [], calledStmts := []

foundMAINB := False ; when true add standard sections 1000-,2000-,3000-,4000-
checkForMAINB := True ; when true check if [COPY MAINB.] exists, but after first procedure division's section is found stop checking.

currentStep := 1

; read all code one line at a time and parse.
Loop, Read, %fullFileCode%
{
  allCode.push(A_LoopReadLine)
  
  ; if main sections parsed or it is comment/spaces don't parse this.
  if (RegExMatch(A_LoopReadLine, "im)^\s*\*.*$") || Trim(A_LoopReadLine) = "")
    Continue  ; parse next stmt

  ;----------------------------------------
  ; if main sections (1-7) not parsed yet: parse current section.
  ;----------------------------------------
  if (currentStep <= 7 && RegExMatch(A_LoopReadLine, parsingRegex[currentStep])) {
    if (currentStep > 1) {
      codeSections[currentStep - 1].endStmt := A_Index - 1
    }

    newSection := {}
    newSection.name := parsingSteps[currentStep]
    newSection.startStmt := currentStep == 1 ? 1 : (A_Index - 1)
    newSection.callingStmt := 0
    codeSections.push(newSection)
    
    currentStep ++
    Continue  ; parse next stmt
  }

  if (currentStep <= 7)
    Continue  ; parse next stmt
  
  ; all 7 main sections are parsed.
  ; parse routines.

  ;----------------------------------------
  ; check if exists [COPY MAINB.] --> it is a Life400 batch program, so standard routines must be added.
  ;----------------------------------------
  if (checkForMAINB && RegExMatch(A_LoopReadLine, parsingRegex[8])) {
    checkForMAINB := False
    foundMAINB := True
    addLife400BatchRoutines(A_Index)
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
    currentRoutine := matchedString ; keep routine name.
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
; codeSections[currentStep - 1].endStmt := allCode.MaxIndex()

addMainSections()
saveSection(codeSections)

; match non-comment line containing "environment division."
; ^[^\*]\s*environment\s+division\s*\.

filename := A_ScriptDir . "\codeCalls.txt"
if FileExist(filename)
  FileDelete, %filename%

FileEncoding, UTF-8
FileAppend, %allSections%, %filename%

ExitApp

  ;---------------------------------------------------------------
  ; 
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

  Loop, % parsingSteps.MaxIndex() {
    
    newSection := {}
    newSection.name := currentRoutine
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
saveSection(codeSections) {
  global
  
  Loop, % codeSections.MaxIndex() {

    line := codeSections[A_Index].startStmt . ", " 
            . codeSections[A_Index].endStmt . ", "
            . codeSections[A_Index].callingStmt . ", "
            . codeSections[A_Index].name . ", "
            . codeSections[A_Index].calledSection
            . "`n"
    allSections .= line
  }
}