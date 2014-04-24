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
 * allow disable of alt tab at global level via tray menu via another program
   like "stab" maybe?
 * use associative array vs loop
 * prompt upon find new window
 * documentation
 * Allow naming of key - override of window title
 * refactor (ongoing)
 * error checking

Maybe
-----
 * On startup, tries to hook you up with your last set of keys/windows
     * Including launching the apps themselves

DONE
----
 * Possibilities
     * window is not visible? (detect hidden windows off)
 * Avoid assumptions such as
     * screen size
     * default font?
 * Maybe don't overdo it/overthink it
 * show all windows not just unassigned
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

do_macros()

VERSION=0.9.1.5 ; vv
DEMO=0

DetectHiddenWindows, Off
CoordMode, ToolTip, Screen

SysGet, VirtualWidth, 78
SysGet, VirtualHeight, 79

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
all_letters := { aaa: 1 }

Loop, parse, LetterKeys, `,
{
    all_letters[A_LoopField] := 1
    IniRead, WinID, %IniFile%, settings, %A_LoopField%
    if(WinID <> "ERROR")
        KeyMap%A_LoopField% := WinID
}
all_letters.Remove("aaa")

Gui, font, s10, Courier New
Gui +AlwaysOnTop
MessageText := "Pick a key:"
Gui, Add, Text, W390 vMessage, %MessageText%
Gui, Add, Text, W390 H580 vTextVar

Gui +Disabled
Gui -SysMenu


Gui, 2:Add, Text, x12 y10 w50 h20 , &Hotkey
Gui, 2:Add, Hotkey, x62 y10 w90 h20 vChosenHotkey, %TriggerKey%
Gui, 2:Add, CheckBox, x22 y40 w200 h30 , Prompt before assigning key
Gui, 2:Add, CheckBox, x22 y70 w200 h30 , Also list unassigned windows
Gui, 2:Add, CheckBox, x22 y100 w200 h30 , CheckBox
Gui, 2:Add, CheckBox, x22 y130 w200 h30 , CheckBox
Gui, 2:Add, CheckBox, x22 y160 w200 h30 , CheckBox
Gui, 2:Add, Button, Default x12 y210 w100 h30 , OK
Gui, 2:Add, Button, x112 y210 w100 h30 , Cancel
; Generated using SmartGUI Creator 4.0

return

DisplayWindow:
    ShowKey("CapsLock")
    ShowMessage(MessageText)
    Texty=

    GoSub, refresh_unassigned

    Loop, parse, LetterKeys, `,
    {
        WinID := KeyMap%A_LoopField%
        if( WinID )
        {
            IfWinNotExist, ahk_id %WinID%
            {
                IniRead, mytitle, %IniFile%, Titles, %A_LoopField%
                IniRead, myprocess, %IniFile%, Executables, %A_LoopField%
                if(myprocess <> "ERROR" and mytitle <> "ERROR")
                {
                    WinID := FindWindow(A_LoopField,myprocess,mytitle)
                }
            }
            StringUpper, myletter, A_LoopField
            IfWinExist, ahk_id %WinID%
            {
                WinGetTitle, Title, ahk_id %WinID%
                StringLeft, mytitle, Title, 25
                WinGet, myprocess, ProcessName
                IniWrite, %myprocess%, %IniFile%, Executables, %A_LoopField%
                IniWrite, %Title%, %IniFile%, Titles, %A_LoopField%
                myprocess := RegExReplace(myprocess, "\..*", "")
                Texty=%Texty%[%myletter%]     %myprocess%: %mytitle%`n
                unassigned_letters.Remove(A_LoopField)
                unassigned_windows.Remove("X" . WinID) ; can't concat
;testext=
;For key, value in unassigned_windows
;    testext := concat([ testext, ":", key ])
;debug({ param1: testext, debug_level: 1, linenumber: A_LineNumber })
            }
            else
            {
                IniRead, myprocess, %IniFile%, Executables, %A_LoopField%
                IniRead, mytitle, %IniFile%, Titles, %A_LoopField%
                if(myprocess <> "ERROR" and mytitle <> "ERROR")
                {
                    myprocess := RegExReplace(myprocess, "\..*", "")
                    Texty=%Texty%[%myletter%]     (%myprocess%)`n
                    unassigned_letters.Remove(A_LoopField)
                }
                else
                    kill_key(myletter)
            }
        }
    }

    Texty=
(
%Texty%
Unassigned`:`n`n
)

array_unassigned_letters := ["aaa"]
For key, value in unassigned_letters
    array_unassigned_letters.Insert(key)

array_unassigned_letters.Remove(1)
hash_letter_win := { aaa:1 }

For key, value in unassigned_windows
{
    StringMid, WinID, key, 2

    IfWinExist, ahk_id %WinID%
    {
        WinGetTitle, Title, ahk_id %WinID%
        if(!Title)
            continue
        StringLeft, mytitle, Title, 25
        WinGet, myprocess, ProcessName
        myprocess := RegExReplace(myprocess, "\..*", "")
        WinGetPos, uX, uY, uWidth, uHeight

        if( uX < 2 and xY < 2 and uWidth < 2 and uHeight < 2 )
            continue
        if( uX > VirtualWidth or uY > VirtualHeight )
            continue

        WinGetClass, this_class, ahk_id %WinID%
        if( this_class = "Button" )
            continue

        next_letter := array_unassigned_letters.Remove(1)
        if(next_letter)
        {
            hash_letter_win[next_letter] := "X" . WinID
            StringUpper, next_letter, next_letter
            Texty=%Texty%[%next_letter%]     %myprocess%: %mytitle%`n
        }
    }
}
hash_letter_win.Remove("aaa")

;loop through unassigned windows

;E-CIN &
;E-DTT an unescaped colon on the line above after "Unassigned" makes the whole
;thing fail quietly. Why?!?

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
        {
;            debug({ param1: concat([ buffer_key, " has a WinID" ]), debug_level: 1, linenumber: A_LineNumber })
;            IfWinExist, ahk_id %WinID%
;            {
;                debug({ param1: concat([ buffer_key, " has a WinID that exists" ]), debug_level: 1, linenumber: A_LineNumber })
;            }

            WinActivate ahk_id %WinID%
        }
        else
        {
            ;debug({ param1: concat([ buffer_key, " has no WinID" ]), debug_level: 1, linenumber: A_LineNumber })
            if( hash_letter_win[buffer_key] )
            {
                WinID := hash_letter_win[buffer_key]
                StringMid, WinID, WinID, 2
                WinActivate ahk_id %WinID%
            }
            else
                set_key(buffer_key,WinExist("A"))
        }
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
    Gui, Show, NoActivate Center W400 H620, sTabby! v%VERSION%
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
    IniDelete, %IniFile%, Titles, %in_key%
    return
}


ShowMessage(mtext)
{
    GuiControl, , Message, %mtext%
    return
}


FindWindow(in_key,executable,title)
{
    global
    DetectHiddenWindows, Off

    ;debug({ param1: concat([ "executable{", executable, "} title{", title,"}" ]), debug_level: 1, linenumber: A_LineNumber })

    first_found_id=

;FAILING because we loop through WINDOW list, not matching keys-executables list
;    WinGet, id, list,,, Program Manager
    WinGet, id, list, ahk_exe %executable%
    outer:
    Loop, %id%
    {
        this_id := id%A_Index%
        WinGetTitle, this_title, ahk_id %this_id%
        ;debug({ param1: concat([ "--this_title{", this_title, "} title{", title,"}" ]), debug_level: 1, linenumber: A_LineNumber })
        Loop, parse, LetterKeys, `,
        {
            WinID := KeyMap%A_LoopField%
            if( WinID = this_id )
            {
                continue outer
            }
        }
        ;take the first one that matches the executable AND is not assigned to
        ;another key
        ;so... INSTEAD, just save the first one and use that if we don't find
        ;an exact title match by the end.
        if(!first_found_id)
        {
            first_found_id := this_id
        }
        if( same( this_title, title ) )
        {
            ;debug({ param1: "title match", debug_level: 1, linenumber: A_LineNumber })
            set_key(in_key,this_id)
            return this_id
        }
    }
    if(first_found_id)
    {
        ;_({ debug: "first found" })
        ;debug({ param1: "first found", debug_level: 1, linenumber: A_LineNumber })
        set_key(in_key,first_found_id)
        return first_found_id
    }
}

same(string1,string2)
{
    string1len := StrLen(string1)
    string2len := StrLen(string2)
    if(string1len > string2len)
        string1 := SubStr(string1, 1, string2len)
    else if(string2len > string1len)
        string2 := SubStr(string2, 1, string1len)
    debug({ param1: concat([ "string1{", string1, "}" ]), debug_level: 1, linenumber: A_LineNumber })
    debug({ param1: concat([ "string2{", string2, "}" ]), debug_level: 1, linenumber: A_LineNumber })
    if(string1 = string2)
        return 1
    else
        return 0
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
    Gui, 2:Default
    GuiControl, , ChosenHotkey, %TriggerKey%
    GuiControl, Focus, ChosenHotkey
    Gui, Show, x560 y295 h260 w225, sTabby - Options
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


refresh_unassigned:
    unassigned_letters := { aaa: 1 }
    Loop, parse, LetterKeys, `,
        unassigned_letters[A_LoopField] := 1
    unassigned_letters.Remove("aaa")

    unassigned_windows := { aaa: 1 }
    WinGet, id, list,,, Program Manager
    Loop, %id%
    {
        this_id := id%A_Index%
        save_id := "X" . this_id ; avoid conversion to decimal
        unassigned_windows[save_id] := 1
    }
    unassigned_windows.Remove("aaa")
return

