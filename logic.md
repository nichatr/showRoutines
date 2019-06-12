
* if parms = true and select = false
    * load
    * on error: blank page

* else if select = true
   * UI select file

* else
   * load from .ini
   * on error: blank page

**---------------------------

## functions

* fileSelector()
    * input= home directory, filter
    * output= selected file

* initialize()
    * runs once only
    * check script arguments
    * check system (home/work)
    * set first filenames & paths

* setup()
    * runs every time a new file must be processed
    * initialize all variables
    * populate data structures

* showGui()

* 