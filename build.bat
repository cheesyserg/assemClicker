@echo off
rc.exe gui.rc
ml.exe /c /coff clicker.asm

:: 4096 is the "Magic Number" for Modern Windows
link /SUBSYSTEM:WINDOWS /ENTRY:start /ALIGN:4096 /FILEALIGN:512 /MERGE:.rdata=.text /MERGE:.data=.text /SECTION:.text,EWR /NODEFAULTLIB clicker.obj gui.res user32.lib kernel32.lib 
upx.exe --ultra-brute clicker.exe

echo Build Successful!
pause
