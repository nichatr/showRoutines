# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Todo]

- showPrograms:

  - find method to insert more spaces between program names and their descriptions.
  - add text to nodes of a boxed tree?

- parseRPG: the output section is not processed.

## 2021-01-02

- [x] showRoutines/showPrograms: move menu items Settings, Help one level up.

## 2020-12-31

- showRoutines:
  - hide declarations sub nodes.
  - added export to powerpoint (vertical).
  - added export to flowchart (vertical).
  - added title.

## 2020-12-25

- showRoutines: move the declaration sections to a main routine (name= declarations).

  - place declarations below MAIN.
    - cobol: environment|data|working-storage|linkage
    - rpg: file|data|input|output ??

## 2020-12-21

- DONE: showRoutines: replace MAIN with the program name, example: B9Y56. Applies to display, export.

## 2020-12-13

- DONE: replace fixed paths in batch script with %APPDATA% or %LOCALDATA% or %ONEDRIVE% (the last is better).

## 2020-11-30

- parseCOBOL.ahk: added 'exit program' keyword similar to 'goback' and 'exit'.
- moved prism.js and prism.css into main folder: otherwise cannot build the showRoutines.EXE program.
- tree diagram in zTree.html: changed refs to '..\prism.js/css'.

## 2020-11-27

- showRoutines:
  - fixed recursive routines calls: A -> B -> C -> A
- DONE: cobol
  - add the sections at the beginning: INPUT-OUTPUT|FILE|WORKING-STORAGE|LINKAGE
  - also replace the MAIN routine with [PROCEDURE DIVISION].
- DONE: rpg
  - add the sections at the beginning: H|F|D|I
  - also replace the MAIN routine with section [C].

## 2020-11-15

- DONE: correct the from/to statements for each routine (rpg) or section (cobol):
  - new from = previous to + 1.
  - new to = same as before.
- DONE: add button in appbar: show all code (same as refresh-F5).
- DONE: fix special char "\" conversion in showRoutines.ahk (see ZWFCON2.CBLLE at the start: \notes --> notes)
- DONE: cobol
  - highlight the "EXIT." if possible.
  - similar to rpg routines highlight:
    - use lookahead to highlight the section name.
    - change section highlight to red.
- DONE: investigate if it is possible.
  - in ztree when double-clicking on a node --> position to the selected routine/section in the code panel without reload.

## before 2020-11-11

- DONE: add sql language
- DONE: add rpg(le) language

## before 2020-11-08

- added second panel in html template to display the code.
- added cobol code highlighting (prism.js) --> see I:\web-ssd\apps\prism\prism-master.

### Changed

- fixed error in export to boxed html.

## 2020-07-27

### Changed

- added this changelog.
- added new html template for the CSS boxed diagram.
- added another export option: boxed tree.
- renmaed export option "html" to "folding tree".
- renamed existing html template.
