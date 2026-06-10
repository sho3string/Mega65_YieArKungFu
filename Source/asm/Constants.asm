// RRB variables

.const RRB_PixiesPerRow		= 20
.const RRB_Tail_words		= (RRB_PixiesPerRow * 3) + 2 				// +final GOTOX +dummy tile
.const GOTOX 				= $10
.const TRANSPARENT 			= $80

// sprite queue variables
.const SPRITE_MAX			= 24	 									// Maximum # of sprites to queue
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
.const SPRITE_RAM1		= $C000
.const WORK_RAM1		= $C030
.const CMD_QUEUE		= $C2C0
.const SPRITE_RAM2		= $C400
.const WORK_RAM2		= $C430
.const SCREEN_BASE		= $2400	 /* background 8x8 screen ram - physcially on screen top left at 5880*/
.const ARCADE_VRAM_BASE	= $5800  /* Arcade character ram */
.const SCREEN_WIDTH 	= 256	 /* arcade is 256 - 32 characters visible */
.const SCREEN_HEIGHT 	= 256	 /* arcade is 224 - 28 characters visible, however visble portion starts at 0x5880, non visible at 0x5800 to 0x587f */
.const CHARS_WIDE 		= (SCREEN_WIDTH / 8) 				// 32 characters.
.const CHARS_HIGH 		= (SCREEN_HEIGHT / 8)				// 32 characters, 28 visible.
.const TOTAL_CHARS  	= CHARS_WIDE + RRB_Tail_words   
.const LINESTEP_BYTES 	= TOTAL_CHARS * 2 
.const LOGICAL_WIDTH	= (CHARS_WIDE * 2) + (RRB_Tail_words * 2) // 64 for characters + 96 for pixies. 2 bytes for each character and pixie.
.const ROW_STRIDE		= $40 + (RRB_Tail_words * 2)
.const COLOR_RAM		= $FF80000 
//.const LOADADDR		= $40000			// use spare ram to load stuff into.
.const GRAPHMEM  		= $10000 			// this will be our character generator at bank 2
.const PLAYFIELD		= GRAPHMEM + $30000	// Playfield data at bank1
.const HISCORE			= PLAYFIELD + $5c1 	// 0x205c0
.const TILE_OFFSET		= GRAPHMEM/64
//.const MEMBANK		= LOADADDR>>16		// 0x40000 >> 16 = 4
.const TAIL_OFF			= CHARS_WIDE*2
.const arcadeRowSize	= 6 // offset/0x40
.const hw_nmi_vec 		= $fffa
.const hw_irq_vec 		= $fffe
.const vicii_irqmask 	= $d01a
.const ciaa_d 			= $dc0d
.const ciaa_timer_a		= $dd0e
.const ciab_d 			= $dd0d
.const vicii_rcl 		= $d012
.const vicii_rch 		= $d011
.const vicii_irq		= $d019


// 6809 registers
.const Y_L				= $aa
.const Y_H				= $ab
.const U_L				= $ba
.const U_H				= $bb
.const B_Register		= $f2
.const zp_cmd_param		= $f4
.const X_L				= $f5
.const X_H				= $f6
.const A_Register		= $f9
.const Flags			= $fa
.const tmp				= $fb
.const tmp2				= $fc
.const tmp3				= $fd
.const Y_Register		= $fe

// Low-RAM staging buffer for one high-score entry

.const HSRC0  				= $50
.const HSRC1 				= $51
.const HSRC2 				= $52
.const HSRC3 				= $53

.const hiscore_row_buf = WORK_RAM2+$120   /* 5550 */

// labels

.label WATERFALL_TILE = (SCREEN_BASE+(RRB_Tail_words*2*($311>>arcadeRowSize))+$311-1)
