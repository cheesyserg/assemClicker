.386
.model flat, stdcall
option casemap:none

includelib user32.lib
includelib kernel32.lib

; --- 1. STRUCTURES ---
POINT STRUCT
    x DWORD ?
    y DWORD ?
POINT ENDS

MOUSEINPUT STRUCT
    dx_         DWORD ?
    dy_         DWORD ?
    mouseData   DWORD ?
    dwFlags     DWORD ?
    time        DWORD ?
    dwExtraInfo DWORD ?
MOUSEINPUT ENDS

INPUT STRUCT
    type_       DWORD ?
    mi          MOUSEINPUT <>
    padding     DWORD ? 
INPUT ENDS

; --- 2. PROTOTYPES ---
GetModuleHandleA PROTO :DWORD
DialogBoxParamA PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
ExitProcess PROTO :DWORD
RegisterHotKey PROTO :DWORD, :DWORD, :DWORD, :DWORD
UnregisterHotKey PROTO :DWORD, :DWORD
SetDlgItemInt PROTO :DWORD, :DWORD, :DWORD, :DWORD
GetDlgItemInt PROTO :DWORD, :DWORD, :DWORD, :DWORD
SetDlgItemTextA PROTO :DWORD, :DWORD, :DWORD
GetDlgItemTextA PROTO :DWORD, :DWORD, :DWORD, :DWORD
SetTimer PROTO :DWORD, :DWORD, :DWORD, :DWORD
KillTimer PROTO :DWORD, :DWORD
SendInput PROTO :DWORD, :DWORD, :DWORD
EndDialog PROTO :DWORD, :DWORD
MessageBoxA PROTO :DWORD, :DWORD, :DWORD, :DWORD
SendDlgItemMessageA PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
EnableWindow PROTO :DWORD, :DWORD
GetDlgItem PROTO :DWORD, :DWORD
SetFocus PROTO :DWORD
SetCursorPos PROTO :DWORD, :DWORD
SetWindowsHookExA PROTO :DWORD, :DWORD, :DWORD, :DWORD
UnhookWindowsHookEx PROTO :DWORD
CallNextHookEx PROTO :DWORD, :DWORD, :DWORD, :DWORD
GetCursorPos PROTO :DWORD
CreateWindowExA PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
SetWindowTextA PROTO :DWORD, :DWORD
SetWindowPos PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
DestroyWindow PROTO :DWORD
GetAsyncKeyState PROTO :DWORD
MapVirtualKeyA PROTO :DWORD, :DWORD
GetKeyNameTextA PROTO :DWORD, :DWORD, :DWORD
wsprintfA PROTO C :DWORD, :DWORD, :VARARG
GetPrivateProfileIntA PROTO :DWORD, :DWORD, :DWORD, :DWORD
WritePrivateProfileStringA PROTO :DWORD, :DWORD, :DWORD, :DWORD
GetTickCount PROTO

; Added Prototypes for Icon Support
LoadIconA PROTO :DWORD, :DWORD
SendMessageA PROTO :DWORD, :DWORD, :DWORD, :DWORD

DlgProc PROTO :DWORD, :DWORD, :DWORD, :DWORD
AboutDlgProc PROTO :DWORD, :DWORD, :DWORD, :DWORD
HotkeyDlgProc PROTO :DWORD, :DWORD, :DWORD, :DWORD
MouseProc PROTO :DWORD, :DWORD, :DWORD
KbProc PROTO :DWORD, :DWORD, :DWORD
UpdateMainButtons PROTO :DWORD
StartClicking PROTO :DWORD
StopClicking PROTO :DWORD
SaveSettings PROTO :DWORD
LoadSettings PROTO :DWORD
GetRandomInterval PROTO :DWORD, :DWORD

.data
    WM_SETICON  equ 80h
    ICON_SMALL   equ 0
    ICON_BIG     equ 1
    inputDown  INPUT <0, <0, 0, 0, 0002h, 0, 0>> 
    inputUp    INPUT <0, <0, 0, 0, 0004h, 0, 0>> 
    infoMsg    db "Random offset varies the delay between clicks to mimic human behavior.", 0
    infoCap    db "Info", 0
    szStatic   db "STATIC", 0
    fmtStr     db "X: %d, Y: %d", 13, 10, "Click to Pick", 0
    fmtInt     db "%d", 0
    cbLeft     db "Left", 0
    cbRight    db "Right", 0
    cbMiddle   db "Middle", 0
    cbSingle   db "Single", 0
    cbDouble   db "Double", 0
    szPressAKey db "[Press a key...]", 0
    fmtStart   db "Start (%s)", 0
    fmtStop    db "Stop (%s)", 0
    iniFile    db ".\settings.ini", 0
    secMain    db "Settings", 0
    keyHH      db "Hours", 0
    keyMM      db "Mins", 0
    keySS      db "Secs", 0
    keyMS      db "MS", 0
    keyOffset  db "Offset", 0
    keyHK      db "Hotkey", 0
    
    downFlags  dd 0002h, 0008h, 0020h 
    upFlags    dd 0004h, 0010h, 0040h 

    isRunning  dd 0
    currentHotKeyCode dd 75h 
    waitingForKey     dd 0    
    hInstance  dd 0
    hMainWnd   dd 0
    hHotkeyDlg dd 0
    isPicking  dd 0
    hMouseHook dd 0
    hKbHook    dd 0
    hToolTip   dd 0
    baseInterval dd 0

.data?
    pt           POINT <>
    coordStr     db 64 dup(?)
    szKeyName    db 32 dup(?)
    szBtnBuffer  db 64 dup(?)
    tempBuf      db 32 dup(?)
    clicksLeft   dd ?
    targetX      dd ?
    targetY      dd ?
    clickType    dd ?
    mouseBtnIdx  dd ?

.code
start:
    invoke GetModuleHandleA, 0
    mov hInstance, eax
    invoke DialogBoxParamA, eax, 100, 0, offset DlgProc, 0
    invoke ExitProcess, 0

GetRandomInterval proc base:DWORD, offsetRange:DWORD
    .if offsetRange == 0
        mov eax, base
        ret
    .endif
    invoke GetTickCount
    xor edx, edx
    mov ecx, offsetRange
    add ecx, ecx        
    div ecx             
    sub edx, offsetRange 
    mov eax, base
    add eax, edx
    .if sdword ptr eax < 1
        mov eax, 1      
    .endif
    ret
GetRandomInterval endp

LoadSettings proc hWnd:DWORD
    invoke GetPrivateProfileIntA, addr secMain, addr keyHH, 0, addr iniFile
    invoke SetDlgItemInt, hWnd, 1001, eax, 0
    invoke GetPrivateProfileIntA, addr secMain, addr keyMM, 0, addr iniFile
    invoke SetDlgItemInt, hWnd, 1002, eax, 0
    invoke GetPrivateProfileIntA, addr secMain, addr keySS, 0, addr iniFile
    invoke SetDlgItemInt, hWnd, 1003, eax, 0
    invoke GetPrivateProfileIntA, addr secMain, addr keyMS, 100, addr iniFile
    invoke SetDlgItemInt, hWnd, 1004, eax, 0
    invoke GetPrivateProfileIntA, addr secMain, addr keyOffset, 40, addr iniFile
    invoke SetDlgItemInt, hWnd, 1007, eax, 0
    invoke GetPrivateProfileIntA, addr secMain, addr keyHK, 75h, addr iniFile
    mov currentHotKeyCode, eax
    ret
LoadSettings endp

SaveSettings proc hWnd:DWORD
    invoke GetDlgItemInt, hWnd, 1001, 0, 0
    invoke wsprintfA, addr tempBuf, addr fmtInt, eax
    invoke WritePrivateProfileStringA, addr secMain, addr keyHH, addr tempBuf, addr iniFile
    invoke GetDlgItemInt, hWnd, 1002, 0, 0
    invoke wsprintfA, addr tempBuf, addr fmtInt, eax
    invoke WritePrivateProfileStringA, addr secMain, addr keyMM, addr tempBuf, addr iniFile
    invoke GetDlgItemInt, hWnd, 1003, 0, 0
    invoke wsprintfA, addr tempBuf, addr fmtInt, eax
    invoke WritePrivateProfileStringA, addr secMain, addr keySS, addr tempBuf, addr iniFile
    invoke GetDlgItemInt, hWnd, 1004, 0, 0
    invoke wsprintfA, addr tempBuf, addr fmtInt, eax
    invoke WritePrivateProfileStringA, addr secMain, addr keyMS, addr tempBuf, addr iniFile
    invoke GetDlgItemInt, hWnd, 1007, 0, 0
    invoke wsprintfA, addr tempBuf, addr fmtInt, eax
    invoke WritePrivateProfileStringA, addr secMain, addr keyOffset, addr tempBuf, addr iniFile
    invoke wsprintfA, addr tempBuf, addr fmtInt, currentHotKeyCode
    invoke WritePrivateProfileStringA, addr secMain, addr keyHK, addr tempBuf, addr iniFile
    ret
SaveSettings endp

UpdateMainButtons proc hWnd:DWORD
    invoke MapVirtualKeyA, currentHotKeyCode, 0
    shl eax, 16
    invoke GetKeyNameTextA, eax, addr szKeyName, 32
    invoke wsprintfA, addr szBtnBuffer, addr fmtStart, addr szKeyName
    invoke SetDlgItemTextA, hWnd, 1018, addr szBtnBuffer
    invoke wsprintfA, addr szBtnBuffer, addr fmtStop, addr szKeyName
    invoke SetDlgItemTextA, hWnd, 1019, addr szBtnBuffer
    ret
UpdateMainButtons endp

AboutDlgProc proc hWnd:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD
    .if uMsg == 0111h 
        mov eax, wParam
        and eax, 0FFFFh
        .if eax == 1 || eax == 2
            invoke EndDialog, hWnd, 0
        .endif
    .elseif uMsg == 0010h 
        invoke EndDialog, hWnd, 0
    .endif
    xor eax, eax
    ret
AboutDlgProc endp

KbProc proc nCode:DWORD, wParam:DWORD, lParam:DWORD
    .if nCode == 0 && (wParam == 0100h || wParam == 0104h)
        .if waitingForKey == 1
            mov edx, lParam
            mov eax, [edx]
            mov currentHotKeyCode, eax
            invoke MapVirtualKeyA, currentHotKeyCode, 0
            shl eax, 16
            invoke GetKeyNameTextA, eax, addr szKeyName, 32
            invoke SetDlgItemTextA, hHotkeyDlg, 2002, addr szKeyName
            mov waitingForKey, 0
            invoke UnhookWindowsHookEx, hKbHook
            mov hKbHook, 0
            invoke GetDlgItem, hHotkeyDlg, 1
            invoke SetFocus, eax
            mov eax, 1
            ret
        .endif
    .endif
    invoke CallNextHookEx, hKbHook, nCode, wParam, lParam
    ret
KbProc endp

MouseProc proc nCode:DWORD, wParam:DWORD, lParam:DWORD
    .if nCode == 0 && wParam == 0201h && isPicking == 1
        mov edx, lParam
        mov eax, [edx]       ; pt.x
        mov ecx, [edx+4]     ; pt.y
        mov targetX, eax
        mov targetY, ecx
        invoke SetDlgItemInt, hMainWnd, 1016, targetX, 1
        invoke SetDlgItemInt, hMainWnd, 1017, targetY, 1
        invoke SendDlgItemMessageA, hMainWnd, 1013, 00F1h, 0, 0 
        invoke SendDlgItemMessageA, hMainWnd, 1014, 00F1h, 1, 0 
        mov isPicking, 0
        invoke KillTimer, hMainWnd, 2
        .if hToolTip != 0
            invoke DestroyWindow, hToolTip
            mov hToolTip, 0
        .endif
        invoke UnhookWindowsHookEx, hMouseHook
        mov hMouseHook, 0
        mov eax, 1
        ret
    .endif
    invoke CallNextHookEx, hMouseHook, nCode, wParam, lParam
    ret
MouseProc endp

HotkeyDlgProc proc hWnd:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD
    .if uMsg == 0110h
        mov eax, hWnd
        mov hHotkeyDlg, eax
        invoke MapVirtualKeyA, currentHotKeyCode, 0
        shl eax, 16 
        invoke GetKeyNameTextA, eax, addr szKeyName, 32
        invoke SetDlgItemTextA, hWnd, 2002, addr szKeyName
    .elseif uMsg == 0111h
        mov eax, wParam
        and eax, 0FFFFh 
        .if eax == 2001
            mov waitingForKey, 1
            invoke SetDlgItemTextA, hWnd, 2002, addr szPressAKey
            invoke SetWindowsHookExA, 13, offset KbProc, hInstance, 0
            mov hKbHook, eax
        .elseif eax == 1 || eax == 2
            .if hKbHook != 0
                invoke UnhookWindowsHookEx, hKbHook
                mov hKbHook, 0
            .endif
            invoke EndDialog, hWnd, eax
        .endif
    .endif
    xor eax, eax
    ret
HotkeyDlgProc endp

DlgProc proc hWnd:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD
    .if uMsg == 0110h ; WM_INITDIALOG
        mov eax, hWnd
        mov hMainWnd, eax
        
        ; --- LOAD AND SET PROGRAM ICON ---
        invoke LoadIconA, hInstance, 200 
        invoke SendMessageA, hWnd, WM_SETICON, ICON_BIG, eax
        invoke SendMessageA, hWnd, WM_SETICON, ICON_SMALL, eax
        
        invoke LoadSettings, hWnd
        invoke RegisterHotKey, hWnd, 1, 0, currentHotKeyCode
        invoke UpdateMainButtons, hWnd
        invoke SetDlgItemInt, hWnd, 1011, 1, 0
        invoke SendDlgItemMessageA, hWnd, 1012, 00F1h, 1, 0 
        invoke SendDlgItemMessageA, hWnd, 1013, 00F1h, 1, 0 
        invoke SendDlgItemMessageA, hWnd, 1008, 0143h, 0, offset cbLeft
        invoke SendDlgItemMessageA, hWnd, 1008, 0143h, 0, offset cbRight
        invoke SendDlgItemMessageA, hWnd, 1008, 0143h, 0, offset cbMiddle
        invoke SendDlgItemMessageA, hWnd, 1008, 014Eh, 0, 0
        invoke SendDlgItemMessageA, hWnd, 1009, 0143h, 0, offset cbSingle
        invoke SendDlgItemMessageA, hWnd, 1009, 0143h, 0, offset cbDouble
        invoke SendDlgItemMessageA, hWnd, 1009, 014Eh, 0, 0
    .elseif uMsg == 0111h
        mov eax, wParam
        and eax, 0FFFFh
        .if eax == 1005
            invoke MessageBoxA, hWnd, addr infoMsg, addr infoCap, 40h
        .elseif eax == 1015
            mov isPicking, 1
            invoke CreateWindowExA, 88h, addr szStatic, 0, 90800001h, 0, 0, 100, 20, 0, 0, hInstance, 0
            mov hToolTip, eax
            invoke SetTimer, hWnd, 2, 15, 0 
            invoke SetWindowsHookExA, 14, offset MouseProc, hInstance, 0
            mov hMouseHook, eax
        .elseif eax == 1020
            invoke DialogBoxParamA, hInstance, 200, hWnd, offset HotkeyDlgProc, 0
            .if eax == 1
                invoke UnregisterHotKey, hWnd, 1
                invoke RegisterHotKey, hWnd, 1, 0, currentHotKeyCode
                invoke UpdateMainButtons, hWnd
            .endif
        .elseif eax == 1021
            invoke DialogBoxParamA, hInstance, 300, hWnd, offset AboutDlgProc, 0 
        .elseif eax == 1018 
            invoke StartClicking, hWnd
        .elseif eax == 1019 
            invoke StopClicking, hWnd
        .endif
    .elseif uMsg == 0312h
        .if isRunning == 1
            invoke StopClicking, hWnd
        .else
            invoke StartClicking, hWnd
        .endif
    .elseif uMsg == 0113h
        .if wParam == 1
            invoke SendDlgItemMessageA, hWnd, 1012, 00F0h, 0, 0
            .if eax != 1 && clicksLeft == 0
                invoke StopClicking, hWnd
            .else
                invoke SendDlgItemMessageA, hWnd, 1014, 00F0h, 0, 0
                .if eax == 1
                    invoke SetCursorPos, targetX, targetY
                .endif
                invoke SendInput, 1, addr inputDown, 28
                invoke SendInput, 1, addr inputUp, 28
                .if clickType == 1
                    invoke SendInput, 1, addr inputDown, 28
                    invoke SendInput, 1, addr inputUp, 28
                .endif
                invoke SendDlgItemMessageA, hWnd, 1006, 00F0h, 0, 0
                .if eax == 1
                    invoke GetDlgItemInt, hWnd, 1007, 0, 0
                    invoke GetRandomInterval, baseInterval, eax
                    invoke SetTimer, hWnd, 1, eax, 0
                .endif
                invoke SendDlgItemMessageA, hWnd, 1012, 00F0h, 0, 0
                .if eax != 1
                    dec clicksLeft
                .endif
            .endif
        .elseif wParam == 2
            invoke GetCursorPos, addr pt
            mov eax, pt.x
            mov ecx, pt.y
            invoke wsprintfA, addr coordStr, addr fmtStr, eax, ecx
            invoke SetWindowTextA, hToolTip, addr coordStr
            mov eax, pt.x
            add eax, 15
            mov ecx, pt.y
            add ecx, 15
            invoke SetWindowPos, hToolTip, -1, eax, ecx, 160, 40, 10h 
            invoke GetAsyncKeyState, 1Bh ; VK_ESCAPE
            test ax, 8000h
            jz skip_esc
                mov isPicking, 0
                invoke KillTimer, hWnd, 2
                .if hToolTip != 0
                    invoke DestroyWindow, hToolTip
                    mov hToolTip, 0
                .endif
                invoke UnhookWindowsHookEx, hMouseHook
                mov hMouseHook, 0
            skip_esc:
        .endif
    .elseif uMsg == 0010h
        invoke SaveSettings, hWnd
        invoke UnregisterHotKey, hWnd, 1
        invoke EndDialog, hWnd, 0
    .endif
    xor eax, eax
    ret
DlgProc endp

StartClicking proc hWnd:DWORD
    LOCAL vhh:DWORD, vmm:DWORD, vss:DWORD, vms:DWORD
    .if isRunning == 0
        invoke SendDlgItemMessageA, hWnd, 1008, 0147h, 0, 0 
        mov mouseBtnIdx, eax
        invoke SendDlgItemMessageA, hWnd, 1009, 0147h, 0, 0 
        mov clickType, eax
        mov edx, mouseBtnIdx
        shl edx, 2 
        mov eax, [downFlags + edx]
        mov inputDown.mi.dwFlags, eax
        mov eax, [upFlags + edx]
        mov inputUp.mi.dwFlags, eax
        invoke GetDlgItemInt, hWnd, 1001, 0, 0
        mov vhh, eax
        invoke GetDlgItemInt, hWnd, 1002, 0, 0
        mov vmm, eax
        invoke GetDlgItemInt, hWnd, 1003, 0, 0
        mov vss, eax
        invoke GetDlgItemInt, hWnd, 1004, 0, 0
        mov vms, eax
        mov eax, vhh
        imul eax, 3600000
        mov baseInterval, eax
        mov eax, vmm
        imul eax, 60000
        add baseInterval, eax
        mov eax, vss
        imul eax, 1000
        add baseInterval, eax
        mov eax, vms
        add baseInterval, eax
        .if baseInterval == 0
            mov baseInterval, 1
        .endif
        invoke GetDlgItemInt, hWnd, 1011, 0, 0
        mov clicksLeft, eax
        invoke GetDlgItemInt, hWnd, 1016, 0, 0
        mov targetX, eax
        invoke GetDlgItemInt, hWnd, 1017, 0, 0
        mov targetY, eax
        invoke GetDlgItem, hWnd, 1018
        invoke EnableWindow, eax, 0
        invoke GetDlgItem, hWnd, 1019
        invoke EnableWindow, eax, 1
        mov isRunning, 1
        invoke SetTimer, hWnd, 1, baseInterval, 0
    .endif
    ret
StartClicking endp

StopClicking proc hWnd:DWORD
    .if isRunning == 1
        mov isRunning, 0
        invoke KillTimer, hWnd, 1
        invoke GetDlgItem, hWnd, 1018
        invoke EnableWindow, eax, 1
        invoke GetDlgItem, hWnd, 1019
        invoke EnableWindow, eax, 0
    .endif
    ret
StopClicking endp

end start