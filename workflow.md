<center> <h1>ShowRoutines workflow</h1> </center>

### Function: to show called routines of a cobol program in tree view.

<center> <h2>In AS400</h2> </center>

CBTREE command with the required cobol program

1. create file with calling/called routine pairs
2. convert above file to txt
3. convert program source to txt using command CVTSRC
4. copy both files to IFS folder.
5. run batch program: **showRoutines.bat** using STRPCO command.
   1. exexcute autohotkey.exe showRoutines.ahk %1 %2 %3
   2. for the 3 parameters see below.

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

- showGui()

-
