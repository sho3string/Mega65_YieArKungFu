cls
pushd G:\Mega65\YieArKungFu
rem 64tass.exe -a --m4510 ../Source/asm/test.asm -I ..\lib\ -o ../test.prg
rem java -jar Kickass.jar ../Source/asm/test.asm
rem acme.exe --cpu m65 -o ../test.prg -f cbm ../Source/asm/test.asm
java -jar G:\Mega65\YiearKungFu\Bin\kickassembler-5.24-65ce02.e.jar -showmem G:/Mega65/YiearKungFu/Source/asm/Yiearkungfu.asm -symbolfile -bytedumpfile YieArKungFu.klist
rem exomizer.exe sfx $900 ../tesmoret.prg -o ../testp.prg -t 65
cmd /c copy "G:\Mega65\YiearKungFu\Source\asm\Yiearkungfu.prg" "G:\Mega65\YiearKungFu\Yiearkungfu.prg"

rem cmd /c G:\Mega65\YiearKungFu\bin\exomizer.exe sfx 0x22b8 -x "LDA #$0B STA $D011 LDA $D020 EOR #$05 STA $D020 STA $D418" -t 65 -Di_ram_exit=0 -o Yiearkungfu.prg Yiearkf.prg 

rem cmd /c copy "G:\Mega65\Exciting Hour\Source\asm\testp.prg" "G:\Mega65\Exciting Hour\testp.prg"
cmd /c del "G:\Mega65\YiearKungFu\Yiearkf.d81"
cmd /c G:\Mega65\Dev\bin\cc1541.exe -n "yie ar kung fu" -w "G:\Mega65\YiearKungFu\yiearkungfu.prg" -w "G:\Mega65\YiearKungFu\YiearKungFu\assets\tilesheet.chr" "G:\Mega65\YiearKungFu\Yiearkf.d81"
cmd /c G:\Mega65\m65tools\mega65_ftp -e -c "put Yiearkf.D81"
popd
rem -x "LDA #$0B STA $D011 LDA $D020 EOR #$05 STA $D020 STA $D418"
