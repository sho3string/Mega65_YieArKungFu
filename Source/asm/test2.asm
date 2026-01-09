
; write our basic program.
;* = $2001
;.cpu "4510" 
;.word (+), 2000 ; line number
;.byte $fe 		 ; will be bank 0
;.byte $02		 ; will be bank 0
;.byte $30		 ; will be bank 0
;.byte $00		 ; basic line end
;.word (+), 2001 ; line number
;.null $9e, ^start
;+ .word 0		 ; basic line end

; ZP registers
charCode 		= $0D 
scAddrLo 		= $02
scAddrHi 		= $03
colPtr 			= $04


; Constants

GOTOX 			= 16
TRANSPARENT 	= 128

SCREEN_BASE		= $1000

SCREEN_WIDTH 	= 240
SCREEN_HEIGHT 	= 256
CHARS_WIDE 		= (SCREEN_WIDTH / 8)
CHARS_HIGH 		= (SCREEN_HEIGHT / 8)
LOGICAL_WIDTH	= (SCREEN_WIDTH / 8) << 1
COLOR_RAM		= $FF80000
true			= 1
false			= 0

; main
;* = $900
* = $900

!src "../Source/asm/m65macros.asm"

START
	; Bank I/O in via C64 mechanism
	SEI
	LDA #$35
	STA $01
	
	+enable40Mhz
	+enableVIC4Registers
	+disableCIA
	
	;Disable C65 rom protection using Hypervisor trap
	+disableC65ROM
	
	; Disable raster interrupts.
	LDA #$00
	STA $D01A
	
	; Unmap C65 Roms $d030 clearing bits 3-7
	LDA #$F8		; #%1111000
	TRB $D030		; Clear bits 3-7
	
	CLI				; Clear interrupts
	
	LDA #$1
	STA $D021		; background color	
	LDA #$2
	STA $D020		; border color
	


	; 320 X 200 High res screen Mode
	LDA #$80
	TRB $D031		; clear bit 7 = H320
	LDA #$08
	TRB $D031		; clear bit 3 - H200
	
	LDA #CHARS_WIDE
	STA $D05E		; Characters per row ( V )
	LDA CHARS_HIGH
	STA $D07B		; Number of rows to display

	; Text X starting position
	LDA #160
	STA $D04C
	
	; Text Y starting position
	LDA #40
	STA $D04E
	
	; Left/Right Border
	LDA #$A0
	STA $D05C
	
	; Top Border
	LDA #$28
	STA $D048
	; Bottom Border
	LDA #$02
	STA $D04B
	LDA #$28
	STA $D04A

	LDA #LOGICAL_WIDTH ; Set linestep to #30
	STA $D058
	LDA #0
	STA $D059
	
	; 16 bit character mode, byte 0 - LSB, byte 1 first 5 bits MSB + attributes
	LDA #$1
	TSB $D054
	
	//Change VIC2 stuff here to save having to disable hot registers
	;LDA #%00000111	// Reset XSCL (horizontal fine scroll)
	;TRB $d016
	
	; Set screen address to 0x01000
	LDA #<SCREEN_BASE
	STA $D060
	LDA #>SCREEN_BASE
	STA $D061
	LDA #$0
	STA $D062
	STA $D063
	
	; SCR RAM START
	LDA #<$1000
	STA scAddrLo
	LDA #>$1000
	STA scAddrHi
	

	; Clear display
	LDA #32				; char code to fill.
	LDX #CHARS_HIGH<<1	; # of rows
	;JSR	setRAM
	
	; SCR RAM START
	LDA #<$D800
	STA scAddrLo
	LDA #>$D800
	STA scAddrHi
	
	; Clear colour ram
	LDA #1				; char code to fill.
	LDX #CHARS_HIGH	; # of rows
	;JSR	setRAM

	;LDA #$80
	;STA $D800
	
	;LDA #15
	;STA $D801
	
	;LDA #7
	;STA $D803
	
	;LDA #$80			; Flip vertically
	;STA $D804
	
	;LDA #9
	;STA $D805
	
	; Prints Jello
	;LDA #$a
	;STA $1000
	;LDA #$5
	;STA $1002
	;LDA #$0C
	;STA $1004
	;STA $1006
	;LDA #$0F
	;STA $1008
	
	JSR CopyColors

	
	LDA #$24	; %00100100 dataset motor control off, ram visible from $A000-$BFFF, $D000-$DFFF and $E000-$FFFF
	STA $01		; processor port / bank switching
	
	JMP *
	
CopyColors 
	+RunDMAJob Job
	RTS
Job
	+DMAHeader $00,COLOR_RAM>>20
	+DMACopyJob COLORS,COLOR_RAM,LOGICAL_WIDTH*CHARS_HIGH,false,false



;* = $1000
;	!for r,33 {
;		!fill 30,1
;	}

; Func: clearScreen


setRAM
	STA charCode
L_B18B	
	LDY #$0
L_B18D
	STA (scAddrLo),Y 
	INY 
	CPY #CHARS_WIDE	; 80  columns
	BCC L_B18D
	DEX				; next row
	BEQ L_B1A7		; all rows done
	CLC 
	LDA scAddrLo
	ADC #CHARS_WIDE	; move to next row
	STA scAddrLo	
	BCC L_B1A2
	INC $03
L_B1A2
	LDA $0D 
	JMP L_B18B
L_B1A7
	CLC 
	LDA scAddrLo 
	ADC #CHARS_WIDE
	STA scAddrLo
	BCC L_B1B3
	INC scAddrHi
L_B1B3
	RTS
	
	
* = SCREEN_BASE	
SCREEN

	!for r,0,32-1 {
		!for s,0,30-1 {
			!byte s,$00
		}
		;!byte $8, 0 
		;!byte 15, 0
		
		;!byte 200, 0 
		;!byte 15, 0
		
		;!byte $f0,0
	
		;!byte 0,0
	}
	
COLORS
	; first 31 rows are not flipped by the Y axes
	!for r,0,32-1 {
		!for s,0,30-1 {
			!byte $00
			!byte $00	; blue
		}
		;!byte GOTOX | TRANSPARENT,$00
		;!byte $00,$07	; yellow
		
		;!byte GOTOX | TRANSPARENT,$00
		;!byte $00,$07	; yellow
		
		;!byte GOTOX,$00
		;!byte $00,$00
	}
	; flip the last row of glyphs
	;!for r,0,30 {
	;	!byte $80	; flip Y
	;	!byte $6	; blue
	;}
	
	
	

	;!for r,0,30 {
	;	!for s,0,32 {
	;		!byte $00
	;		!byte $1
	;	}
	;}
