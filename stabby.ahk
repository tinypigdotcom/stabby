;    "sTabby" - a replacement for Windows' alt-tab navigation
;    Copyright (C) 2014  David M. Bradford
;
;    This program is free software: you can redistribute it and/or modify
;    it under the terms of the GNU General Public License as published by
;    the Free Software Foundation, either version 3 of the License, or
;    (at your option) any later version.
;
;    This program is distributed in the hope that it will be useful,
;    but WITHOUT ANY WARRANTY; without even the implied warranty of
;    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;    GNU General Public License for more details.
;
;    You should have received a copy of the GNU General Public License
;    along with this program.  If not, see https://www.gnu.org/licenses/gpl.txt
;
;    The author, David M. Bradford, can be contacted at:
;    davembradford@gmail.com
;
;Scaffolding_section <-- A quick shortcut to whatever part I'm currently working on
;____Approximate_middle_of_table_of_contents
; MsgBox, 0, , %KeyList%, 1 ;DEBUG
/*

===================================
  stabby: stop the alt-tab madness!
===================================

Table_of_Contents
-----------------
Build_GUI
____Approximate_middle_of_table_of_contents
Initialization_section

TODO
----
 * documentation
 * credits
 * license
 * window title
 * Maybe don't overdo it/overthink it
 * Should at least have option for main hotkey though
 * Ability to delete key from list
 * Avoid assumptions such as
     * screen size
     * default font?
 * Possibilities
     * window is not visible?
 * Allow naming of key - override of window title
 * refactor
 * error checking

Maybe
-----
 * Ability to reassign key to different window
 * On startup, tries to hook you up with your last set of keys/windows
     * Including launching the apps themselves

DONE
----
 * Display what is currently set
 * Possibilities
     * window is closed

*/


;===[  Initialization_section  ]==============================================

#Warn All, OutputDebug
#SingleInstance ignore
#WinActivateForce

VERSION=0.2

SplitPath, A_ScriptName,,, TheScriptExtension, TheScriptName
IniFile = %A_ScriptDir%\%TheScriptName%.ini
IconFile = %A_ScriptDir%\%TheScriptName%.ico

if TheScriptExtension = Exe
{
}
else
{
    menu, tray, icon,%IconFile%
}

menu, tray, NoStandard
menu, tray, add, Options, GetOptions
menu, tray, add, Reload, GoReload
menu, tray, add, Exit, GoAway

IfNotExist, %IniFile%
    Gosub, BuildIni

IniRead, TriggerKey, %IniFile%, settings, TriggerKey, CapsLock

Hotkey, %TriggerKey%, DisplayWindow
Hotkey, %TriggerKey%, On

LetterKeys=a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z

;===[  Build_GUI  ]===========================================================

Gui, font, s10, Courier New
Gui +AlwaysOnTop
Gui, Add, Text,  vMessage, Pick a key (A-Z), Space to reassign, or Esc
Gui, Add, Text, W390 H380 vTextVar

Gui, 2:Add, Text, x6 y7 w50 h20 , &Hotkey
Gui, 2:Add, Hotkey, x66 y7 w90 h20 vChosenHotkey, %TriggerKey%
Gui, 2:Add, Button, Default x6 y37 w100 h30 , OK
Gui, 2:Add, Button, x116 y37 w100 h30 , Cancel
return

DisplayWindow:
    Texty=

    Loop, parse, LetterKeys, `,
    {
        WinID := KeyMap%A_LoopField%
        if( WinID )
        {
            IfWinExist, ahk_id %WinID%
            {
                StringUpper, myletter, A_LoopField
                WinGetTitle, Title, ahk_id %WinID%
                Texty=%Texty%[%myletter%] - %Title%`n
            }
            else
            {
                KeyMap%A_LoopField%=
            }
        }
    }
    GuiControl, , TextVar, %Texty%
    ShowGUI()
    Gosub, GetKey
    Gui, Hide
    if buffer_key in %LetterKeys%
    {
        WinID := KeyMap%buffer_key%
        if( WinID )
        {
            WinActivate ahk_id %WinID%
        }
        else
        {
            KeyMap%buffer_key% := WinExist("A")
;            MsgBox, 0, , %KeyList%, 1
;Scaffolding_section
        }
    }
    else
    {
        if buffer_key=%A_Space%
        {
            ShowMessage("Enter letter to re-use:")
            ShowGUI()
            Gosub, GetKey
            Gui, Hide
            if buffer_key in %LetterKeys%
            {
                KeyMap%buffer_key% := WinExist("A")
            }
        }
    }
return

;------------------------------------------------------------------------------
GetKey:
;------------------------------------------------------------------------------
    Input, buffer_key, L1, {LControl}{RControl}{LAlt}{RAlt}{LShift}{RShift}{LWin}{RWin}{AppsKey}{F1}{F2}{F3}{F4}{F5}{F6}{F7}{F8}{F9}{F10}{F11}{F12}{Left}{Right}{Up}{Down}{Home}{End}{PgUp}{PgDn}{Del}{Ins}{BS}{Capslock}{Numlock}{PrintScreen}{Pause}
return


;EndKey:Delete

;------------------------------------------------------------------------------
ShowGUI()
;------------------------------------------------------------------------------
{
    Gui, Show, NoActivate Center W400 H420, sTabby!
    return
}


;------------------------------------------------------------------------------
ShowMessage(mtext)
;------------------------------------------------------------------------------
{
;    global Message
    GuiControl, , Message, %mtext%
    return
}


2ButtonOK:  ; This section is used by the "about box" above.
    Gui, 2:Submit
    Hotkey, %TriggerKey%, Off
    TriggerKey=%ChosenHotkey%
    IniWrite, %TriggerKey%, %IniFile%, settings, TriggerKey
    Hotkey, %TriggerKey%, DisplayWindow
    Hotkey, %TriggerKey%, On
return

2ButtonCancel:
2GuiClose:
2GuiEscape:
    Gui, 2:Hide
return

;------------------------------------------------------------------------------
BuildIni:
;------------------------------------------------------------------------------
    IniWrite, CapsLock, %IniFile%, settings, TriggerKey
return

TestToggleEnable:
return


GoAway:
    ExitApp
return

GetOptions:
    Gui, 2:Show, x131 y91 h82 w227, New GUI Window
return

GoReload:
    MsgBox, 4, Reload, Reloading will wipe out your keys.  Continue?
    IfMsgBox Yes
        Reload
return


