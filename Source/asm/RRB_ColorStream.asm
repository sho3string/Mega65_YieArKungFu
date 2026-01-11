#import "Source/asm/Constants.asm"

.file [name="colorram.bin", type="bin", segments="ColourRAM"]
.segment ColourRAM[]
	
*=COLOR_RAM "RRB Colour Stream - yiearkungfu.asm"

COLORS:
	.for(var r=0; r<CHARS_HIGH; r++) { // for each row
		
		// byte 0 = flipx/flipy, byte 1 ???
		.fill CHARS_WIDE, [0,0] // layer 1

		.for (var p=0; p<RRB_PixiesPerRow; p++) {
			//Set bit 4 of color ram byte 0 to enable gotox flag
			//set bit 7 additionally to enable transparency
			
			// pixie #: raster, tile, GOTOX
			.byte [GOTOX | TRANSPARENT], $00
			.byte 0, 0
			.byte [GOTOX], $00

		}
		.byte 0,0 // terminator
	}