
.cpu _45gs02


#import "Source/asm/mega65defs.asm"
#import "Source/asm/m65macros.asm"

/* ZP */
* = $200 "Basepage - yiearkungfu.asm" virtual
	byte_0:		.byte	$00
	byte_1:		.byte	$00
	byte_2:		.byte	$00
	byte_3:		.byte	$00
	byte_4:		.byte	$00
	byte_5:		.byte	$00
	byte_6:		.byte	$00
	byte_7:		.byte	$00
	byte_8:		.byte	$00
	byte_9:		.byte	$00
	byte_a:		.byte	$00
	byte_b:		.byte	$00
	byte_c:		.byte	$00
	byte_d:		.byte	$00
	byte_e:		.byte	$00
	byte_f:		.byte	$00
	byte_10:	.byte	$00
	byte_11:	.byte	$00
	byte_12:	.byte	$00
	byte_13:	.byte	$00
	byte_14:	.byte	$00
	byte_15:	.byte	$00
	byte_16:	.byte	$00
	byte_17:	.byte	$00
	byte_18:	.byte	$00
	byte_19:	.byte	$00
	byte_1a:	.byte	$00
	byte_1b:	.byte	$00
	byte_1c:	.byte	$00
	byte_1d:	.byte	$00
	byte_1e:	.byte	$00
	byte_1f:	.byte	$00
	byte_20:	.byte	$00
	byte_21:	.byte	$00
	byte_22:	.byte	$00
	byte_23:	.byte	$00
	byte_24:	.byte	$00
	byte_25:	.byte	$00
	byte_26:	.byte	$00
	byte_27:	.byte	$00
	byte_28:	.byte	$00
	byte_29:	.byte	$00
	byte_2a:	.byte	$00
	byte_2b:	.byte	$00
	byte_2c:	.byte	$00
	byte_2d:	.byte	$00
	byte_2e:	.byte	$00
	byte_2f:	.byte	$00
	byte_30:	.byte	$00
	byte_31:	.byte	$00
	byte_32:	.byte	$00
	byte_33:	.byte	$00
	byte_34:	.byte	$00
	byte_35:	.byte	$00
	byte_36:	.byte	$00
	byte_37:	.byte	$00
	byte_38:	.byte	$00
	byte_39:	.byte	$00
	byte_3a:	.byte	$00
	byte_3b:	.byte	$00
	byte_3c:	.byte	$00
	byte_3d:	.byte	$00
	byte_3e:	.byte	$00
	byte_3f:	.byte	$00
	byte_40:	.byte	$00
	byte_41:	.byte	$00
	byte_42:	.byte	$00
	byte_43:	.byte	$00
	byte_44:	.byte	$00
	byte_45:	.byte	$00
	byte_46:	.byte	$00
	byte_47:	.byte	$00
	byte_48:	.byte	$00
	byte_49:	.byte	$00
	byte_4a:	.byte	$00
	byte_4b:	.byte	$00
	byte_4c:	.byte	$00
	byte_4d:	.byte	$00
	byte_4e:	.byte	$00
	byte_4f:	.byte	$00
	byte_50:	.byte	$00
	byte_51:	.byte	$00
	byte_52:	.byte	$00
	byte_53:	.byte	$00
	byte_54:	.byte	$00
	byte_55:	.byte	$00
	byte_56:	.byte	$00
	byte_57:	.byte	$00
	byte_58:	.byte	$00
	byte_59:	.byte	$00
	byte_5a:	.byte	$00
	byte_5b:	.byte	$00
	byte_5c:	.byte	$00
	byte_5d:	.byte	$00
	byte_5e:	.byte	$00
	byte_5f:	.byte	$00
	byte_60:	.byte	$00
	byte_61:	.byte	$00
	byte_62:	.byte	$00
	byte_63:	.byte	$00
	byte_64:	.byte	$00
	byte_65:	.byte	$00
	byte_66:	.byte	$00
	byte_67:	.byte	$00
	byte_68:	.byte	$00
	byte_69:	.byte	$00
	byte_6a:	.byte	$00
	byte_6b:	.byte	$00
	byte_6c:	.byte	$00
	byte_6d:	.byte	$00
	byte_6e:	.byte	$00
	byte_6f:	.byte	$00
	byte_70:	.byte	$00
	byte_71:	.byte	$00
	byte_72:	.byte	$00
	byte_73:	.byte	$00
	byte_74:	.byte	$00
	byte_75:	.byte	$00
	byte_76:	.byte	$00
	byte_77:	.byte	$00
	byte_78:	.byte	$00
	byte_79:	.byte	$00
	byte_7a:	.byte	$00
	byte_7b:	.byte	$00
	byte_7c:	.byte	$00
	byte_7d:	.byte	$00
	byte_7e:	.byte	$00
	byte_7f:	.byte	$00
	byte_80:	.byte	$00
	byte_81:	.byte	$00
	byte_82:	.byte	$00
	byte_83:	.byte	$00
	byte_84:	.byte	$00
	byte_85:	.byte	$00
	byte_86:	.byte	$00
	byte_87:	.byte	$00
	byte_88:	.byte	$00
	byte_89:	.byte	$00
	byte_8a:	.byte	$00
	byte_8b:	.byte	$00
	byte_8c:	.byte	$00
	byte_8d:	.byte	$00
	byte_8e:	.byte	$00
	byte_8f:	.byte	$00
	byte_90:	.byte	$00
	byte_91:	.byte	$00
	byte_92:	.byte	$00
	byte_93:	.byte	$00
	byte_94:	.byte	$00
	byte_95:	.byte	$00
	byte_96:	.byte	$00
	byte_97:	.byte	$00
	byte_98:	.byte	$00
	byte_99:	.byte	$00
	byte_9a:	.byte	$00
	byte_9b:	.byte	$00
	byte_9c:	.byte	$00
	byte_9d:	.byte	$00
	byte_9e:	.byte	$00
	byte_9f:	.byte	$00
	byte_a0:	.byte	$00
	byte_a1:	.byte	$00
	byte_a2:	.byte	$00
	byte_a3:	.byte	$00
	byte_a4:	.byte	$00
	byte_a5:	.byte	$00
	byte_a6:	.byte	$00
	byte_a7:	.byte	$00
	byte_a8:	.byte	$00
	byte_a9:	.byte	$00
	byte_aa:	.byte	$00
	byte_ab:	.byte	$00
	byte_ac:	.byte	$00
	byte_ad:	.byte	$00
	byte_ae:	.byte	$00
	byte_af:	.byte	$00
	byte_b0:	.byte	$00
	byte_b1:	.byte	$00
	byte_b2:	.byte	$00
	byte_b3:	.byte	$00
	byte_b4:	.byte	$00
	byte_b5:	.byte	$00
	byte_b6:	.byte	$00
	byte_b7:	.byte	$00
	byte_b8:	.byte	$00
	byte_b9:	.byte	$00
	byte_ba:	.byte	$00
	byte_bb:	.byte	$00
	byte_bc:	.byte	$00
	byte_bd:	.byte	$00
	byte_be:	.byte	$00
	byte_bf:	.byte	$00
	byte_c0:	.byte	$00
	byte_c1:	.byte	$00
	byte_c2:	.byte	$00
	byte_c3:	.byte	$00
	byte_c4:	.byte	$00
	byte_c5:	.byte	$00
	byte_c6:	.byte	$00
	byte_c7:	.byte	$00
	byte_c8:	.byte	$00
	byte_c9:	.byte	$00
	byte_ca:	.byte	$00
	byte_cb:	.byte	$00
	byte_cc:	.byte	$00
	byte_cd:	.byte	$00
	byte_ce:	.byte	$00
	byte_cf:	.byte	$00
	byte_d0:	.byte	$00
	byte_d1:	.byte	$00
	byte_d2:	.byte	$00
	byte_d3:	.byte	$00
	byte_d4:	.byte	$00
	byte_d5:	.byte	$00
	byte_d6:	.byte	$00
	byte_d7:	.byte	$00
	byte_d8:	.byte	$00
	byte_d9:	.byte	$00
	byte_da:	.byte	$00
	byte_db:	.byte	$00
	byte_dc:	.byte	$00
	byte_dd:	.byte	$00
	byte_de:	.byte	$00
	byte_df:	.byte	$00
	byte_e0:	.byte	$00
	byte_e1:	.byte	$00
	byte_e2:	.byte	$00
	byte_e3:	.byte	$00
	byte_e4:	.byte	$00
	byte_e5:	.byte	$00
	byte_e6:	.byte	$00
	byte_e7:	.byte	$00
	byte_e8:	.byte	$00
	byte_e9:	.byte	$00
	byte_ea:	.byte	$00
	byte_eb:	.byte	$00
	byte_ec:	.byte	$00
	byte_ed:	.byte	$00
	byte_ee:	.byte	$00
	byte_ef:	.byte	$00
	byte_f0:	.byte	$00
	byte_f1:	.byte	$00
	byte_f2:	.byte	$00
	byte_f3:	.byte	$00
	byte_f4:	.byte	$00
	byte_f5:	.byte	$00
	byte_f6:	.byte	$00
	byte_f7:	.byte	$00
	byte_f8:	.byte	$00
	byte_f9:	.byte	$00
	byte_fa:	.byte	$00
	byte_fb:	.byte	$00
	byte_fc:	.byte	$00
	byte_fd:	.byte	$00
	byte_fe:	.byte	$00
	byte_ff:	.byte	$00

/* Constants */

	// ZP layout
.const sprPtrLo	= byte_30   // X pointer low
.const sprPtrHi	= byte_31   // X pointer high
.const logoPtrLo	= byte_46   // U pointer low
.const logoPtrHi	= byte_47   // U pointer high
.const logoX		= byte_21   // B equivalent
.const logoCount	= byte_20   // Y equivalent
.const tmpPtrLo 	= byte_f4
.const tmpPtrHi 	= byte_f5

#import "Source/asm/Constants.asm"


BasicUpstart65(Entry)

*=$2015 "Game Routines - yiearkungfu.asm"

#import "Source/asm/Hardware.asm"
#import "Source/asm/DisplaySetup.asm"
#import "Source/asm/PaletteSetup.asm"
#import "Source/asm/Loader.asm"
#import "Source/asm/6809.asm"

//#import "../Source/asm/AssetLoader.asm"

*=* "Main Entry - yiearkungfu.asm"	

Entry:
{
	
	// clean up first, colour ram, attributes..etc
	lda #147
	jsr $FFD2

	// Bank I/O in via C64 mechanism
	sei
	lda #$35
	sta $01
	
	enable40Mhz()
	enableVIC4Registers()
	disableCIA()
	
	//Disable C65 rom protection using Hypervisor trap
	disableC65ROM()
	
	// Loads assets
	LoadFile(GRAPHMEM, "TS.CHR") // Load graphical assets ( sprites and backghrounds )
	LoadFile(COLOR_RAM, "COLORRAM.BIN") // Load the RRB colour stream

	// Disable raster interrupts.
	lda #$00
	sta vicii_irqmask
	
	// Unmap C65 Roms $d030 clearing bits 3-7
	lda #$F8		// #%11111000
	trb $D030		// Clear bits 3-7
	
	// set base register to 2
	lda #$2
	tab
	cli				// Clear interrupts 
	
	// Black according to palette table.
	lda #$0		
	sta $D021		// background color	
	lda #$0
	sta $D020		// border color
	
	jsr	setUpDisplay
	jsr setUpPalette
	//jsr	CopyColors
	
	ldy #(byte_ff - byte_0)
	lda #$00
clearVars:
	sta byte_0,y
	dey
	bne clearVars
	
	jsr loc_8163	// start game.
}


//#import "Source/asm/SidTest.asm"

/* 80 colour palette table 

Use default Mega65 256 colour palette and modify it based on the Arcade's default palette

Components are split up into 3 of red, green and blue.

Yie Ar Kung Fu has 32 colours, 16 for backgrounds and 16 for sprites.

*/

* = * "Palette Data - yiearkungfu.asm"

customPaletteTbl_1_Start:
red:
.byte $00,$12,$00,$8b,$ed,$ff,$8b,$ed,$ff,$ed,$ff,$ff,$8b,$74,$8b,$ff // 00 - 15
.byte $00,$8b,$ed,$ed,$8b,$00,$ed,$ed,$12,$00,$00,$00,$00,$86,$8b,$ff // 16 - 32
customPaletteTbl_1_End:

green:
.byte $00,$12,$79,$ff,$00,$79,$86,$8b,$ff,$8b,$ff,$ed,$ff,$ed,$8b,$ff // 00 - 15
.byte $00,$ed,$86,$79,$79,$ed,$ff,$8b,$8b,$79,$00,$00,$79,$79,$8b,$ff // 16 - 32

blue:
.byte $00,$74,$ed,$ed,$00,$79,$74,$00,$00,$79,$79,$79,$00,$74,$79,$ed // 00 - 15
.byte $00,$ed,$74,$74,$79,$74,$ed,$00,$00,$00,$00,$79,$79,$ed,$79,$ed // 16 - 32
customPaleteTable_1_Total_Size:

* = SPRITE_RAM1	"Sprite Ram 1 - yiearkungfu.asm"
	.fill $30,0
* = *				"Work Ram 1 - yiearkungfu.asm"
	.fill $3d0,0

* = *				"Sprite Ram 2 - yiearkungfu.asm"
	.fill $30,0

* = *				"Work Ram 2 - yiearkungfu.asm"
	.fill $3d0,0

* = SCREEN_BASE "Character Ram - yiearkungfu.asm"
buffer:
	//.fill (SCREEN_BASE+$800) - SCREEN_BASE, 0    // reserve 0x800 bytes (2048 bytes) for the playfield.
	
	//  0x800 + 0xC00  = 0x1400
	.fill (((SCREEN_WIDTH/8 * SCREEN_HEIGHT/8)* 2) + ((RRB_Tail_words*CHARS_HIGH*2))), 0
buffer_buffer_end:


#import "Source/asm/SpriteQueue.asm"
#import "Source/asm/VideoRamHelper.asm"
#import "Source/asm/Game.asm"
#import "Source/asm/GameData.asm"
#import "Source/asm/Irq.asm"
