/*How to index entries

Entry i (0..23):

// offset = i*4
// base   = SpriteQueueData

// Y    at SpriteQueueData + offset + 0
// X    at SpriteQueueData + offset + 1
// TILE at SpriteQueueData + offset + 2
// ATTR at SpriteQueueData + offset + 3


So in code you do:

lda i
asl
asl
tay
lda SpriteQueueData+0,y   // Y

*/

.const Q_IDX	= byte_34
.const Q_Y		= byte_35
.const Q_X		= byte_36
.const Q_TILE	= byte_37
.const Q_ATTR	= byte_38		// “sanitized for queue”: keep bit0, clear bits6/7
.const TLo		= byte_39
.const THi		= byte_3a
.const Q_YME	= byte_3b
.const Q_ATTR_RAW = byte_3c	// original arcade full byte
.const Q_FLIPBITS = byte_3d	// just bits 6/7 ( FlipX/FlipY ) of attribute from arcade


.const SPRITE_BASE_PAGE = 0
.const SPR_TILE_STRIDE  = 16     // 16 tiles across
.const SPR_TILE_BASE	  = $0200  // Add offset to tilesheet to begin at sprite data.


*=* "Sprite Queue Routines - SpriteQueue.asm"

BuildPixieBucketsFromSpriteQueue:
    lda #0
    sta Q_IDX

!spriteLoop:
    lda Q_IDX
    cmp SpriteQueueCount
    lbeq !done+

    // qOff = Q_IDX * 4
    lda Q_IDX
    asl
    asl
    tay

    // Load queue entry
    lda SpriteQueueData+0,y
    sta Q_Y
    lda SpriteQueueData+1,y
    sta Q_X
    lda SpriteQueueData+2,y
    sta Q_TILE
    lda SpriteQueueData+3,y
    sta Q_ATTR

    // ------------------------------------------------------------
    // byte_0/byte_1 = SCREEN_BASE + Q_IDX*LINESTEP_BYTES + (CHARS_WIDE*2)
    // (Q_IDX selects the Pixie row slot: row0=row0 sprite, row1=row1 sprite...)
    // ------------------------------------------------------------
    lda #<SCREEN_BASE
    sta byte_0
    lda #>SCREEN_BASE
    sta byte_1

    ldx Q_IDX
    beq !rowAdded+

!addStride:
    clc
    lda byte_0
    adc #<LINESTEP_BYTES
    sta byte_0
    lda byte_1
    adc #>LINESTEP_BYTES
    sta byte_1
    dex
    bne !addStride-

!rowAdded:
    clc
    lda byte_0
    adc #<(CHARS_WIDE * 2)
    sta byte_0
    lda byte_1
    adc #>(CHARS_WIDE * 2)
    sta byte_1

    // ------------------------------------------------------------
    // Use THIS ONE Pixie row for THIS ONE arcade sprite.
    // 4 pixies in the same row.
    // For now: pixie2/3 overlap 0/1 (acceptable per your request).
    // ------------------------------------------------------------

    // Pixie 0 (TL)
	
    WRITE_GOTOX(0, 0)
    WRITE_PIXIE_TILE(0, 0)
    //WRITE_GOTOX_END(4)

    // Pixie 1 (TR)
    WRITE_GOTOX(6, 8)
    WRITE_PIXIE_TILE(6, 1)
    //WRITE_GOTOX_END(10)
	
	// move down one pixie bucket row (Y + 8), this is for testing only.
	clc
	lda byte_0
	adc #<LINESTEP_BYTES
	sta byte_0
	lda byte_1
	adc #>LINESTEP_BYTES
	sta byte_1

    // Pixie 2 (BL)
    WRITE_GOTOX(12, 0)          // or 16 if you want 4-wide
    //WRITE_PIXIE_TILE(12, 2)
	WRITE_PIXIE_TILE(12, SPR_TILE_STRIDE)
    //WRITE_GOTOX_END(16)

    // Pixie 3 (BR)
    WRITE_GOTOX(18, 8)
    //WRITE_PIXIE_TILE(18, 3)
    WRITE_PIXIE_TILE(18, SPR_TILE_STRIDE+1) 
    WRITE_GOTOX_END(22)
	
	

    inc Q_IDX
    jmp !spriteLoop-

!done:
    rts

BuildSpriteQueueFromArcadeRAM:
    lda #0
    sta SpriteQueueCount
    sta Q_IDX                 // spriteIndex = 0

!loop:
    lda Q_IDX
    cmp #SPRITE_MAX
    beq !done+

    // srcOff = spriteIndex * 2
    lda Q_IDX
    asl
    tay

    // ---- skip parked sprites (arcade convention) ----
    //lda SPRITE_RAM1+1,y       // arcade Y
    //cmp #$01
    //beq !nextSprite+
	
	
	/* Sprite RAM 1 reads */
	// ---- read Y first ----
    lda SPRITE_RAM1+1,y       // Y byte (pair: [ATTR,Y])
    sta Q_Y
	
	//---- skip uninitialized/parked ----
    // Your RAM shows Y=$01 for uninit and also many $00's.
    lda Q_Y
    beq !nextSprite+          // Y==0 => invalid/uninitialized, may need to remove this later.
    cmp #$01
    beq !nextSprite+          // Y==1 => parked/uninitialized
	
	// ---- read the rest ----
	lda SPRITE_RAM1+0,y         // arcade ATTR
    sta Q_ATTR_RAW              // keep full byte for later use if needed

    and #%11000000
    sta Q_FLIPBITS              // keep bits 6/7 (flip flags)

    lda Q_ATTR_RAW
    and #%00111111              // clear bits 6/7, keep bit0 and other low bits
    sta Q_ATTR		   			// queue attr: bit0 preserved, flips removed
	
	/* Sprite RAM 2 reads */
    lda SPRITE_RAM2+0,y       // X
    sta Q_X
    lda SPRITE_RAM2+1,y       // TILE
    sta Q_TILE
	
	// ---- optional extra sanity: skip the exact uninit signature ----
    // If your RAM2 looks like 00 01 repeating too, this will drop it:
    // uninit signature: ATTR=0, X=0, TILE=1, Y=1 (already excluded by Y==1)
    // also exclude the all-zero signature:
    lda Q_ATTR
    ora Q_X
    ora Q_TILE
    ora Q_Y
    beq !nextSprite+          // all four are 0 => invalid

	// ---- destOff = count * 4 ----
    lda SpriteQueueCount		// gets current count
    asl							// multiply by 2 bytes to get corresponding index
    asl
    tax							// use as index.

    // ---- store queue entry ----
    lda Q_Y
    sta SpriteQueueData+0,x	// Store Y Position in Queue
    lda Q_X
    sta SpriteQueueData+1,x	// Store X Position in Queue
    
	lda Q_TILE
    sta SpriteQueueData+2,x	// Store Tile index in Queue
    lda Q_ATTR
    sta SpriteQueueData+3,x	// Store Stripped Attribute Data
	
	
	//--- TEST: force arcade index $1E0 ---
    /*lda #$f4
    sta SpriteQueueData+2,x
    lda #$01
    sta SpriteQueueData+3,x*/

    inc SpriteQueueCount

!nextSprite:
    inc Q_IDX
    jmp !loop-

!done:
    rts

	
// Parks all 24 sprite buckets off-screen by writing Y=$01 into raster-lo
// for the 4 pixies in each bucket row tail.
//
// Uses: Q_IDX, byte_0, byte_1. Clobbers A,X,Y.

ParkAllPixieBuckets:
    lda #0
    sta Q_IDX

!loop:
    lda Q_IDX
    cmp #SPRITE_MAX
    beq !done+

    // byte_0/1 = SCREEN_BASE
    lda #<SCREEN_BASE
    sta byte_0
    lda #>SCREEN_BASE
    sta byte_1

    // advance by Q_IDX rows
    ldx Q_IDX
    beq !rowAdded+

!addStride:
    clc
    lda byte_0
    adc #<LINESTEP_BYTES
    sta byte_0
    lda byte_1
    adc #>LINESTEP_BYTES
    sta byte_1
    dex
    bne !addStride-

!rowAdded:
    // + CHARS_WIDE*2 column offset
    clc
    lda byte_0
    adc #<(CHARS_WIDE * 2)
    sta byte_0
    lda byte_1
    adc #>(CHARS_WIDE * 2)
    sta byte_1

    // raster X = $FF for all 4 pixies
    lda #$ff
    ldy #0
    sta (byte_0),y
    ldy #6
    sta (byte_0),y
    ldy #12
    sta (byte_0),y
    ldy #18
    sta (byte_0),y

    // disable gotox by clearing BOTH start+resume hi bytes
    lda #0
    // start hi
    ldy #1
    sta (byte_0),y
    ldy #7
    sta (byte_0),y
    ldy #13
    sta (byte_0),y
    ldy #19
    sta (byte_0),y
    // resume hi
    ldy #5
    sta (byte_0),y
    ldy #11
    sta (byte_0),y
    ldy #17
    sta (byte_0),y
    ldy #23
    sta (byte_0),y

    inc Q_IDX
    jmp !loop-

!done:
    rts


/*
.macro WRITE_PIXIE_TILE(pixieBaseOfs, delta) {
    // --- build base = SPR_TILE_BASE + Q_TILE + delta ---
    clc
    lda Q_TILE
    adc #delta
    adc #<SPR_TILE_BASE
    sta TLo

    lda Q_ATTR
    and #$01
    adc #>SPR_TILE_BASE      // includes carry from low-byte add
    sta THi

    // --- add TILE_OFFSET ---
    clc
    lda TLo
    adc #<TILE_OFFSET
    ldy #pixieBaseOfs+2
    sta (byte_0),y

    lda THi
    adc #>TILE_OFFSET
    iny
    sta (byte_0),y
}*/
/*
	lda RRB_PixieProtoType+2
    clc
    adc #<TILE_OFFSET
    sta (byte_0),y
    iny
    lda RRB_PixieProtoType+3
    clc
    adc #>TILE_OFFSET
    sta (byte_0),y
    iny
*/

.macro WRITE_PIXIE_TILE(pixieBaseOfs, delta) {
	
	// ------------------------------------------------------------
	// Convert arcade 16x16 sprite index to MEGA65 8x8 tile index
	//
	// Arcade sprites are 16x16 pixels.
	// MEGA65 pixies are 8x8 tiles.
	//
	// The sprite sheet is laid out as a 2D grid of 8x8 tiles:
	//   - 16 tiles wide in 8x8 units
	//   - therefore 8 sprites per row (each sprite is 2 tiles wide)
	//
	// Arcade provides a 9-bit sprite index:
	//   sprite16 = (Q_ATTR bit0) << 8 | Q_TILE
	//
	// This sprite index counts 16x16 sprites linearly:
	//   sprite16 = 0, 1, 2, 3, ...
	//
	// But because the sheet is 2D-packed, the top-left 8x8 tile
	// of a sprite is NOT at sprite16 * 4.
	//
	// Instead:
	//   col = sprite16 & 7          ; which sprite column (0..7)
	//   row = sprite16 >> 3         ; which sprite row
	//
	// Each sprite row occupies:
	//   2 rows of 8x8 tiles
	//   => 2 * SPR_TILE_STRIDE = 32 tiles per sprite row
	//
	// Each sprite column advances by:
	//   2 tiles horizontally
	//
	// Therefore:
	//   base8 = row * 32 + col * 2
	//
	// Result:
	//   THi:TLo = base8
	//   (8x8 tile index of the TOP-LEFT subtile of the 16x16 sprite)
	//
	// From this base index, subtiles are addressed as:
	//   TL = base8 + 0
	//   TR = base8 + 1
	//   BL = base8 + SPR_TILE_STRIDE      (+16)
	//   BR = base8 + SPR_TILE_STRIDE + 1  (+17)
	// ------------------------------------------------------------


    // Build 16-bit sprite16 index into THi:TLo
    lda Q_TILE
    sta TLo			// Load the low byte of the 16×16 sprite index into TLo.
    lda Q_ATTR 	// Extract bit0 of Q_ATTR (the arcade MSB of the sprite index).
    and #$01
    sta THi			// THi:TLo = 9-bit sprite16 (0..511)


	/* col = sprite16 & 7  (save it)
	spritesPerRow = 8, so the column within the row is the low 3 bits.
	col = sprite16 % 8
	Save col for later (we’ll need col*2). */
	lda TLo
	and #$07
	sta Q_YME          // scratch (0..7)

	/* row = sprite16 >> 3  (TLo becomes row)
	
	This shifts the 9-bit value THi:TLo right by 3 bits.
	After these 3 lsr/ror pairs:
		TLo = sprite16 / 8 (integer divide)
		THi becomes 0 (because the original value was only 9 bits)
		
		So now
		row = sprite16 >> 3
	*/
	lsr THi
	ror TLo
	lsr THi
	ror TLo
	lsr THi
	ror TLo            // now TLo=row, THi=0

	/* base8 = row * 32  (<<5)
	Shift left 5 times (<< 5) to multiply by 32.
	Why 32?
	Each 16×16 sprite occupies 2 rows of 8×8 tiles.
	Each 8×8 row is SPR_TILE_STRIDE = 16 tiles wide.
	So one sprite row consumes 2 * 16 = 32 tiles in the 8×8 tile index space.
	*/
	
	lda #0
	sta THi			   // Clear THi explicitly so THi:TLo is a clean 16-bit number holding row.
	asl TLo
	rol THi
	asl TLo
	rol THi
	asl TLo
	rol THi
	asl TLo
	rol THi
	asl TLo
	rol THi            // THi:TLo = row*32

	/* add col*2
	Each sprite is 2 tiles wide, so moving one sprite to the right means +2 tiles.
	So col*2 gives the horizontal offset in 8×8 tiles.
	*/
	lda Q_YME
	asl                // *2
	
	/*
	Add col*2 to the low byte.
	*/
	
	clc
	adc TLo
	sta TLo
	
	/*
	If the low-byte addition overflowed, increment the high byte.
	At this point:
	THi:TLo = row*32 + col*2
	This is base8, the top-left 8×8 tile index for the given arcade 16×16 sprite index.
	*/
	bcc !noCarry+
	inc THi
	!noCarry:
	// result: THi:TLo = base8 (top-left 8x8 tile index)

	

	// low byte
    clc
    lda #<TILE_OFFSET
    adc #<SPR_TILE_BASE
    adc TLo
    adc #delta
    ldy #pixieBaseOfs+2
    sta (byte_0),y

    // capture carry from low-byte chain (0/1)
    lda #0
    adc #0
    sta Q_YME

    // high byte
    clc
    lda #>TILE_OFFSET
    adc #>SPR_TILE_BASE
    adc THi
    adc Q_YME
    iny
    sta (byte_0),y
	
}


.macro WRITE_GOTOX(pixieBaseOfs, add) {
    ldy #pixieBaseOfs

    // low byte
    clc
    lda Q_X
    adc #add
    sta (byte_0),y
    iny

    // high byte = (Q_ATTR bit0) + carry from low-byte add
    lda #$00 //Q_ATTR
    and #$01
    adc #$00
    sta (byte_0),y
}

.macro WRITE_GOTOX_END(pixieBaseOfs) {
    ldy #pixieBaseOfs
    lda #$ff
    sta (byte_0),y
    iny
    lda #$00
    sta (byte_0),y
}

RowSpriteCount:
    .fill SPRITE_MAX, 0

