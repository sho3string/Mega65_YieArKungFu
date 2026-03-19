#import "Source/asm/Constants.asm"

.file [name="colorram.bin", type="bin", segments="ColourRAM"]
.segment ColourRAM[]
	
*=COLOR_RAM "RRB Colour Stream - yiearkungfu.asm"

COLORS:
	.for(var r=0; r<CHARS_HIGH; r++) { // for each row
		
		// byte 0 = FlipX/FlipY ( bitx 6 or 7 ) for characters
		.fill CHARS_WIDE, [0,0] // layer 1

		.for (var p=0; p<RRB_PixiesPerRow; p++) {
			/********************************************************************
			Byte 0:	
				Set bit 4 of color ram byte 0 to enable gotox flag
				Set bit 7 additionally to enable transparency
				Set bit 3 for rowmask enable ?
			Byte 1: rowmask bits [ 0 - 7 ]
			pixie #: raster, tile, GOTOX
			
			The code below creates this structure from 0xD840 which
			represents the tail row.
			
			D840: 98 FF 00 00 10 00   98 FF 00 00 10 00   98 FF 00 00 10 00 ...
				  ^  ^                 ^  ^
				  |  |                 |  |
				  |  mask              |  mask
				  flags
				  
			This coincides with bytes stored 0x2840 in character ram
			
			00002800: ... (blank chars)
			00002840: 38 00 80 11 FF 00 40 00 81 11 FF 00 F5 00 45 0E 00 01 F5 00 45 0E 00 01 00 00
			byte 0: X Raster position low
			byte 1: X Raster position high
			byte 2: Low byte: tile #, High byte: page # ( each page consists of 256 character steps )
			byte 3: GotoX marker Low
			byte 4: GotoX marker High
			
			This data is templated from at the time of writing. See RRB_ColorStream.asm
			
			RRB_PixieProtoType: // set this to a blank tile and move off screen, say 0xff. for now we want to see them all as we troubleshoot
				.byte 245, 0	
				.byte 69, $06  
				.byte 64, 1

			*********************************************************************/
			

			//    0x10		0x80		   0x08	  0xff
			.byte [GOTOX | TRANSPARENT | ROWMASK], %11111111 // default all bits on.
			.byte $00, 00	// byte 0 - FlipX/FlipY for Pixies.
			.byte [GOTOX], $00

		}
		// final GOTOX color-word (matches screen final GOTOX word)
		.byte [GOTOX | TRANSPARENT], $00     // control for gotoX (no mask needed)
		// dummy tile color-word (matches screen dummy tile word)
		.byte $00, $00                       // flipbits/attr for dummy tile
	}
