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
 * Allow naming of key - override of window title
 * documentation
 * refactor (ongoing)
 * error checking (ongoing)

Maybe
-----
 * prompt upon find new window
 * On startup, tries to hook you up with your last set of keys/windows
     * Including launching the apps themselves

DONE
----
 * use associative array vs loop
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

VERSION=0.9.2.1 ; vv
DEMO=0

DetectHiddenWindows, Off
CoordMode, ToolTip, Screen

SysGet, VirtualWidth, 78
SysGet, VirtualHeight, 79

SplitPath, A_ScriptName,,, script_extension, script_name
ini_file = %A_ScriptDir%\%script_name%.ini
icon_file = %A_ScriptDir%\%script_name%.ico
error_level=

if script_extension <> Exe
    menu, tray, icon, %icon_file%

menu, tray, NoStandard
menu, tray, add, Options, get_options
menu, tray, add, Reload, go_reload
menu, tray, add, Exit, go_away

IfNotExist, %ini_file%
    Gosub, build_ini

IniRead, trigger_key, %ini_file%, settings, trigger_key, CapsLock

Hotkey, %trigger_key%, display_window
Hotkey, %trigger_key%, On

letter_keys=A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z

valid_winids_a       := [ ] ; array of currently open WinIDs
valid_winids_h       := { } ; hash of currently open WinIDs
all_letters_h        := { } ; Contain all letters in letter_keys for lookup
all_letters_a        := [ ] ; Contain all letters in letter_keys for looping
letter_to_win_id     := { } ; hash mapping assigned letter to WinID
win_id_to_letter     := { } ; hash mapping WinID to assigned letter
pretty_title         := { } ; hash of titles by WinID for printing
pretty_process       := { } ; hash of executables by WinID for printing
unassigned_to_win_id := { } ; hash mapping unassigned letter to WinID

Loop, parse, letter_keys, `,
{
    all_letters_h[A_LoopField] := 1
    all_letters_a.Insert(A_LoopField)

    IniRead, win_id, %ini_file%, settings, %A_LoopField%

    if(win_id <> "ERROR")
    {
        x_win_id := "X" . win_id
        letter_to_win_id[A_LoopField] := win_id
        win_id_to_letter[x_win_id] := A_LoopField
    }
}

message_text := "Pick a key:"
Gui, font, s10, Courier New
Gui, +AlwaysOnTop
Gui, Add, Text, W390      vmessage,      %message_text%
Gui, Add, Text, W390 H580 vtext_variable

Gui +Disabled
Gui -SysMenu

Gui, 2:Add, Text,              x12  y10  w50 h20               , &Hotkey
Gui, 2:Add, Hotkey,            x62  y10  w90 h20 vchosen_hotkey, %trigger_key%
Gui, 2:Add, CheckBox,          x22  y40 w200 h30               , Prompt before assigning key
Gui, 2:Add, CheckBox,          x22  y70 w200 h30               , Also list unassigned windows
Gui, 2:Add, CheckBox,          x22 y100 w200 h30               , CheckBox
Gui, 2:Add, CheckBox,          x22 y130 w200 h30               , CheckBox
Gui, 2:Add, CheckBox,          x22 y160 w200 h30               , CheckBox
Gui, 2:Add, Button,   Default  x12 y210 w100 h30               , OK
Gui, 2:Add, Button,           x112 y210 w100 h30               , Cancel
; Generated using SmartGUI Creator 4.0
remap_all_windows()

return

display_window:
    show_key("CapsLock")
    show_message(message_text)
    output=

    GoSub, refresh_unassigned ; TODO this should be included in remap_all_windows

    remap_all_windows()

    for index, loop_letter in all_letters_a
    {
        win_id   := letter_to_win_id[loop_letter]
        x_win_id := "X" . win_id
        if( win_id )
        {
            if( valid_winids_h[x_win_id] )
                output := output . "[" . loop_letter . "] " . pretty_process[x_win_id] . " " . pretty_title[x_win_id] . "`n"
            else
            {
                IniRead, _process, %ini_file%, Executables, %loop_letter%
                IniRead, _title,   %ini_file%, Titles,      %loop_letter%
                if(_process <> "ERROR" and _title <> "ERROR")
                {
                    _process := RegExReplace(_process, "\..*", "")
                    output := output . "[" . loop_letter . "] (" . _process . ")`n"
                    unassigned_letters.Remove(loop_letter)
                }
                else
                    kill_key(loop_letter)
            }
        }
    }

    output := output . "`nUnassigned:`n`n"

    ; TODO this should be included in remap_all_windows
    array_unassigned_letters := [ ]
    For key, value in unassigned_letters
        array_unassigned_letters.Insert(key)

    unassigned_to_win_id := { }

    for key, value in unassigned_windows
    {
        x_win_id := key
        StringMid, win_id, key, 2

        if ( valid_winids_h[x_win_id] )
        {
            next_letter := array_unassigned_letters.Remove(1)
            if( next_letter )
            {
                unassigned_to_win_id[next_letter] := x_win_id
                output := output . "[" . next_letter . "] " . pretty_process[x_win_id] . " " . pretty_title[x_win_id] . "`n"
            }
        }
    }


    output := output . "`n"
           . "[space] reassign letter`n"
           . "[del]   delete letter`n"
           . "[esc]   dismiss this window`n"
           . "[home]  restart sTabby`n"

    GuiControl, , text_variable, %output%
    buffer_key := GetKey()
    if ( all_letters_h[buffer_key] )
    {
        win_id := letter_to_win_id[buffer_key]
        if( win_id )
            WinActivate ahk_id %win_id%
        else
        {
            if( unassigned_to_win_id[buffer_key] )
            {
                win_id := unassigned_to_win_id[buffer_key]
                StringMid, win_id, win_id, 2
                WinActivate ahk_id %win_id%
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
            if( all_letters_h[buffer_key] )
                set_key(buffer_key,WinExist("A"))
        }
        else if error_level=EndKey:Delete
        {
            buffer_key := GetKey("Enter letter to delete:")
            if( all_letters_h[buffer_key] )
                kill_key(buffer_key)
        }
        else if error_level=EndKey:Home
            Reload
    }
return


GetKey(prompt="Pick a key:")
{
    global

    show_message(prompt)
    Gui, Show, NoActivate Center W400 H620, sTabby! v%VERSION%
    Input, gbuffer_key, L1,{LControl}{RControl}{LAlt}{RAlt}{LShift}{RShift}{LWin}{RWin}{AppsKey}{F1}{F2}{F3}{F4}{F5}{F6}{F7}{F8}{F9}{F10}{F11}{F12}{Left}{Right}{Up}{Down}{Home}{End}{PgUp}{PgDn}{Del}{Ins}{BS}{Capslock}{Numlock}{PrintScreen}{Pause}{Esc}

    error_level=%ErrorLevel%
    show_key:= gbuffer_key
    StringUpper, show_key, show_key
    if show_key = %A_Space%
    {
        show_key := "{Space}"

    }

    IfInString, error_level, EndKey:
    {
        StringReplace, show_key, error_level, EndKey:
        show_key := "{" . show_key . "}"
    }

    show_key(show_key)
    Gui, Hide
    return gbuffer_key
}


set_key(in_key,in_winid)
{
    global
    letter_to_win_id[in_key] := in_winid
    x_win_id := "X" . in_winid
    win_id_to_letter[x_win_id] := in_key
    IniWrite, %in_winid%, %ini_file%, Settings, %in_key%
    return
}


clear_key(in_key)
{
    global
    x_win_id := "X" . letter_to_win_id.Remove(in_key)
    win_id_to_letter.Remove(x_win_id)
    IniDelete, %ini_file%, Settings, %in_key%
    return
}


kill_key(in_key)
{
    global
    clear_key(in_key)
    IniDelete, %ini_file%, Executables, %in_key%
    IniDelete, %ini_file%, Titles, %in_key%
    return
}


show_message(mtext)
{
    GuiControl, , message, %mtext%
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
        x_win_id := "X" . this_id ; avoid conversion to decimal

        WinGetTitle, Title, ahk_id %this_id%
        if(!Title)
            continue
        WinGet, _process, ProcessName, ahk_id %this_id%

        WinGetPos, uX, uY, uWidth, uHeight, ahk_id %this_id%

        if( uX < 2 and xY < 2 and uWidth < 2 and uHeight < 2 )
            continue
        if( uX > VirtualWidth or uY > VirtualHeight )
            continue

        WinGetClass, this_class, ahk_id %this_id%
        if( this_class = "Button" )
            continue

        WinGetTitle, Title, ahk_id %this_id%
        StringLeft, _title, Title, 25
        WinGet, currentprocess, ProcessName, ahk_id %this_id%
        StringUpper, _process, currentprocess
        _process := RegExReplace(_process, "\..*", "")
        _process := SubStr(_process . "         ", 1, 8)
        pretty_title[x_win_id] := _title
        pretty_process[x_win_id] := _process

        current_letter := win_id_to_letter[x_win_id]
        if ( current_letter )
        {
            IniWrite, %currentprocess%, %ini_file%, Executables, %current_letter%
            IniWrite, %Title%, %ini_file%, Titles, %current_letter%
            unassigned_letters.Remove(current_letter)
            unassigned_windows.Remove(x_win_id)
        }
        valid_winids_a.Insert(x_win_id)
        valid_winids_h[x_win_id] := 1
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
;    debug({ param1: concat([ "string1{", string1, "}" ]), debug_level: 1, linenumber: A_LineNumber })
;    debug({ param1: concat([ "string2{", string2, "}" ]), debug_level: 1, linenumber: A_LineNumber })
    if(string1 = string2)
        return 1
    else
        return 0
}


2ButtonOK:  ; This section is used by the "about box" above.
    Gui, 2:Submit
    Hotkey, %trigger_key%, Off
    trigger_key=%chosen_hotkey%
    IniWrite, %trigger_key%, %ini_file%, settings, trigger_key
    Hotkey, %trigger_key%, display_window
    Hotkey, %trigger_key%, On
return


2ButtonCancel:
2GuiClose:
2GuiEscape:
    Gui, 2:Hide
return


build_ini:
    IniWrite, CapsLock, %ini_file%, settings, trigger_key
return


go_away:
    ExitApp
return


get_options:
    Gui, 2:Default
    GuiControl, , chosen_hotkey, %trigger_key%
    GuiControl, Focus, chosen_hotkey
    Gui, Show, x560 y295 h260 w225, sTabby - Options
return


go_reload:
    Reload
return


show_key(text="no_message")
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
    unassigned_letters := { }
    for index, loop_letter in all_letters_a
        unassigned_letters[loop_letter] := 1

    unassigned_windows := { }
    WinGet, id, list,,, Program Manager
    Loop, %id%
    {
        this_id := id%A_Index%
        x_win_id := "X" . this_id ; avoid conversion to decimal
        unassigned_windows[x_win_id] := 1
    }
return

;testext=
;For key, value in unassigned_windows
;    testext := concat([ testext, ":", key ])
;debug({ param1: testext, debug_level: 1, linenumber: loop_letter })

;E-CIN &
;E-DTT an unescaped colon in "heredoc" fails quietly. Why?!?

; Removing Find Window because it is having the key and asking
; where is its window, but we should be taking the unmapped window
; and asking where is its key.
