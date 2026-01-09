
*=* "Character loader routine"
loadChargen1:
	/* Load routine requires high word for 32 bit addresses */
	lda #$00 
	sta $b0
	sta $ad
	sta $ae
	lda #LOADADDR>>16			// address to load asset into
	sta $af
	
	lda #FNAMETS_END-FNAMETS	// get file name length
	ldx	#<FNAMETS
	ldy #>FNAMETS
	jsr $ffbd					// calls setname.
	
	/* setbnk */
	lda #MEMBANK				// bank for loading
	ldx #$00					// bank for filename
	jsr $ff6b
	
	/* setlfd */
	lda #$00
	ldx #$08					// device 8
	ldy #$00
	jsr $ffba

	lda #$40					// set mode to raw
	ldx #$00
	ldy #$00
	jsr $ffd5
	bcs doerror
	jmp goexit
	
doerror:	
	ldy #ERRLOAD_END-ERRLOAD-1
loo:
	lda ERRLOAD,y
	sta $c10,y			// print the error to screen
	dey
	bpl loo
derror:
	inc $d020			// and flash the border forever.
	jmp derror
goexit: 
	rts
	
/* Prints Error if there's a problem loading & flashes border */
	/*lda #5
	sta $c10
	lda #18
	sta $c11
	sta $c12
	lda #15
	sta $c13
	lda #18
	sta $c14*/
