msgbox, % A_Args.length()
return

for n, param in A_Args  ; For each parameter:
{
    MsgBox Parameter number %n% is %param%.
}

msgbox, end of process
return


