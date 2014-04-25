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

VERSION=0.9.1.9 ; vv
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
    menu, tray, icon, %IconFile%

menu, tray, NoStandard
menu, tray, add, Options, GetOptions
menu, tray, add, Reload, GoReload
menu, tray, add, Exit, GoAway

IfNotExist, %IniFile%
    Gosub, BuildIni

IniRead, TriggerKey, %IniFile%, settings, TriggerKey, CapsLock

Hotkey, %TriggerKey%, DisplayWindow
Hotkey, %TriggerKey%, On

valid_winids_a := [ ]
valid_winids_h := { }
;executables  := { }
;titles       := { }
;letter_wins  := { }

;found a window that isn't mapped to a key
;make a list of valid windows (visible, not weird)
;valid_win_ids[ ]
;win_ids
;win_ids{win_id} = letter

LetterKeys=A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z
all_letters_h := { }
all_letters_a := [ ]
keymap := { }

Loop, parse, LetterKeys, `,
{
    all_letters_h[A_LoopField] := 1
    all_letters_a.Insert(A_LoopField)
    IniRead, WinID, %IniFile%, settings, %A_LoopField%
    if(WinID <> "ERROR")
        keymap[A_LoopField] := WinID
}

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
remap_all_windows()

return

DisplayWindow:
    ShowKey("CapsLock")
    ShowMessage(MessageText)
    Texty=

    GoSub, refresh_unassigned

    for index, loop_letter in all_letters_a
    {
        WinID  := keymap[loop_letter]
        XWinID := "X" . WinID
        if( WinID )
        {
            if(!valid_winids_h[XWinID])
            {
                WinID := FindWindow(loop_letter)
                XWinID := "X" . WinID
            }
            if(valid_winids_h[XWinID])
            {
                WinGetTitle, Title, ahk_id %WinID%
                StringLeft, mytitle, Title, 25
                WinGet, myprocess, ProcessName, ahk_id %WinID%
                StringUpper, myprocess, myprocess
                IniWrite, %myprocess%, %IniFile%, Executables, %loop_letter%
                IniWrite, %Title%, %IniFile%, Titles, %loop_letter%
                myprocess := RegExReplace(myprocess, "\..*", "")
                Texty=%Texty%[%loop_letter%]  %myprocess% %mytitle%`n
                unassigned_letters.Remove(loop_letter)
                unassigned_windows.Remove(XWinID) ; can't concat
            }
            else
            {
                IniRead, myprocess, %IniFile%, Executables, %loop_letter%
                IniRead, mytitle, %IniFile%, Titles, %loop_letter%
                if(myprocess <> "ERROR" and mytitle <> "ERROR")
                {
                    myprocess := RegExReplace(myprocess, "\..*", "")
                    Texty=%Texty%[%loop_letter%]     (%myprocess%)`n
                    unassigned_letters.Remove(loop_letter)
                }
                else
                    kill_key(loop_letter)
            }
        }
    }

    Texty=
(
%Texty%
Unassigned`:`n`n
)

array_unassigned_letters := [ ]
For key, value in unassigned_letters
    array_unassigned_letters.Insert(key)

hash_letter_win := { }

for key, value in unassigned_windows
{
    XWinID := key
    StringMid, WinID, key, 2

    if(valid_winids_h[XWinID])
    {
        WinGetTitle, Title, ahk_id %WinID%
        StringLeft, mytitle, Title, 25
        WinGet, myprocess, ProcessName, ahk_id %WinID%
        myprocess := RegExReplace(myprocess, "\..*", "")

        next_letter := array_unassigned_letters.Remove(1)
        if(next_letter)
        {
            hash_letter_win[next_letter] := XWinID
            StringUpper, myprocess, myprocess
            Texty=%Texty%[%next_letter%]  %myprocess% %mytitle%`n
        }
    }
}

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
    if ( all_letters_h[buffer_key] )
    {
        WinID := keymap[buffer_key]
        if( WinID )
            WinActivate ahk_id %WinID%
        else
        {
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
    keymap[in_key] := in_winid
    IniWrite, %in_winid%, %IniFile%, Settings, %in_key%
    return
}


clear_key(in_key)
{
    global
    keymap.Remove(in_key)
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


;1. what is the question?
;2. don't answer a question that isn't being asked
remap_all_windows()
{
    global

    valid_winids_a := [ ]
    valid_winids_h := { }

    WinGet, id, list,,, Program Manager
    Loop, %id%
    {
        this_id := id%A_Index%
        save_id := "X" . this_id ; avoid conversion to decimal

        WinGetTitle, Title, ahk_id %this_id%
        if(!Title)
            continue
        WinGet, myprocess, ProcessName, ahk_id %this_id%

        WinGetPos, uX, uY, uWidth, uHeight, ahk_id %this_id%

        if( uX < 2 and xY < 2 and uWidth < 2 and uHeight < 2 )
            continue
        if( uX > VirtualWidth or uY > VirtualHeight )
            continue

        WinGetClass, this_class, ahk_id %this_id%
        if( this_class = "Button" )
            continue

        valid_winids_a.Insert(save_id)
        valid_winids_h[save_id] := 1
    }
    ;_({ debug: join(",", valid_winids_a) })
    debug({ param1: join(",", valid_winids_a), debug_level: 1, linenumber: A_LineNumber })
}


FindWindow(in_key)
{
    global

    IniRead, mytitle, %IniFile%, Titles, %in_key%
    IniRead, executable, %IniFile%, Executables, %in_key%

    if(myprocess = "ERROR" or mytitle = "ERROR")
        return

    DetectHiddenWindows, Off

    WinGet, id, list, ahk_exe %executable%
    outer:
    Loop, %id%
    {
        this_id := id%A_Index%
        WinGetTitle, this_title, ahk_id %this_id%
        Loop, parse, LetterKeys, `,
        {
            WinID := keymap[A_LoopField]
            if( WinID = this_id )
            {
                continue outer
            }
        }
        set_key(in_key,this_id)
        return this_id
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

;testext=
;For key, value in unassigned_windows
;    testext := concat([ testext, ":", key ])
;debug({ param1: testext, debug_level: 1, linenumber: loop_letter })
