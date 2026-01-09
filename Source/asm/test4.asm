
.cpu _45gs02
#import "../Source/asm/mega65defs.asm"
#import "../Source/asm/m65macros.asm"


/* ZP */
* = $02 "Basepage" virtual
	charCode:		.byte 	$00
	colPtr:			.byte 	$00
	scAddr:			.word 	$0000 /* low and high addr */
	ScreenVector:	.word 	$0000
	ZP_PTR_TARGET:	.dword	$00000000
	ZP_PTR1:		.word 	$0000
	ZP_PTR2:		.word 	$0000

/* Constants */

.const GOTOX 			= $10
.const TRANSPARENT 	= $80

.const SCREEN_BASE		= $4000	 /* background screen ram */
.const SCREEN_FG		= $F800 /* foreground screen ram  */
.const SCREEN_WIDTH 	= 224
.const SCREEN_HEIGHT 	= 224
.const CHARS_WIDE 		= (SCREEN_WIDTH / 8)   
.const CHARS_HIGH 		= (SCREEN_HEIGHT /8)
.const LOGICAL_WIDTH	= (SCREEN_WIDTH / 8) << 1
.const COLOR_RAM		= $FF80000
.const GRAPHMEM  		= $6000 // this will be our character generator at bank4


BasicUpstart65(Entry)
*= $2016 "Entry"	
//*=$900 "Entry"

Entry:
{
	

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


	
enable40Mhz()
	enableVIC4Registers()
	disableCIA()
	
	//Disable C65 rom protection using Hypervisor trap
	disableC65ROM()
	
	// Disable raster interrupts.
	lda #$00
	sta $D01A
	
	// Unmap C65 Roms $d030 clearing bits 3-7
	lda #$F8		// #%11111000
	trb $D030		// Clear bits 3-7
	
	cli				// Clear interrupts 
	lda #$1
	sta $D021		// background color	
	lda #$0
	sta $D020		// border color
	
	// 320 X 200 High res screen Mode
	lda #$80
	trb $D031		// clear bit 7 = H320
	lda #$08
	trb $D031		// clear bit 3 - H200
	
	lda #CHARS_WIDE
	sta $D05E		// Characters per row ( V )
	lda #CHARS_HIGH
	sta $D07B		// Number of rows to display

	// Text X starting position
	lda #176
	sta $D04C
	
	// Text Y starting position
	lda #52
	sta $D04E
	
	// Left/Right Border
	lda #$B0
	sta $D05C
	
	// Top Border
	lda #$34
	sta $D048
	// Bottom Border
	lda #$01
	sta $D04B
	lda #$F2
	sta $D04A

	lda #LOGICAL_WIDTH // Set linestep to #28
	sta $D058
	lda #0
	sta $D059
	
	// 16 bit character mode, byte 0 - LSB, byte 1 first 5 bits MSB + attributes
	lda #$05			//Enable 16 bit char numbers (bit0) and 
	tsb $D054			//full color for chars>$ff (bit2)
	
	
	//Change VIC2 stuff here to save having to disable hot registers
	//lda #%00000111	// Reset XSCL (horizontal fine scroll)
	//trb $d016
	
	/*lda #$0				// bank in palette 0
	sta $d070
	
	ldx #$04
l:	lda c64_colours_table+00,x     // load & store red component
	sta $D100,x
	lda c64_colours_table+5,x     // load & store green component
	sta $D200,x
	lda c64_colours_table+10,x     // load & store blue component
	sta $D300,x
	dex
	bpl l*/
	
	
	// Set screen address 
	lda #<SCREEN_BASE
	sta $D060
	lda #>SCREEN_BASE
	sta $D061
	lda #$0
	sta $D062
	sta $D063

	// Set character set
	//lda #$80
	//sta $D800
	
	//lda #15
	//sta $D801
	
	//lda #7
	//sta $D803
	
	//lda #$80			// Flip vertically
	//sta $D804
	
	//lda #9
	//sta $D805

	lda #<SCREENDATA
	sta ZP_PTR1
	lda #>SCREENDATA
	sta ZP_PTR1 + 1
	
	// set screen base pointer
	lda #<SCREEN_BASE
	sta ZP_PTR2
	lda #>SCREEN_BASE
	sta ZP_PTR2 + 1
		  
	//setup target pointer in zeropage
	ldx #<COLOR_RAM
	stx ZP_PTR_TARGET + 0
	ldx #>COLOR_RAM
	stx ZP_PTR_TARGET + 1
	ldx #( COLOR_RAM >> 16 ) & $ff
	stx ZP_PTR_TARGET + 2
	ldx #( COLOR_RAM >> 24 )
	stx ZP_PTR_TARGET + 3
	
	ldx #28  // 28 rows
NextLine:	
	ldz #0
	ldy #0
loop:
	//we need to add offset to the character data
	lda #0
	sta ((ZP_PTR_TARGET)),z
	
	//lo byte
	lda (ZP_PTR1),y  		  // tile data
	clc
	adc #<(GRAPHMEM / 64 )   // address of tile / 64 = 16 bit tile #
	sta (ZP_PTR2),y  		  // video ram memory
	iny
	inz	
	
	//we need to add offset to the character data
	lda #0
	sta ((ZP_PTR_TARGET)),z
	
	//hi byte
	lda (ZP_PTR1),y  		   // attribute
	clc
	adc #>(GRAPHMEM / 64 )    // address of tile / 64 = 16 bit tile #
	sta (ZP_PTR2),y  		   // video ram memory
	iny
	inz
	cpy #56
	bne loop
	
    //(we only change the lower 16bit)
	lda ZP_PTR_TARGET
	clc
	adc #56
	sta ZP_PTR_TARGET
	bcc pl
	inc ZP_PTR_TARGET + 1
pl:

	lda ZP_PTR1
	clc
	adc #56
	sta ZP_PTR1
	bcc pl2
	inc ZP_PTR1 + 1
pl2:

	lda ZP_PTR2
	clc
	adc #56
	sta ZP_PTR2
	bcc pl3
	inc ZP_PTR2 + 1
pl3:
	dex
	bne NextLine
	
	
	// Prints Jello using normal character set
	/*lda #$a
	sta SCREEN_BASE+56
	lda #$5
	sta SCREEN_BASE+58
	lda #$0C
	sta SCREEN_BASE+60
	sta SCREEN_BASE+62
	lda #$0F
	sta SCREEN_BASE+64
	lda #$14
	sta SCREEN_BASE+66*/
	
	
	//jsr CopyColors

	
	;lda #$24	// %00100100 dataset motor control off, ram visible from $A000-$BFFF, $D000-$DFFF and $E000-$FFFF
	;sta $01		// processor port / bank switching
	jmp *
}
	
	
*=* "CopyColors"
CopyColors: {
	RunDMAJob(Job)
	rts
Job:
	DMAHeader($00,COLOR_RAM>>20)
	DMACopyJob(COLORS,COLOR_RAM,LOGICAL_WIDTH*CHARS_HIGH,false,false)
}

*=* "Screen Offset Table"
ScreenOffsets:
	.for(var r=0; r<28; r++) {
		.word SCREEN_BASE + r*LOGICAL_WIDTH + 80
	}

/*
* = SCREEN_BASE	 "Character Ram"
SCREEN:
	//Build each row in a loop
	.for(var r=0; r<28 ; r++) {
		.fill 30, [i, 0] 
	}
*/


* = * "Palette"
c64_colours_table:


.byte 0,151,151,71,255 // red
.byte 0,104,71,33,104  // green
.byte 0,0,0,0,0			// blue


* = *	"Color Ram"
COLORS:
	.for(var r=0; r<28; r++) {
	//	.fill 28 , [0, r] //layer 1
	
	}
* = * "Character Data"
SCREENDATA:
	.import binary "../bankp/chardata.bin"

* = * "Character Generator filename"

FNAMETS:
	.text "BANKP.CHR"
FNAMETS_END:


ERRLOAD:
	.text "error loading character set"
ERRLOAD_END:

*=$6000

	.import binary "../bankp/bankp.chr"