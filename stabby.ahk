/*
    "sTabby" - a replacement for Windows' alt-tab navigation
    Copyright (C) 2014  David M. Bradford

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see https://www.gnu.org/licenses/gpl.txt

    The author, David M. Bradford, can be contacted at:
    davembradford@gmail.com

===================================
  stabby: stop the alt-tab madness!
===================================

TODO
----
 * Maybe don't overdo it/overthink it
 * documentation
 * Avoid assumptions such as
     * screen size
     * default font?
 * Possibilities
     * window is not visible?
 * Allow naming of key - override of window title
 * refactor (ongoing)
 * error checking

Maybe
-----
 * On startup, tries to hook you up with your last set of keys/windows
     * Including launching the apps themselves

DONE
----
 * Display what is currently set
 * Possibilities
     * window is closed
 * Should at least have option for main hotkey though
 * credits
 * window title
 * Ability to delete key from list
 * Ability to reassign key to different window

*/


#Warn All, OutputDebug
#SingleInstance ignore
#WinActivateForce

VERSION=0.9
DEMO=0

CoordMode, ToolTip, Screen

SplitPath, A_ScriptName,,, TheScriptExtension, TheScriptName
IniFile = %A_ScriptDir%\%TheScriptName%.ini
IconFile = %A_ScriptDir%\%TheScriptName%.ico
myerrorlevel=

if TheScriptExtension <> Exe
    menu, tray, icon,%IconFile%

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

Loop, parse, LetterKeys, `,
{
    IniRead, WinID, %IniFile%, settings, %A_LoopField%
    IfWinExist, ahk_id %WinID%
        KeyMap%A_LoopField% := WinID
}

Gui, font, s10, Courier New
Gui +AlwaysOnTop
MessageText := "Pick a key:"
Gui, Add, Text, W390 vMessage, %MessageText%
Gui, Add, Text, W390 H380 vTextVar

Gui +Disabled
Gui -SysMenu
Gui, 2:Add, Text, x6 y7 w50 h20 , &Hotkey
Gui, 2:Add, Hotkey, x66 y7 w90 h20 vChosenHotkey, %TriggerKey%
Gui, 2:Add, Button, Default x6 y37 w100 h30 , OK
Gui, 2:Add, Button, x116 y37 w100 h30 , Cancel
return

DisplayWindow:
    ShowTip("CapsLock")
    ShowMessage(MessageText)
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
                StringLeft, mytitle, Title, 25
                WinGet, myprocess, ProcessName
                myprocess := RegExReplace(myprocess, "\..*", "")
                Texty=%Texty%[%myletter%]     %myprocess%: %mytitle%`n
            }
            else
                clear_key(A_LoopField)
        }
    }

    Texty=
(
%Texty%

[space] reassign letter
[del]   delete letter
[esc]   dismiss this window
[home]  restart sTabby
)

    GuiControl, , TextVar, %Texty%
    Gosub, GetKey
    if buffer_key in %LetterKeys%
    {
        WinID := KeyMap%buffer_key%
        if( WinID )
            WinActivate ahk_id %WinID%
        else
            set_key(buffer_key,WinExist("A"))
    }
    else
    {
        if buffer_key=%A_Space%
        {
            ShowMessage("Enter letter to re-use:")
            Gosub, GetKey
            if buffer_key in %LetterKeys%
                set_key(buffer_key,WinExist("A"))
        }
        else if myerrorlevel=EndKey:Delete
        {
            ShowMessage("Enter letter to delete:")
            Gosub, GetKey
            if buffer_key in %LetterKeys%
                clear_key(buffer_key)
        }
        else if myerrorlevel=EndKey:Home
            Reload
    }
return


GetKey:
    Gui, Show, NoActivate Center W400 H420, sTabby! v%VERSION%
    Input, buffer_key, L1, {LControl}{RControl}{LAlt}{RAlt}{LShift}{RShift}{LWin}{RWin}{AppsKey}{F1}{F2}{F3}{F4}{F5}{F6}{F7}{F8}{F9}{F10}{F11}{F12}{Left}{Right}{Up}{Down}{Home}{End}{PgUp}{PgDn}{Del}{Ins}{BS}{Capslock}{Numlock}{PrintScreen}{Pause}
    ShowTip(buffer_key)
    myerrorlevel=%ErrorLevel%
    Gui, Hide
return


set_key(in_key,in_winid)
{
    global
    KeyMap%in_key% := in_winid
    IniWrite, %in_winid%, %IniFile%, Settings, %in_key%
    return
}


clear_key(in_key)
{
    global
    KeyMap%in_key%=
    IniWrite, %A_Space%, %IniFile%, Settings, %in_key%
    return
}


ShowMessage(mtext)
{
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


BuildIni:
    IniWrite, CapsLock, %IniFile%, settings, TriggerKey
return


GoAway:
    ExitApp
return


GetOptions:
    Gui, 2:Show, x131 y91 h82 w227, sTabby - Options
return


GoReload:
    Reload
return


ShowTip(text="no_message")
{
    global
    if(DEMO)
    {
        Progress, x0 y0 h50 cwFFFF00 m2 b fs28 zh0, %text%, , , Courier New
        SetTimer, DisablePoker, 750
    }
    return
}

DisablePoker:
    Progress, Off
return

