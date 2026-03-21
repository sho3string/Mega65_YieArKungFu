// RRB variables

.const RRB_PixiesPerRow			= 40
.const RRB_Tail_words				= (RRB_PixiesPerRow * 3) + 2 				// +final GOTOX +dummy tile
.const ROWMASK						= $08    									// color byte0 bit3
.const GOTOX 						= $10
.const TRANSPARENT 				= $80

// sprite queue variables
.const SPRITE_MAX					= 23	 									// Maximum # of sprites to queue
.const PIXIE_MAX					= 185
.const SPRITE_Q_ENTRY_SIZE		= 4											// 4 bytes per sprite. ( Y, X, TILE, ATTR )
.const SPRITE_Q_SIZE				= 1 + (SPRITE_MAX * SPRITE_Q_ENTRY_SIZE) // 23 x 4 = 92 bytes 
/*
On arcade.

5800-5fff   RW  video RAM
byte 0 - bit 4 - character code MSB
		 bit 6 - flip Y
		 bit 7 - flip X
byte 1 - character code LSB
*/

// - work ram 0x5000 - 0x57ff
.const SPRITE_RAM1	= $7000
.const WORK_RAM1		= $7030
.const CMD_QUEUE		= $72C0
.const SPRITE_RAM2	= $7400
.const WORK_RAM2		= $7430
.const SCREEN_BASE	= $2400	 /* background 8x8 screen ram - physcially on screen top left at 5880*/
.const SCREEN_WIDTH 	= 256	 /* arcade is 256 - 32 characters visible */
.const SCREEN_HEIGHT 	= 256	 /* arcade is 224 - 28 characters visible, however visble portion starts at 0x5880, non visible at 0x5800 to 0x587f */
.const CHARS_WIDE 	= (SCREEN_WIDTH / 8) 				// 32 characters.
.const CHARS_HIGH 	= (SCREEN_HEIGHT / 8)				// 32 characters, 28 visible.
.const TOTAL_CHARS  	= CHARS_WIDE + RRB_Tail_words   
.const LINESTEP_BYTES = TOTAL_CHARS * 2 
.const LOGICAL_WIDTH	= (CHARS_WIDE << 1) + (RRB_Tail_words << 1 ) // 64 for characters + 96 for pixies. 2 bytes for each character and pixie.

.const COLOR_RAM		= $FF80000
//.const LOADADDR		= $40000			// use spare ram to load stuff into.
.const GRAPHMEM  		= $20000 			// this will be our character generator at bank 2
.const TILE_OFFSET	= GRAPHMEM/64
//.const MEMBANK		= LOADADDR>>16		// 0x40000 >> 16 = 4
.const TAIL_OFF		= CHARS_WIDE*2
.const arcadeRowSize	= 6 // offset/0x40

.const EOL_X_LO		= <320          // $40
.const EOL_X_HI		= (>320) & 3    // $01

.const hw_nmi_vec 	= $fffa
.const hw_irq_vec 	= $fffe
.const vicii_irqmask 	= $d01a
.const ciaa_d 			= $dc0d
.const ciab_d 			= $dd0d
.const vicii_rcl 		= $d012
.const vicii_rch 		= $d011
.const vicii_irq		= $d019

// 6809 registers

.const Y_L				= $c0
.const Y_H				= $c1
.const B_Register		= $f2
.const U_L				= $f3
.const U_H				= $f4
.const X_L				= $f5
.const X_H				= $f6
.const FB_L				= $f7
.const FB_H				= $f8
.const A_Register		= $f9
.const Flags			= $fa
.const tmp				= $fb

