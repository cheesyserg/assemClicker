@echo off

echo Compiling resources... 
rc.exe gui.rc 

echo Assembling... 
ml.exe /c /coff clicker.asm 

echo Linking with size optimizations... 
link /SUBSYSTEM:WINDOWS /ENTRY:start /ALIGN:4096 /FILEALIGN:512 /MERGE:.rdata=.text /MERGE:.data=.text /SECTION:.text,EWR /NODEFAULTLIB /FIXED /MANIFEST:NO /OPT:REF /OPT:ICF clicker.obj gui.res user32.lib kernel32.lib 

echo Compressing with UPX...  
upx.exe --ultra-brute --lzma clicker.exe 

echo Build Successful! 
pause
