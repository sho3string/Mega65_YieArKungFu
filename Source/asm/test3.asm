
.cpu _45gs02
#import "../Source/asm/mega65defs.asm"
#import "../Source/asm/m65macros.asm"
#import "../Source/asm/vic4fcm.asm"

/* ZP */
* = $02 "Basepage" virtual
	charCode:		.byte $00
	colPtr:			.byte $00
	scAddr:			.word $0000 /* low and high addr */
	ScreenVector:	.word $0000
	ZP_PTR1:		.byte $00
	ZP_PTR2:		.byte $00

/* Constants */

.const GOTOX 			= $10
.const TRANSPARENT 	= $80

//.const SCREEN_BASE	= $F000	 /* background screen ram */
.const SCREEN_FG		= $F800 /* foreground screen ram  */
.const SCREEN_WIDTH 	= 224
.const SCREEN_HEIGHT 	= 224
.const CHARS_WIDE 	= (SCREEN_WIDTH / 8)   
.const CHARS_HIGH 	= (SCREEN_HEIGHT /8)
.const LOGICAL_WIDTH	= ((SCREEN_WIDTH / 8) )<< 1
.const COLORRAM		= $FF81000

.const BASEPAGE  		= (>theend)+1 // right after our program
.const VICSTATE  		= $f0    // basepage storage for old vic state
.const SCREENMEM 		= (theend & $ff00) + $200
.const GRAPHMEM  		= $40000 // this will be our character ram at bank4


/*BasicUpstart65(Entry)
* = $2016 "Entry"	
//*=$900 "Entry"*/

Entry:
{

setup:
	Basic65Upstart() 
	// Bank I/O in via C64 mechanism
	sei
	lda #$35
	sta $01
	
	GoFaster()
	UnmapMemory()
	EnableVIC4()
	//enableVIC4Registers() // magic vic4 knock
	MoveBasePage(BASEPAGE)
	UARTClearKey()
	disableCIA()
	//Disable C65 rom protection using Hypervisor trap
	disableC65ROM()
	
start:
	
	VIC4_StoreState(VICSTATE)
	lda #$0
	sta VICIV_BORDERCOL	
	sta VICIV_SCREENCOL
	
	// 0 black for gfx ram filling, white for color ram filling.
	FCM_InitScreenMemory(0,SCREENMEM,GRAPHMEM,0,COLORRAM,1) 
	FCM_ScreenOn(SCREENMEM,COLORRAM)
	
	
	ldx #0 // text index
	ldy #0 // screen index
!txtloop:
	lda display_text1,x
	beq !endloop+
	sta SCREENMEM + 806,y
	iny
	lda #$0
	sta SCREENMEM + 806,y
	iny
	inx
	bra !txtloop-
!endloop:

	lda #$1E		// up arrow.
	sta SCREENMEM + 4*80
	lda #$0
	sta SCREENMEM + 4*80 + 1
	
	lda #$01
	sta SCREENMEM + 2
	lda #$10
	sta SCREENMEM + 3
	
	lda #<(GRAPHMEM & $ffff)
	sta $10
	lda #>(GRAPHMEM & $ffff)
	sta $11
	lda #<(GRAPHMEM>>16)
	sta $12
	lda #>(GRAPHMEM>>16)
	sta $13
	
	ldz #0
gfxloop:
	tza
	and #03
	clc
	adc #1
	sta (($10)),z
	UARTWaitKey()
	cmp #113
	beq endloop
	inz
	bne gfxloop
endloop:
	//
	// 04: bonus - DMA line drawing
	// DMA line drawing doesnt work in Xemu yet
	/*FCM_DrawLine(GRAPHMEM + 3*$640 + 3*$40, $2000, 1)
	FCM_DrawLine(GRAPHMEM + 3*$640 + 3*$40, $4000, 2)
	FCM_DrawLine(GRAPHMEM + 3*$640 + 3*$40, $6000, 3)
	FCM_DrawLine(GRAPHMEM + 3*$640 + 3*$40, $8000, 4)
	FCM_DrawLine(GRAPHMEM + 3*$640 + 3*$40, $A000, 5)
	FCM_DrawLine(GRAPHMEM + 3*$640 + 3*$40, $C000, 6)
	FCM_DrawLine(GRAPHMEM + 3*$640 + 3*$40, $E000, 7)
	FCM_DrawLine(GRAPHMEM + 3*$640 + 3*$40, $ffff, 8)*/
	
	
	

	
	UARTWaitKey()
exit:
	VIC4_RestoreState(VICSTATE)
	ResetBasePage()
	rts
	
	// Disable raster interrupts.
	lda #$00
	sta $D01A
	
	// Unmap C65 Roms $d030 clearing bits 3-7
	lda #$F8		// #%11111000
	trb $D030		// Clear bits 3-7
	
	cli				// Clear interrupts

	

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
	
	// Set screen address 
	/*lda #<SCREEN_BASE
	sta $D060
	lda #>SCREEN_BASE
	sta $D061
	lda #$0
	sta $D062
	sta $D063*/
	
	


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
	
	// Prints Jello
	//lda #$a
	//sta $1000
	//lda #$5
	//sta $1002
	//lda #$0C
	//sta $1004
	//sta $1006
	//lda #$0F
	//sta $1008
	jsr CopyColors

	
	;lda #$24	// %00100100 dataset motor control off, ram visible from $A000-$BFFF, $D000-$DFFF and $E000-$FFFF
	;sta $01		// processor port / bank switching
	jmp *
}
	
display_text1:
	.encoding "screencode_mixed"
	.text "press any key"
	.byte 0
	
*=* "CopyColors"
CopyColors: {
	RunDMAJob(Job)
	rts
Job:
	DMAHeader($00,COLORRAM>>20)
	DMACopyJob(COLORS,COLORRAM,LOGICAL_WIDTH*CHARS_HIGH,false,false)
}


*=* "Screen Offset Table"
ScreenOffsets:
	.for(var r=0; r<28; r++) {
	//	.word SCREEN_BASE + r*LOGICAL_WIDTH + 80
	}

/** = SCREEN_BASE	 "Character Ram"
SCREEN:
	//Build each row in a loop
	.for(var r=0; r<28 ; r++) {
		.fill 30, [i, 0] 
	}*/

* = *	"Color Ram"
COLORS:
	
	.for(var r=0; r<28; r++) {
		.fill 30 , [0, 0] //layer 1
	
	}
	

//.align 64
//GFX1_TILEMAP:
//	.import c64 "../Source/chr/bankp.chr"

theend: .byte 0