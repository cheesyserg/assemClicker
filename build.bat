@echo off

echo Compiling resources... 
rc.exe gui.rc 

echo Assembling... 
ml.exe /c /coff clicker.asm 

echo Linking with size optimizations... 
link /SUBSYSTEM:WINDOWS /ENTRY:start ^
     /ALIGN:512 /FILEALIGN:512 ^
     /MERGE:.rdata=.text /MERGE:.data=.text ^
     /SECTION:.text,EWR ^
     /NODEFAULTLIB /FIXED /MANIFEST:NO ^
     /OPT:REF /OPT:ICF ^
     /IGNORE:4108 ^
     clicker.obj gui.res user32.lib kernel32.lib Winmm.lib 

echo Build Successful! 
