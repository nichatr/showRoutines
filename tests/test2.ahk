; https://autohotkey.com/board/topic/89793-set-height-of-listbox-rows/

#NoEnv
LBS_NOINTEGRALHEIGHT := 0x0100
Gui, Margin, 10, 10
Gui, Add, ListBox, w300 r6 hwndHListBox +0x0100, 1|2|3|4|5|6
Gui, Add, Button, wp gIncreaseHeight, Increase Height by 4 Pixel
Gui, Show, , ListBox
Return

GuiClose:
ExitApp

IncreaseHeight:
   LB_AdjustItemHeight(HListBox, 4)
Return

LB_AdjustItemHeight(HListBox, Adjust) {
   Return LB_SetItemHeight(HListBox, LB_GetItemHeight(HListBox) - Adjust)
}

LB_GetItemHeight(HListBox) {
   Static LB_GETITEMHEIGHT := 0x01A1
   SendMessage, %LB_GETITEMHEIGHT%, 0, 0, , ahk_id %HListBox%
   Return ErrorLevel
}

LB_SetItemHeight(HListBox, NewHeight) {
   Static LB_SETITEMHEIGHT := 0x01A0
   SendMessage, %LB_SETITEMHEIGHT%, 0, %NewHeight%, , ahk_id %HListBox%
   WinSet, Redraw, , ahk_id %HListBox%
   Return ErrorLevel
}