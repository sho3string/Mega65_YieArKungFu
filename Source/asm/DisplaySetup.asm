
* = * "Chargen init routine - DisplaySetup.asm"
setUpDisplay:
	/* set up a 256x224 / 30x28 chartacter screen */
	
	// on arcade start of visible screen is 5881
	
	// 320 X 200 High res screen Mode
	lda #$80
	trb $D031		// clear bit 7 = H320
	lda #$08
	trb $D031		// clear bit 3 - H200
	
	lda #TOTAL_CHARS
	sta $D05E		// 32 Characters per row
	lda #CHARS_HIGH
	sta $D07B		// 28 rows high

	// Text X starting position
	lda #143
	sta $D04C
	
	// Text Y starting position
	//lda #40
	lda #18
	sta $D04E
	
	// Left/Right Border
	lda #$90
	sta $D05C
	
	// Top Border
	//lda #$27
	lda #$32
	sta $D048
	// Bottom Border
	lda #$f1
	sta $D04A

	// char step
	//lda #<LINESTEP // Set linestep 
	lda #<CHARS_WIDE*2
	sta $D058
	//lda #>LINESTEP
	lda #>CHARS_WIDE*2
	sta $D059
	
	// 16 bit character mode, byte 0 - LSB, byte 1 first 5 bits MSB + attributes
	lda #$05			//Enable 16 bit char numbers (bit0) and 
	tsb $D054			//full color for chars>$ff (bit2)
	

	// Set screen address 
	lda #<SCREEN_BASE
	sta $D060
	lda #>SCREEN_BASE
	sta $D061
	lda #$0
	sta $D062
	sta $D063
	
	rts