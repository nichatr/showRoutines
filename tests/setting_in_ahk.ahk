; any AutoHotkey version
; your script
 
; to read:
; IniRead, Key1, %A_ScriptFullPath%, settings, key1
; msgbox, % key1
 
; to write:
IniWrite, "key2 new value", %A_ScriptFullPath%, settings, key2
 
/*
[settings]
key1=value of key1
key2="key2 new value"
 
*/
