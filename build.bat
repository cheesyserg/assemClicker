@echo off
echo Compiling resources...
rc.exe gui.rc

echo Assembling...
ml.exe /c /coff clicker.asm

echo Linking...
:: Removed /MERGE:.rsrc=.text to fix LNK1272
:: Set /ALIGN:32 to keep the file as small as possible 
link /SUBSYSTEM:WINDOWS /ENTRY:start /ALIGN:32 /FILEALIGN:32 /MERGE:.rdata=.text /MERGE:.data=.text /SECTION:.text,EWR /FIXED /NODEFAULTLIB clicker.obj gui.res user32.lib kernel32.lib 

echo Done!
pause [cite: 2]