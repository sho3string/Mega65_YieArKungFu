// ZP temps (use your existing ones)
.const Q_IDX		= byte_33   // reuse if safe in this scope
.const P_IDX		= byte_34   // reuse if safe in this scope
.const Q_Y			= byte_35
.const Q_X			= byte_36
.const Q_TILE		= byte_37
.const Q_ATTR		= byte_38
.const TLo			= byte_39
.const THi			= byte_3a
.const Q_TOP		= byte_3b   // top mask
.const ROW			= byte_3c   // coarse row for this sprite
.const CurrentRow	= byte_3d
.const Q_ATTR_RAW	= byte_3e
.const Q_FLIPBITS	= byte_3f
.const Q_ROW		= byte_40
.const Q_TMP		= byte_41   // general scratch (was Q_YME in old code)
.const Q_CARRY		= byte_42   // carry temp for tile hi add
.const Q_YSUB5		= byte_43   // MUST be a safe scratch not used elsewhere
.const Q_YSUB		= byte_44 
.const XHI_TEMP	= byte_45
.const SORT_I		= byte_46   // choose free zp
.const KEY_X		= byte_47
.const Q_XHI		= byte_48
.const Q_BOT		= byte_49
.const COLPTR0		= byte_5a
.const COLPTR1		= byte_5b
.const COLPTR2		= byte_5c
.const COLPTR3		= byte_5d
.const Q_ROW_P1	= byte_5e
.const Q_ROW_P2	= byte_5f


.const FCM_YOFFS_DIR		= $10	// bit4 in raster-hi
.const SPR_TILE_STRIDE	= 16	// 16 tiles across
.const SPR_TILE_BASE		= $0200	// Add offset to tilesheet to begin at sprite data.
.const Y_BIAS				= 16

*=* "Sprite Queue Routines - SpriteQueue.asm"


BuildRowListsFromArcadeRAM:

	
    // clear runtime pixie/node state
    lda #0
    sta PixieCount
    sta P_IDX
    sta Q_IDX

    // clear per-row linked list heads
    lda #$ff
    ldx #0
!clearHeads:
    sta RowHead,x
    inx
    cpx #CHARS_HIGH
    bne !clearHeads-

!loop:
    lda Q_IDX
    cmp #SPRITE_MAX
    lbeq !done+

    // srcOff = spriteIndex * 2
    asl
    tay

    // ------------------------------------------------------------
    // Load arcade sprite directly
    // ------------------------------------------------------------
    lda SPRITE_RAM1+1,y
    sta Q_Y

    // skip parked / uninitialised
    lda Q_Y
    lbeq !next+
    cmp #$01
    lbeq !next+

    lda SPRITE_RAM2+0,y
    sta Q_X

    lda SPRITE_RAM2+1,y
    sta Q_TILE

    lda SPRITE_RAM1+0,y
    sta Q_ATTR_RAW

    lda Q_ATTR_RAW
    and #%11000000
    sta Q_FLIPBITS
	
	/* Convert arcade flip bits to MEGA65 colour flip bits */
	lda Q_FLIPBITS
	eor #$40	// sprites already face towards the right, arcade does the opposite and they facing left.
				// 0x40 is set for sprites to face right on arcade, so we exclusive or to remove this on the mega65
	and #$40
	sta Q_MEGA_FLP

	lda Q_FLIPBITS
	and #$80
	ora Q_MEGA_FLP
	sta Q_MEGA_FLP

    lda Q_ATTR_RAW
    and #%00111111
    sta Q_ATTR

    // ------------------------------------------------------------
    // Convert Y
    // ------------------------------------------------------------
    lda Q_Y
    eor #$ff
    clc
    adc #1
    sta Q_TMP

    sec
    lda Q_TMP
    sbc #Y_BIAS
    sta Q_TMP

    // fine Y
    lda Q_TMP
    and #$07
    sta Q_YSUB

    lda Q_YSUB
    asl
    asl
    asl
    asl
    asl
    sta Q_YSUB5

    // coarse row
    lda Q_TMP
    lsr
    lsr
    lsr
    sta Q_ROW
	
	clc
	adc #1
	sta Q_ROW_P1
	adc #1
	sta Q_ROW_P2


    // compute base 8x8 tile
    jsr ComputeBase8FromSprite16

    // ------------------------------------------------------------
    // bounds / capacity
    // aligned sprites emit 4 pixies
    // misaligned sprites emit 8 pixies
    // ------------------------------------------------------------
	lda Q_YSUB
	beq !alignedCapacity+

	// misaligned: needs rows R..R+2 and 8 pixies
	lda Q_ROW
	cmp #(CHARS_HIGH-2)
	bcs !next+

	lda P_IDX
	cmp #(PIXIE_MAX-8)
	bcs !next+
	jmp !capacityDone+

!alignedCapacity:
    // aligned: needs rows R..R+1 and 4 pixies
    lda Q_ROW
    cmp #(CHARS_HIGH-1)
    bcs !next+

    lda P_IDX
    cmp #(PIXIE_MAX-4)
    bcs !next+

!capacityDone:

    // load masks
    ldy Q_YSUB
    lda TopMask,y
    sta Q_TOP
    lda BotMask,y
    sta Q_BOT

    // aligned vs spill
    lda Q_YSUB
    beq !aligned+

    // misaligned = full 3-row path
    jsr Emit_TL_R_top
    jsr Emit_TR_R_top
    jsr Emit_TL_R1_bot
    jsr Emit_TR_R1_bot
    jsr Emit_BL_R1_top
    jsr Emit_BR_R1_top
    jsr Emit_BL_R2_bot
    jsr Emit_BR_R2_bot
    jmp !next+

!aligned:
    jsr Emit_TL_R_aligned
    jsr Emit_TR_R_aligned
    jsr Emit_BL_R1_aligned
    jsr Emit_BR_R1_aligned

!next:
    inc Q_IDX
    jmp !loop-

!done:
    rts


ComputeBase8FromSprite16:

    ldx Q_TILE
    lda RowBaseLo,x
    sta TLo

    lda RowBaseHi,x
    sta THi

    lda Q_ATTR
    and #1
    beq !+

    // add 32*32 = 1024 = $0400
    clc
    lda TLo
    adc #$00
    sta TLo
    lda THi
    adc #$04
    sta THi
!:

    lda Q_TILE
    and #7
    asl
    clc
    adc TLo
    sta TLo
    bcc !+
    inc THi
!:
    rts



// ------------------------------------------------------------
// RRB_BuildRow
// Direct linked-list version (no RowOrder[])
// ------------------------------------------------------------

RRB_BuildRow:
	// ---------------------------------------------
	// init counters
	// ---------------------------------------------
	lda #0
	sta RowCount
	sta RRB_NeededThisRow

	// ---------------------------------------------
	// pass 1: count active pixies in this row
	// ---------------------------------------------
	ldy CurrentRow
	lda RowHead,y
	cmp #$ff
	lbeq !noPixies+

	tax                     // X = first pixie in this row

!countWalk:

	lda RowCount
    cmp RRB_GlobalPeakCount
    bcc !noGlobalPeak+
    sta RRB_GlobalPeakCount
    lda CurrentRow
    sta RRB_GlobalPeakRow
!noGlobalPeak:

	lda PixieActive,x
	beq !countNext+         // optional safety

	inc RRB_NeededThisRow
	lda RowCount
	cmp #RRB_PixiesPerRow
	bcs !countNext+
	inc RowCount

!countNext:
	lda PixieNext,x
	tax
	cmp #$ff
	bne !countWalk-

!noPixies:

	// ---------------------------------------------
	// calculate peak pixie usage
	// ---------------------------------------------
	ldy CurrentRow
	lda RRB_NeededThisRow
	cmp RowPeakTable,y
	bcc !noRowPeak+
	sta RowPeakTable,y
!noRowPeak:

	// ---------------------------------------------
	// emit tail directly from linked list
	// byte_0/1   = screen tail pointer
	// COLPTR0..3 = colour tail pointer
	// RowCount   = number of pixies to emit (<= limit)
	// ---------------------------------------------
	ldy #0
	ldz #0
	lda #0
	sta P_IDX               // emit count so far

	ldy CurrentRow
	lda RowHead,y
	sta Q_TMP        // or some scratch
	ldy #0
	ldz #0
	lda #0
	sta P_IDX
	lda Q_TMP
	cmp #$ff
	lbeq !emitFinal+
	tax

!emitWalk:
	lda P_IDX
	cmp RowCount
	lbeq !emitFinal+

	lda PixieActive,x
	lbeq !advanceCurrent+    // optional safety

	stx Q_TMP               // save current pixie index

	// -------- colour for THIS pixie --------
	lda #$98
	sta ((COLPTR0)),z
	inz
	lda PixieMask,x
	sta ((COLPTR0)),z
	inz
	//lda #0
	lda PixieFlip,x        /* Colour RAM byte 0: flip bits */
	sta ((COLPTR0)),z
	inz
	sta ((COLPTR0)),z
	inz
	lda #$10
	sta ((COLPTR0)),z
	inz
	lda #0
	sta ((COLPTR0)),z
	inz

	// -------- screen for THIS pixie --------
	lda PixieXLo,x
	sta (byte_0),y
	iny
	lda PixieXHi,x
	sta (byte_0),y
	iny
	lda PixieTileLo,x
	sta (byte_0),y
	iny
	lda PixieTileHi,x
	sta (byte_0),y
	iny

	// -------------------------------------------------
	// gotoX = next emitted pixie X, else 320
	// Need to search forward through PixieNext chain
	// because we removed RowOrder[]
	// -------------------------------------------------
	lda P_IDX
	clc
	adc #1
	cmp RowCount
	beq !lastPixie+

	// find next active pixie in chain
	ldx Q_TMP
	lda PixieNext,x
	tax

!findNextActive:
	cpx #$ff
	beq !lastPixie+

	lda PixieActive,x
	bne !haveNextPixie+

	lda PixieNext,x
	tax
	jmp !findNextActive-

!haveNextPixie:
	lda PixieXLo,x
	sta (byte_0),y
	iny

	lda PixieXHi,x
	and #$03
	sta (byte_0),y
	iny

	jmp !afterGoto+

!lastPixie:
	lda #<320
	sta (byte_0),y
	iny
	lda #>320
	sta (byte_0),y
	iny

!afterGoto:
	inc P_IDX

	// advance current pixie = PixieNext[current]
	ldx Q_TMP
	lda PixieNext,x
	tax
	cpx #$ff
	lbne !emitWalk-
	jmp !emitFinal+

!advanceCurrent:
	lda PixieNext,x
	tax
	cpx #$ff
	lbne !emitWalk-

!emitFinal:
!padLoop:
	lda P_IDX
	cmp #RRB_PixiesPerRow
	beq !writeFinal+

	// screen prototype (6 bytes)
	lda RRB_PixieProtoType+0
	sta (byte_0),y
	iny
	lda RRB_PixieProtoType+1
	sta (byte_0),y
	iny
	lda RRB_PixieProtoType+2
	sta (byte_0),y
	iny
	lda RRB_PixieProtoType+3
	sta (byte_0),y
	iny

	// gotoX for padded slot
	lda P_IDX
	clc
	adc #1
	cmp #RRB_PixiesPerRow
	beq !padLastGoto+

	asl
	asl
	asl
	sta (byte_0),y
	iny
	lda #0
	sta (byte_0),y
	iny
	jmp !padGotoDone+

!padLastGoto:
	lda #<320
	sta (byte_0),y
	iny
	lda #>320
	sta (byte_0),y
	iny

!padGotoDone:
	inc P_IDX
	jmp !padLoop-

!writeFinal:
	// final screen words (EOL + dummy tile)
	lda #<320
	sta (byte_0),y
	iny
	lda #>320
	sta (byte_0),y
	iny

	lda RRB_PixieProtoType+2
	sta (byte_0),y
	iny
	lda RRB_PixieProtoType+3
	sta (byte_0),y
	iny

	// final colour words
	lda #$90
	sta ((COLPTR0)),z
	inz
	lda #0
	sta ((COLPTR0)),z
	inz

	lda #0
	sta ((COLPTR0)),z
	inz
	sta ((COLPTR0)),z
    rts



RRB_BuildAllRows:
    lda #0
    sta CurrentRow

    // init screen pointer to row 0
    lda #<SCREEN_BASE
    sta byte_0
    lda #>SCREEN_BASE
    sta byte_1

    // init colour pointer to row 0
    lda #<COLOR_RAM
    sta COLPTR0
    lda #>COLOR_RAM
    sta COLPTR1
    lda #((COLOR_RAM >> 16) & $ff)
    sta COLPTR2
    lda #((COLOR_RAM >> 24) & $ff)
    sta COLPTR3

!rowLoop:
    lda CurrentRow
    cmp #CHARS_HIGH
    lbeq !done+

    // ---- advance screen pointer to tail start ----
    clc
    lda byte_0
    adc #<TAIL_OFF
    sta byte_0
    lda byte_1
    adc #>TAIL_OFF
    sta byte_1

    // ---- advance color pointer to tail start ----
    clc
    lda COLPTR0
    adc #<TAIL_OFF
    sta COLPTR0
    lda COLPTR1
    adc #>TAIL_OFF
    sta COLPTR1
    bcc !+
    inc COLPTR2
    bne !+
    inc COLPTR3
!:

	
    // --------- NEW: only build rows matching phase ----------
    //lda CurrentRow
    //and #1
    //cmp RRB_FramePhase
    //bne !skipBuild+

    jsr RRB_BuildRow

!skipBuild:
    // --------- restore row base (undo TAIL_OFF) -------------
    sec
    lda byte_0
    sbc #<TAIL_OFF
    sta byte_0
    lda byte_1
    sbc #>TAIL_OFF
    sta byte_1

    sec
    lda COLPTR0
    sbc #<TAIL_OFF
    sta COLPTR0
    lda COLPTR1
    sbc #>TAIL_OFF
    sta COLPTR1
    bcs !+
    dec COLPTR2
    bne !+
    dec COLPTR3
!:

    // --------- advance to next row --------------------------
    clc
    lda byte_0
    adc #<LINESTEP_BYTES
    sta byte_0
    lda byte_1
    adc #>LINESTEP_BYTES
    sta byte_1

    clc
    lda COLPTR0
    adc #<LINESTEP_BYTES
    sta COLPTR0
    lda COLPTR1
    adc #>LINESTEP_BYTES
    sta COLPTR1
    bcc !+
    inc COLPTR2
    bne !+
    inc COLPTR3
!:

    inc CurrentRow
    jmp !rowLoop-

!done:
    jsr RRB_ClearUsedMarks
    rts

RRB_ClearUsedMarks:
    ldx #0
!:
    cpx PixieCount
    beq !done+
    lda PixieActive,x
    and #$7F
    sta PixieActive,x
    inx
    jmp !-
!done:
    rts

/*

When 16x16 quads are flipped horizontally, we don't only
on flipping each pixie. We must also flip the left and right
quad as pixies are only 8x8 pixels. Otherwise we end up with 
an object which is inside out.

Also swap the left and right quadrants because pixies are 8x8 pixies
and you cannot completely flip a 16x16 sprite by flipping individual tiles.

*/


StoreTile_Q_B1:
    lda Q_FLIPBITS
    and #$40
    bne !normal+
    jmp StoreTile_B2
!normal:
    jmp StoreTile_B1
	
StoreTile_Q_B2:
    lda Q_FLIPBITS
    and #$40
    bne !normal+
    jmp StoreTile_B1
!normal:
    jmp StoreTile_B2

	
StoreTile_Q_TL:
	lda Q_FLIPBITS
	and #$40              /* arcade horizontal flip */
	bne !normal+
	jmp StoreTile_TR
!normal:
	jmp StoreTile_TL

StoreTile_Q_TR:
	lda Q_FLIPBITS
	and #$40
	bne !normal+
	jmp StoreTile_TL
!normal:
	jmp StoreTile_TR

StoreTile_Q_BL:
	lda Q_FLIPBITS
	and #$40
	bne !normal+
	jmp StoreTile_BR
!normal:
	jmp StoreTile_BL

StoreTile_Q_BR:
	lda Q_FLIPBITS
	and #$40
	bne !normal+
	jmp StoreTile_BL
!normal:
	jmp StoreTile_BR
// ------------------------------------------------------------
// StoreTile_TL  (tile = base + 0)
// ------------------------------------------------------------
StoreTile_TL:

    clc
    lda #<TILE_OFFSET
    adc #<SPR_TILE_BASE
    adc TLo
    sta PixieTileLo,x

    lda #0
    adc #0
    sta Q_CARRY

    clc
    lda #>TILE_OFFSET
    adc #>SPR_TILE_BASE
    adc THi
    adc Q_CARRY
    sta PixieTileHi,x
    rts


// ------------------------------------------------------------
// StoreTile_BL  (tile = base + 1)
// ------------------------------------------------------------
StoreTile_BL:
    clc
    lda #<TILE_OFFSET
    adc #<SPR_TILE_BASE
    adc TLo
    adc #1
    sta PixieTileLo,x

    lda #0
    adc #0
    sta Q_CARRY

    clc
    lda #>TILE_OFFSET
    adc #>SPR_TILE_BASE
    adc THi
    adc Q_CARRY
    sta PixieTileHi,x
    rts


// ------------------------------------------------------------
// StoreTile_TR  (tile = base + 16)
// ------------------------------------------------------------
StoreTile_TR:
    clc
    lda #<TILE_OFFSET
    adc #<SPR_TILE_BASE
    adc TLo
    adc #<SPR_TILE_STRIDE      // +16
    sta PixieTileLo,x

    lda #0
    adc #0
    sta Q_CARRY

    clc
    lda #>TILE_OFFSET
    adc #>SPR_TILE_BASE
    adc THi
    adc Q_CARRY
    sta PixieTileHi,x
    rts


// ------------------------------------------------------------
// StoreTile_BR  (tile = base + 17)
// ------------------------------------------------------------
StoreTile_BR:
    clc
    lda #<TILE_OFFSET
    adc #<SPR_TILE_BASE
    adc TLo
    adc #<SPR_TILE_STRIDE+1      // +17
   
    sta PixieTileLo,x

    lda #0
    adc #0
    sta Q_CARRY

    clc
    lda #>TILE_OFFSET
    adc #>SPR_TILE_BASE
    adc THi
    adc Q_CARRY
    sta PixieTileHi,x
    rts
	
	
// ------------------------------------------------------------
// StoreTile_BL  (tile = base + 2)
// ------------------------------------------------------------
StoreTile_B1:
    clc
    lda #<TILE_OFFSET
    adc #<SPR_TILE_BASE
    adc TLo
    adc #2
    sta PixieTileLo,x

    lda #0
    adc #0
    sta Q_CARRY

    clc
    lda #>TILE_OFFSET
    adc #>SPR_TILE_BASE
    adc THi
    adc Q_CARRY
    sta PixieTileHi,x
    rts
	
	
// ------------------------------------------------------------
// StoreTile_B2  (tile = base + 18)
// ------------------------------------------------------------
StoreTile_B2:
    clc
    lda #<TILE_OFFSET
    adc #<SPR_TILE_BASE
    adc TLo
    adc #<SPR_TILE_STRIDE+2      // +18
   
    sta PixieTileLo,x

    lda #0
    adc #0
    sta Q_CARRY

    clc
    lda #>TILE_OFFSET
    adc #>SPR_TILE_BASE
    adc THi
    adc Q_CARRY
    sta PixieTileHi,x
    rts

	
// ------------------------------------------------------------
// Emit TL @ row R, topmask
// ------------------------------------------------------------
Emit_TL_R_top:
	ldx P_IDX
	lda Q_MEGA_FLP
	sta PixieFlip,x
	lda #1
	sta PixieActive,x
	lda Q_ROW
	sta PixieRow,x
	lda Q_X
	sta PixieXLo,x

	lda #FCM_YOFFS_DIR
	ora Q_YSUB5
	sta PixieXHi,x

	lda Q_TOP                    // TopMask[sub]
	sta PixieMask,x
	jsr StoreTile_Q_TL
	
	ldy PixieRow,x
	lda RowHead,y
	sta PixieNext,x
	txa
	sta RowHead,y
	
	inc P_IDX
	inc PixieCount
	rts


// ------------------------------------------------------------
// Emit TR @ row R, topmask
// ------------------------------------------------------------
Emit_TR_R_top:
	ldx P_IDX
	lda Q_MEGA_FLP
	sta PixieFlip,x
	lda #1
	sta PixieActive,x
	lda Q_ROW
	sta PixieRow,x

	clc
	lda Q_X
	adc #8
	sta PixieXLo,x

	lda #0
	adc #0
	and #$03
	ora #FCM_YOFFS_DIR
	ora Q_YSUB5
	sta PixieXHi,x

	lda Q_TOP                   // TopMask[sub]
	sta PixieMask,x
	jsr StoreTile_Q_TR
	
	ldy PixieRow,x
	lda RowHead,y
	sta PixieNext,x
	txa
	sta RowHead,y
	
	inc P_IDX
	inc PixieCount
	rts
	
// ------------------------------------------------------------
// Emit TL @ row R+1, botmask
// ------------------------------------------------------------
Emit_TL_R1_bot:
	ldx P_IDX
	lda Q_MEGA_FLP
	sta PixieFlip,x
	lda #1
	sta PixieActive,x
	lda Q_ROW_P1
	sta PixieRow,x

	lda Q_X
	sta PixieXLo,x
	lda #FCM_YOFFS_DIR  
	ora Q_YSUB5
	sta PixieXHi,x
	lda Q_BOT
	sta PixieMask,x
	jsr StoreTile_Q_BL
	
	ldy PixieRow,x
	lda RowHead,y
	sta PixieNext,x
	txa
	sta RowHead,y
	
	inc P_IDX
	inc PixieCount
	rts


// ------------------------------------------------------------
// Emit TR @ row R+1, botmask
// ------------------------------------------------------------
Emit_TR_R1_bot:
	ldx P_IDX
	lda Q_MEGA_FLP
	sta PixieFlip,x
	lda #1
	sta PixieActive,x
	lda Q_ROW_P1
	sta PixieRow,x

	clc
	lda Q_X
	adc #8
	sta PixieXLo,x

	lda #0
	adc #0
	and #3
	ora #FCM_YOFFS_DIR
	ora Q_YSUB5
	sta PixieXHi,x

	lda Q_BOT
	sta PixieMask,x
	jsr StoreTile_Q_BR
	
	ldy PixieRow,x
	lda RowHead,y
	sta PixieNext,x
	txa
	sta RowHead,y
	
	inc P_IDX
	inc PixieCount
	rts
	
// ------------------------------------------------------------
// Emit BL @ row R+1, topmask
// ------------------------------------------------------------

Emit_BL_R1_top:
	ldx P_IDX
	lda Q_MEGA_FLP
	sta PixieFlip,x
	lda #1
	sta PixieActive,x

	lda Q_ROW_P1
	sta PixieRow,x

	lda Q_X
	sta PixieXLo,x

	lda #FCM_YOFFS_DIR
	ora Q_YSUB5
	sta PixieXHi,x

	lda Q_TOP                // TopMask[sub]
	sta PixieMask,x
	jsr StoreTile_Q_BL
	
	ldy PixieRow,x
	lda RowHead,y
	sta PixieNext,x
	txa
	sta RowHead,y
	
	inc P_IDX
	inc PixieCount
	rts


// ------------------------------------------------------------
// Emit BR @ row R+1, topmask
// ------------------------------------------------------------
Emit_BR_R1_top:
	ldx P_IDX
	lda Q_MEGA_FLP
	sta PixieFlip,x
	lda #1
	sta PixieActive,x
	lda Q_ROW_P1
	sta PixieRow,x

	clc
	lda Q_X
	adc #8
	sta PixieXLo,x

	lda #0
	adc #0
	and #$03
	ora #FCM_YOFFS_DIR
	ora Q_YSUB5
	sta PixieXHi,x

	lda Q_TOP
	sta PixieMask,x
	jsr StoreTile_Q_BR
	
	ldy PixieRow,x
	lda RowHead,y
	sta PixieNext,x
	txa
	sta RowHead,y
	
	inc P_IDX
	inc PixieCount
	rts
	
// ------------------------------------------------------------
// Emit BL @ row R+2, botmask
// ------------------------------------------------------------
Emit_BL_R2_bot:
    ldx P_IDX
	lda Q_MEGA_FLP
	sta PixieFlip,x
    lda #1
    sta PixieActive,x

	lda Q_ROW_P2
    sta PixieRow,x

    lda Q_X
    sta PixieXLo,x

    lda #FCM_YOFFS_DIR
    ora Q_YSUB5
    sta PixieXHi,x

    lda Q_BOT
    sta PixieMask,x
    jsr StoreTile_Q_B1   // <-- NOT BL
	
	ldy PixieRow,x
	lda RowHead,y
	sta PixieNext,x
	txa
	sta RowHead,y
	
    inc P_IDX
    inc PixieCount
    rts

// ------------------------------------------------------------
// Emit BR @ row R+2, botmask
// ------------------------------------------------------------
Emit_BR_R2_bot:
    ldx P_IDX
	lda Q_MEGA_FLP
	sta PixieFlip,x
    lda #1
    sta PixieActive,x

    lda Q_ROW_P2
    sta PixieRow,x

    clc
    lda Q_X
    adc #8
    sta PixieXLo,x

    lda #0
    adc #0
    and #3
    ora #FCM_YOFFS_DIR
    ora Q_YSUB5
    sta PixieXHi,x

    lda Q_BOT
    sta PixieMask,x
    jsr StoreTile_Q_B2   // <-- NOT BR
	
	ldy PixieRow,x
	lda RowHead,y
	sta PixieNext,x
	txa
	sta RowHead,y
	
    inc P_IDX
    inc PixieCount
    rts
	
Emit_TL_R_aligned:

	ldx P_IDX
	lda Q_MEGA_FLP
	sta PixieFlip,x
	lda #1
	sta PixieActive,x

	lda Q_ROW
	sta PixieRow,x

	lda Q_X
	sta PixieXLo,x

	lda #$00
	sta PixieXHi,x

	lda #$ff
	sta PixieMask,x

	jsr StoreTile_TL

	ldy PixieRow,x
	lda RowHead,y
	sta PixieNext,x
	txa
	sta RowHead,y

	inc P_IDX
	inc PixieCount
	rts


Emit_TR_R_aligned:

	ldx P_IDX
	lda Q_MEGA_FLP
	sta PixieFlip,x
	lda #1
	sta PixieActive,x

	lda Q_ROW
	sta PixieRow,x

	clc
	lda Q_X
	adc #8
	sta PixieXLo,x

	lda #0
	adc #0
	and #$03
	sta PixieXHi,x

	lda #$ff
	sta PixieMask,x

	jsr StoreTile_TR

	ldy PixieRow,x
	lda RowHead,y
	sta PixieNext,x
	txa
	sta RowHead,y

	inc P_IDX
	inc PixieCount
	rts


Emit_BL_R1_aligned:

	ldx P_IDX
	lda Q_MEGA_FLP
	sta PixieFlip,x
	lda #1
	sta PixieActive,x

	lda Q_ROW_P1
	sta PixieRow,x

	lda Q_X
	sta PixieXLo,x

	lda #$00
	sta PixieXHi,x

	lda #$ff
	sta PixieMask,x

	jsr StoreTile_BL

	ldy PixieRow,x
	lda RowHead,y
	sta PixieNext,x
	txa
	sta RowHead,y

	inc P_IDX
	inc PixieCount
	rts


Emit_BR_R1_aligned:

    ldx P_IDX
	lda Q_MEGA_FLP
	sta PixieFlip,x
	lda #1
	sta PixieActive,x

	lda Q_ROW_P1
	sta PixieRow,x

	clc
	lda Q_X
	adc #8
	sta PixieXLo,x

	lda #0
	adc #0
	and #$03
	sta PixieXHi,x

	lda #$ff
	sta PixieMask,x

	jsr StoreTile_BR

	ldy PixieRow,x
	lda RowHead,y
	sta PixieNext,x
	txa
	sta RowHead,y

	inc P_IDX
	inc PixieCount
	rts


//RRB_FramePhase:		.byte 0    // 0 or 1
RRB_NeededThisRow:	.byte 0    // temp for current row
RowCount:				.byte 0
PixieCount:			.byte 0
Q_MEGA_FLP:			.byte 0

RowPeakTable:			.fill CHARS_HIGH, 0 // debugging.

PixieActive:			.fill PIXIE_MAX, 0   // 1=active
PixieRow:				.fill PIXIE_MAX, 0   // coarse row 0..31
PixieXLo:				.fill PIXIE_MAX, 0
PixieXHi:				.fill PIXIE_MAX, 0   // only bits0-1 used
PixieTileLo:			.fill PIXIE_MAX, 0
PixieTileHi:			.fill PIXIE_MAX, 0
PixieFlip:				.fill PIXIE_MAX, 0
// Temp working set for one row build
PixieMask:				.fill PIXIE_MAX, 0
RowHead:				.fill CHARS_HIGH, $ff   // head index per row
PixieNext:				.fill PIXIE_MAX, 0      // next pointer

RRB_GlobalPeakCount: .byte 0
RRB_GlobalPeakRow:   .byte 0

RowBaseLo:
    .fill 256, <(((i >> 3) * 32))
RowBaseHi:
    .fill 256, >(((i >> 3) * 32))
	

TopMask:
	.byte %11111111
	.byte %11111110
	.byte %11111100
	.byte %11111000
	.byte %11110000
	.byte %11100000
	.byte %11000000
	.byte %10000000

BotMask:
	.byte %00000000
	.byte %00000001
	.byte %00000011
	.byte %00000111
	.byte %00001111
	.byte %00011111
	.byte %00111111
	.byte %01111111
