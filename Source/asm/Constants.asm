// RRB variables

.const RRB_PixiesPerRow		= 20
.const RRB_Tail_words		= (RRB_PixiesPerRow * 3) + 2 				// +final GOTOX +dummy tile
.const GOTOX 				= $10
.const TRANSPARENT 			= $80

// sprite queue variables
.const SPRITE_MAX			= 23	 									// Maximum # of sprites to queue
.const PIXIE_MAX			= 180

/*
On arcade.

5800-5fff   RW  video RAM
byte 0 - bit 4 - character code MSB
		 bit 6 - flip Y
		 bit 7 - flip X
byte 1 - character code LSB
*/

// - work ram 0x5000 - 0x57ff
.const SPRITE_RAM1		= $9000
.const WORK_RAM1			= $9030
.const CMD_QUEUE			= $92C0
.const SPRITE_RAM2		= $9400
.const WORK_RAM2			= $9430
.const SCREEN_BASE		= $2400	 /* background 8x8 screen ram - physcially on screen top left at 5880*/
.const ARCADE_VRAM_BASE	= $5800  /* Arcade character ram */
.const SCREEN_WIDTH 		= 256	 /* arcade is 256 - 32 characters visible */
.const SCREEN_HEIGHT 		= 256	 /* arcade is 224 - 28 characters visible, however visble portion starts at 0x5880, non visible at 0x5800 to 0x587f */
.const CHARS_WIDE 		= (SCREEN_WIDTH / 8) 				// 32 characters.
.const CHARS_HIGH 		= (SCREEN_HEIGHT / 8)				// 32 characters, 28 visible.
.const TOTAL_CHARS  		= CHARS_WIDE + RRB_Tail_words   
.const LINESTEP_BYTES 	= TOTAL_CHARS * 2 
.const LOGICAL_WIDTH		= (CHARS_WIDE * 2) + (RRB_Tail_words * 2) // 64 for characters + 96 for pixies. 2 bytes for each character and pixie.
.const ROW_STRIDE			= $40 + (RRB_Tail_words * 2)
.const COLOR_RAM			= $FF80000 
//.const LOADADDR			= $40000			// use spare ram to load stuff into.
.const GRAPHMEM  			= $30000 			// this will be our character generator at bank 2
.const TILE_OFFSET		= GRAPHMEM/64
//.const MEMBANK			= LOADADDR>>16		// 0x40000 >> 16 = 4
.const TAIL_OFF			= CHARS_WIDE*2
.const arcadeRowSize		= 6 // offset/0x40
.const hw_nmi_vec 		= $fffa
.const hw_irq_vec 		= $fffe
.const vicii_irqmask 		= $d01a
.const ciaa_d 				= $dc0d
.const ciab_d 				= $dd0d
.const vicii_rcl 			= $d012
.const vicii_rch 			= $d011
.const vicii_irq			= $d019

// 6809 registers
.const Y_L					= $aa
.const Y_H					= $ab
.const B_Register			= $f2
.const U_L					= $f3
.const U_H					= $f4
.const X_L					= $f5
.const X_H					= $f6
.const FB_L				= $f7
.const FB_H				= $f8
.const A_Register			= $f9
.const Flags				= $fa
.const tmp					= $fb
.const tmp2				= $fc


// labels

.label WATERFALL_TILE = (SCREEN_BASE+(RRB_Tail_words*2*($311>>arcadeRowSize))+$311-1)
