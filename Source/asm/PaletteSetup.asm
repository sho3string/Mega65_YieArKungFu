
* = * "Palette init routine - PaletteSetup.asm"
setUpPalette:	
	lda #$0			// bank in palette 0, we only need 1 for Yie Ar Kung Fu
	sta $d070
	
	ldx #customPaletteTbl_1_End-customPaletteTbl_1_Start // size of our palette.
paletteLoop:
	lda red,x     	// load & store red component
	sta $d100,x
	lda green,x    // load & store green component
	sta $d200,x
	lda blue,x     // load & store blue component
	sta $d300,x
	dex
	bpl paletteLoop
	rts
	