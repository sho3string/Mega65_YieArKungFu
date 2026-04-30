cls
pushd G:\Mega65\YieArKungFu
java -jar G:\Mega65\YiearKungFu\Bin\kickassembler-5.24-65ce02.e.jar -showmem G:/Mega65/YiearKungFu/Source/asm/Yiearkungfu.asm -symbolfile -bytedumpfile YieArKungFu.klist
cmd /c copy "G:\Mega65\YiearKungFu\Source\asm\Yiearkungfu.prg" "G:\Mega65\YiearKungFu\Yiearkungfu.prg"


java -jar G:\Mega65\YiearKungFu\Bin\kickassembler-5.24-65ce02.e.jar -showmem Source/asm/RRB_ColorStream.asm
cmd /c copy "G:\Mega65\YiearKungFu\Source\asm\colorram.bin" "G:\Mega65\YiearKungFu\colorram.bin"

java -jar G:\Mega65\YiearKungFu\Bin\kickassembler-5.24-65ce02.e.jar -showmem Source/asm/Playfield.asm
cmd /c copy "G:\Mega65\YiearKungFu\Source\asm\plyfld.bin" "G:\Mega65\YiearKungFu\plyfld.bin"

rem cmd /c G:\Mega65\YiearKungFu\bin\exomizer.exe sfx 0x22b8 -x "LDA #$0B STA $D011 LDA $D020 EOR #$05 STA $D020 STA $D418" -t 65 -Di_ram_exit=0 -o Yiearkungfu.prg Yiearkf.prg 

cmd /c del "G:\Mega65\YiearKungFu\Yiearkf.d81"

echo Convert sprites.bin
python G:\Mega65\YieArKungFu\YieArKungFu\Tools\patch_diagonals.py G:\Mega65\YieArKungFu\YieArKungFu\assets\TILESHEET.chr G:\Mega65\YieArKungFu\YieArKungFu\assets\TS.chr --tiles-per-row 16 --start-row 32 --sprite-cols 8 --sprite-rows 64


cmd /c G:\Mega65\Dev\bin\cc1541.exe -n "yie ar kung fu" -w "G:\Mega65\YiearKungFu\yiearkungfu.prg" -w "G:\Mega65\YiearKungFu\YiearKungFu\assets\ts.chr" -w "G:\Mega65\YiearKungFu\colorram.bin" -w "G:\Mega65\YiearKungFu\plyfld.bin" "G:\Mega65\YiearKungFu\Yiearkf.d81"
cmd /c G:\Mega65\m65tools\mega65_ftp -e -c "put Yiearkf.D81"
popd
rem -x "LDA #$0B STA $D011 LDA $D020 EOR #$05 STA $D020 STA $D418"
