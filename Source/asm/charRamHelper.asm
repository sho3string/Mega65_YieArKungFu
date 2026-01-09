*=* "Character Ram Routines - charRamHelper.asm"

/* Simulates a 16x16px character by combining 4 8x8 characters */



do16x16Chars:

	/************************************* CHARACTER TILES **********************************************/
	

	/* 1st quadrant top left tile */
	ldy     byte_2			// 0x5	; offset into table at 8dc7
	lda     (byte_10),y	// tile # 0xe2
	ldy     byte_3			// 0x00 ; offset into char ram
	
	clc
	adc 	#<(GRAPHMEM / 64 )   // address of tile / 64 = 16 bit tile #
	sta     (byte_12),y		// char ram 0xe2@0x2000
	
	/* 2nd quadrant top right tile */
	ldy     byte_2			// 0x5	; offset into table at 8dc7
	lda     (byte_10),y	// tile # 0xe2
	adc		#1				// get next tile
	ldy     byte_3			// 0x00 ; offset into char ram
	
	clc
	adc 	#<(GRAPHMEM / 64 )   // address of tile / 64 = 16 bit tile #
	iny		// skip attribute for previous character
	iny
	sta     (byte_12),y		// char ram 0xe2@0x2000
	
	
	/* 3nd quadrant bot left tile */											// 2nd iteration.
	ldy     byte_2			// 0x5	; offset into table at 8dc7				; 0x05
	lda     (byte_10),y	// tile # 0xe2										; 0x84
	adc		#32				// get tile # 1 row down.							; 0xa4
	ldy     byte_3			// 0x00 ; offset into char ram					; 0x04	
	clc
	adc 	#<(GRAPHMEM / 64 )   // address of tile / 64 = 16 bit tile #
	
	phy
	pha
	//lda		#LOGICAL_WIDTH														// 0x40
	lda 	#LINESTEP
	tay																			// y=0x40
	pla
	sta     (byte_12),y			// char ram 0xe2@0x2000						
	ply
	
	
	/* 4th quadrant bot right tile */
	ldy     byte_2			// 0x5	; offset into table at 8dc7
	lda     (byte_10),y	// tile # 0xe2
	adc		#33				// get tile # 1 row down + #1 position
	ldy     byte_3			// 0x00 ; offset into char ram
	clc
	adc 	#<(GRAPHMEM / 64 )   // address of tile / 64 = 16 bit tile #
	
	phy
	pha
	//lda		#LOGICAL_WIDTH+2
	lda		#LINESTEP+2
	tay		
	pla
	sta     (byte_12),y		// char ram 0xe2@0x2000
	ply
	 
	
	
	/************************************* ATTRIBUTES **********************************************/


	/* 1st quadrant top left attr */
	lda     byte_5			// 0x30 ; attribute ram
	//sta     (byte_14),y	// attr ram 0x30@0x2200, not required since attr ram is layed out differently on the Mega65
	iny
	clc
	adc 	#>(GRAPHMEM / 64 )    // address of tile / 64 = 16 bit tile #
	sta     (byte_12),y	
	
	/* 2nds quadrant top right attr */
	lda     byte_5			// 0x30 ; attribute ram
	iny
	iny
	clc
	adc 	#>(GRAPHMEM / 64 )    // address of tile / 64 = 16 bit tile #
	sta     (byte_12),y	
	//dey
	//dey
	
	/* 3rd quadrant bot left attr */
	lda     byte_5			// 0x30 ; attribute ram
	clc
	adc 	#>(GRAPHMEM / 64 )    // address of tile / 64 = 16 bit tile #
	
	phy
	pha
	//lda		#LOGICAL_WIDTH+1
	lda		#LINESTEP+1
	tay
	pla
	sta     (byte_12),y	
	ply
	
	/* 4th quadrant bot right attr */
	lda     byte_5			// 0x30 ; attribute ram
	clc
	adc 	#>(GRAPHMEM / 64 )    // address of tile / 64 = 16 bit tile #
	phy
	pha
	//lda		#LOGICAL_WIDTH+3
	lda		#LINESTEP+3
	tay
	pla
	sta     (byte_12),y	
	ply
	rts