<center> <h1>ShowRoutines workflow</h1> </center>

### Function: to show called routines of a cobol program in tree view.

<center> <h2>In AS400</h2> </center>

CBTREE command with the required cobol program

1. create file with calling/called routine pairs
2. convert above file to txt
3. convert program source to txt using command CVTSRC
4. copy both files to IFS folder.
5. run batch program: **showRoutines.bat** using STRPCO command.
   - exexcute **autohotkey.exe showRoutines.ahk %1 %2 %3**
   - for the 3 parameters see below.

<center> <h2>In showRoutines.ahk</h2> </center>

#### Parameters

- if parms = true and select = false

  - load
  - on error: blank page

- else if select = true

  - UI select file

- else
  - load from .ini
  - on error: blank page

#### functions

```javascript
  initialize()
  mainProcess()
  return
  mainProcess() {
      setup()
      populateRoutines()
      populateCode()
      loadTreeview()
      updateStatusBar()
      showGui()
  }
```

- fileSelector()

  - input= home directory, filter
  - output= selected file

- initialize()

  - runs once only
  - check script arguments
  - check system (home/work)
  - set first filenames & paths

- setup()

  - runs every time a new file must be processed
  - initialize all variables
  - populate data structures

- populateRoutines()

  - read text file with routine calls
  - for each line:
    - parseLine()
    - searchRoutine()
    - if not found: createRoutineItem()
    - else: updateRoutineItem()
  - at end object allRoutines holds each routine and the routines that calls.

- loadTreeview()

  - processRoutine(allRoutines[1]) // it is always MAIN

- processRoutine(currRoutine)

  - addToTreeview(currRoutine)
  - for each called in currRoutine:
    - processRoutine(called)

- showGui()

-
