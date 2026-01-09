
/* this will also work

    lda #254
l1  cmp $d012
    bne l1
l2  cmp $d012
    beq l2
*/

waitvb:
	bit $d011	/* wait for raster beam in range 0-255 */
    bpl waitvb
waitvb2: 
	bit $d011	/* waits for line 255 */
    bmi waitvb2
	rts
	