/**********************************************************
*Each pixie produces 3 tilemap entries plus a terminator  *
*1. .byte raster_low, raster_high                         *
*2. .byte tile_low, tile_high                             *
*3. .byte gotox_low, gotox_high                           *
*   .byte 0,0                                             *
**********************************************************/

.const RRB_PixiesPerRow	= 31
.const RRB_Tail			= (RRB_PixiesPerRow * 3) + 1
.const GOTOX 				= $10
.const TRANSPARENT 		= $80

/*
On arcade.

5800-5fff   RW  video RAM
byte 0 - bit 4 - character code MSB
		 bit 6 - flip Y
		 bit 7 - flip X
byte 1 - character code LSB
*/


.const SPRITE_RAM1	= $5000
.const WORK_RAM1		= $5030
.const SPRITE_RAM2	= $5400
.const WORK_RAM2		= $5430
.const SCREEN_BASE	= $2800	 /* background 8x8 screen ram - physcially on screen top left at 5880*/
.const SCREEN_WIDTH 	= 256	 /* arcade is 256 - 32 characters visible */
.const SCREEN_HEIGHT 	= 256	 /* arcade is 224 - 28 characters visible, however visble portion starts at 0x5880, non visible at 0x5800 to 0x587f */
.const CHARS_WIDE 	= (SCREEN_WIDTH / 8) 		// 32 characters.
.const CHARS_HIGH 	= (SCREEN_HEIGHT / 8)		// 32 characters, 28 visible.
.const TOTAL_CHARS  	= CHARS_WIDE + RRB_Tail   // 32 + 48 = 80 characters
.const LINESTEP_BYTES = TOTAL_CHARS * 2         // 160 bytes
.const LOGICAL_WIDTH	= (CHARS_WIDE << 1) + (RRB_Tail << 1 ) // 64 for characters + 96 for pixies. 2 bytes for each character and pixie.



.const COLOR_RAM		= $FF80000
//.const LOADADDR		= $40000			// use spare ram to load stuff into.
.const GRAPHMEM  		= $20000 			// this will be our character generator at bank 2
.const TILE_OFFSET	= GRAPHMEM/64
//.const MEMBANK		= LOADADDR>>16		// 0x40000 >> 16 = 4

.const hw_nmi_vec 	= $fffa
.const hw_irq_vec 	= $fffe
.const vicii_irqmask 	= $d01a
.const ciaa_d 			= $dc0d
.const ciab_d 			= $dd0d
.const vicii_rcl 		= $d012
.const vicii_rch 		= $d011  ; bit 7
.const vicii_irq		= $d019