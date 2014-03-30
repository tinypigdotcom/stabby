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

VERSION=0.9.1
DEMO=0
SHOWTIP_DEBUG=3

; How Debug works:
; ================
; Default level for debug statements is 2.  Debug statements will only print if
; Master Debug Level >= statement level.  So, if you create a level 1 debug
; statement and set Master Debug Level to 1, only that one will print.  Setting
; Master Debug Level to 2 will trigger a lot of debug output.
;
; tscdebug.txt is created in script directory with all debug output
;
; Template debug statement:
;
; Debug("myvar: " . myvar,1) ;xd
;
debug_level=1
debug_text=

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
    if(WinID <> "ERROR")
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
    ShowKey("CapsLock")
    ShowMessage(MessageText)
    Texty=

    Loop, parse, LetterKeys, `,
    {
        WinID := KeyMap%A_LoopField%
        if( WinID )
        {
            IfWinNotExist, ahk_id %WinID%
            {
                IniRead, myprocess, %IniFile%, Executables, %A_LoopField%
                if(myprocess <> "ERROR")
                {
                    WinID := FindWindow(A_LoopField,myprocess)
                }
            }
            StringUpper, myletter, A_LoopField
            IfWinExist, ahk_id %WinID%
            {
                WinGetTitle, Title, ahk_id %WinID%
                StringLeft, mytitle, Title, 25
                WinGet, myprocess, ProcessName
                IniWrite, %myprocess%, %IniFile%, Executables, %A_LoopField%
                myprocess := RegExReplace(myprocess, "\..*", "")
                Texty=%Texty%[%myletter%]     %myprocess%: %mytitle%`n
            }
            else
            {
                IniRead, myprocess, %IniFile%, Executables, %A_LoopField%
                if(myprocess <> "ERROR")
                {
                    myprocess := RegExReplace(myprocess, "\..*", "")
                    Texty=%Texty%[%myletter%]     (%myprocess%)`n
                }
            }
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
    buffer_key := GetKey()
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
            buffer_key := GetKey("Enter letter to re-use:")
            if buffer_key in %LetterKeys%
                set_key(buffer_key,WinExist("A"))
        }
        else if myerrorlevel=EndKey:Delete
        {
            buffer_key := GetKey("Enter letter to delete:")
            if buffer_key in %LetterKeys%
                kill_key(buffer_key)
        }
        else if myerrorlevel=EndKey:Home
            Reload
    }
return


GetKey(prompt="Pick a key:")
{
    global

    ShowMessage(prompt)
    Gui, Show, NoActivate Center W400 H420, sTabby! v%VERSION%
    Input, gbuffer_key, L1,{LControl}{RControl}{LAlt}{RAlt}{LShift}{RShift}{LWin}{RWin}{AppsKey}{F1}{F2}{F3}{F4}{F5}{F6}{F7}{F8}{F9}{F10}{F11}{F12}{Left}{Right}{Up}{Down}{Home}{End}{PgUp}{PgDn}{Del}{Ins}{BS}{Capslock}{Numlock}{PrintScreen}{Pause}{Esc}

    myerrorlevel=%ErrorLevel%
    show_key:= gbuffer_key
    StringUpper, show_key, show_key
    if show_key = %A_Space%
    {
        show_key := "{Space}"

    }

    IfInString, myerrorlevel, EndKey:
    {
        StringReplace, show_key, myerrorlevel, EndKey:
        show_key := "{" . show_key . "}"
    }

    ShowKey(show_key)
    Gui, Hide
    return gbuffer_key
}


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
    IniDelete, %IniFile%, Settings, %in_key%
    return
}


kill_key(in_key)
{
    global
    clear_key(in_key)
    IniDelete, %IniFile%, Executables, %in_key%
    return
}


ShowMessage(mtext)
{
    GuiControl, , Message, %mtext%
    return
}


FindWindow(in_key,executable)
{
    global
    DetectHiddenWindows, Off

;    WinGet, id, list,,, Program Manager
    WinGet, id, list, ahk_exe %executable%
    outer:
    Loop, %id%
    {
        this_id := id%A_Index%
        Loop, parse, LetterKeys, `,
        {
            WinID := KeyMap%A_LoopField%
            if( WinID = this_id )
            {
                continue outer
            }
        }
        set_key(in_key,this_id)
        return this_id
    }
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


ShowKey(text="no_message")
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


ShowTip(text="",posx="",posy="",channel=1)
{
    ToolTip %text%, %posx%, %posy%, %channel%
    return
}


Debug(dtext,item_debug_level=2)
{
    global debug_level
    global debug_text

    FormatTime, TimeString,, yyyy-MM-dd HH:mm
    if(debug_level >= item_debug_level)
    {
        diagnostic_info=%TimeString% %A_ScriptName%
        FileAppend, %diagnostic_info%: %dtext%`r`n, %A_ScriptDir%\tscdebug.txt
        DebugText(dtext)
    }
    return
}


DebugText(dtext)
{
    global debug_text, SHOWTIP_DEBUG

    debug_x := A_ScreenWidth  - 400
    debug_y := A_ScreenHeight - 75

    if debug_text
    {
        debug_text = %debug_text%`n.    %dtext%
    }
    else
    {
        debug_text = .    %dtext%
    }
    debug_y_offset += 12
    tmp_debug_y := debug_y - debug_y_offset
    ShowTip(debug_text . "    `n", debug_x, tmp_debug_y, SHOWTIP_DEBUG)
    SetTimer, DisableDebugTip, 9000
    return
}


DisableDebugTip:
{
    global SHOWTIP_DEBUG
    debug_text=
    debug_y_offset = 0
    SetTimer, DisableDebugTip, Off
    ClearTip(SHOWTIP_DEBUG)
    return
}


ClearTip(channel=1)
{
    ToolTip,,,,%channel%
    return
}


