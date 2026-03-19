// ============================================================
// Sprite → Pixie → RRB Pipeline
// ============================================================
//
// This module converts arcade sprite RAM into RRB “pixies”
// (8x8 strips) and emits per-row command streams for the
// MEGA65 RRB renderer.
//
// The pipeline is split into 4 stages:
//
// ------------------------------------------------------------
// 1. BuildSpriteQueueFromArcadeRAM
// ------------------------------------------------------------
// Reads raw arcade sprite RAM and builds a compact queue.
//
// - Iterates all hardware sprites
// - Skips uninitialised/parked entries (Y = $00 or $01)
// - Extracts and normalises:
//     Y, X, TILE, ATTR (with flip bits separated)
// - Stores 4-byte entries into SpriteQueueData:
//     [Y, X, TILE, ATTR]
//
// Result: a clean, tightly packed sprite queue for this frame.
//
// ------------------------------------------------------------
// 2. BuildPixieListFromSpriteQueue
// ------------------------------------------------------------
// Expands each 16x16 sprite into 8x8 “pixies” suitable for RRB.
//
// For each sprite:
// - Converts arcade Y (inverted) into screen space
// - Applies Y bias
// - Splits Y into:
//     coarse row (8-pixel rows)
//     fine Y (sub-row offset 0..7)
// - Computes base 8x8 tile index (top-left tile)
// - Uses TopMask/BotMask to clip rows for fine Y scrolling
//
// Each sprite produces:
//   Coarse (aligned): 4 pixies (2 rows)
//   Fine (sub-pixel): up to 8 pixies (3 rows, with masking)
//
// Emits pixies into arrays:
//   PixieRow, PixieXLo/Hi, PixieTileLo/Hi, PixieMask, Active
//
// Also assigns each pixie to a row (PixieRow), which is later
// used by the RRB builder.
//
// ------------------------------------------------------------
// 3. RRB_BuildRow
// ------------------------------------------------------------
// Builds one RRB row command stream.
//
// - Scans all pixies
// - Selects those matching CurrentRow
// - Stores indices into RowOrder[]
// - Clamps to hardware limit (RRB_PixiesPerRow = 37)
// - Sorts by X (insertion sort, stable enough for small sets)
//
// Emits:
//   - Screen commands (X, tile, gotoX)
//   - Colour commands (mask, attributes)
//
// Pads remaining slots with prototype entries
// Writes final EOL markers
//
// Result: fully formed RRB command list for one row.
//
// ------------------------------------------------------------
// 4. RRB_BuildAllRows
// ------------------------------------------------------------
// Builds all rows for the frame.
//
// - Iterates all character rows
// - Advances screen + colour pointers per row
// - Applies frame-phase split (even/odd rows per frame)
//   to avoid vblank overrun
// - Calls RRB_BuildRow for active rows only
//
// After completion:
// - Clears per-frame pixie “used” flags
//
// ------------------------------------------------------------
// Tile Layout Assumption
// ------------------------------------------------------------
//
// Tilesheet layout is pre-arranged as:
//
//   [TL][BL]
//   [TR][BR]
//
// Tile offsets from base8:
//   TL = +0
//   BL = +1
//   TR = +16
//   BR = +17
//
// Additional offsets (+2, +18) are used for lower spill rows.
//
// No runtime tile remapping is required.
//
// ------------------------------------------------------------
// Notes / Constraints
// ------------------------------------------------------------
//
// - Maximum pixies per row is limited to 37 (RRB constraint)
// - Excess pixies are dropped after clamping
// - Fine Y uses bit 5–7 encoding in PixieXHi (FCM mode)
// - Frame-phase splitting halves per-frame workload
// - Current implementation performs per-row scan + sort
//   (candidate for future optimisation via row-linked lists)
//
// ============================================================
// TODO (perf):
// Current approach scans ALL pixies per row and sorts them (O(N²)).
// Replace with per-row linked lists (RowHead/PixieNext) built during
// pixie emission to eliminate scan + sort entirely.


// ZP temps (use your existing ones)
.const Q_IDX   	= byte_33   // reuse if safe in this scope
.const P_IDX   	= byte_34   // reuse if safe in this scope
.const Q_Y     	= byte_35
.const Q_X     	= byte_36
.const Q_TILE  	= byte_37
.const Q_ATTR  	= byte_38
.const TLo     	= byte_39
.const THi     	= byte_3a
.const Q_TOP      	= byte_3b   // top mask
.const ROW     	= byte_3c   // coarse row for this sprite
.const CurrentRow	= byte_3d
.const Q_ATTR_RAW	= byte_3e
.const Q_FLIPBITS	= byte_3f
.const Q_ROW		= byte_40
.const Q_TMP		= byte_41   // general scratch (was Q_YME in old code)
.const Q_CARRY 	= byte_42   // carry temp for tile hi add
.const Q_YSUB5		= byte_43   // MUST be a safe scratch not used elsewhere
.const Q_YSUB		= byte_44 
.const XHI_TEMP	= byte_45
.const COLPTR0 	= byte_46
.const COLPTR1 	= byte_47
.const COLPTR2 	= byte_48
.const COLPTR3 	= byte_49
.const SORT_I		= byte_4a   // choose free zp
.const KEY_X		= byte_4b
.const Q_XHI		= byte_4c
.const Q_BOT      	= byte_4d

.const FCM_YOFFS_DIR		= $10	// bit4 in raster-hi
.const SPR_TILE_STRIDE	= 16	// 16 tiles across
.const SPR_TILE_BASE		= $0200	// Add offset to tilesheet to begin at sprite data.
.const Y_BIAS				= 16

*=* "Sprite Queue Routines - SpriteQueue.asm"

/* Test 1 Sprite */

BuildSpriteQueueFromArcadeRAM:
    lda #0
    sta SpriteQueueCount // clear count of sprite queue
	sta Q_IDX			   // clear sprite index

!loop:
    lda Q_IDX
    cmp #SPRITE_MAX
    bcs !done+

    // srcOff = spriteIndex * 2
    //lda Q_IDX
    asl
    tay

    // ---- read Y first ----
    lda SPRITE_RAM1+1,y
    sta Q_Y

    // skip parked/uninitialised
    lda Q_Y
    beq !nextSprite+
    cmp #$01
    beq !nextSprite+

    // ---- read rest ----
    lda SPRITE_RAM1+0,y
    sta Q_ATTR_RAW
	
	and #%11000000
	sta Q_FLIPBITS		// keep bits 6/7 (flip flags)
	
	lda Q_ATTR_RAW
    and #%00111111
    sta Q_ATTR

	/* Sprite RAM 2 reads */
    lda SPRITE_RAM2+0,y // X
    sta Q_X
    lda SPRITE_RAM2+1,y // TILE
    sta Q_TILE
	
	lda SpriteQueueCount // gets current count
	asl						// destOff = count * 4. multuply by 2 bytes to get corresponding index
	asl
	tax						// use as index
	
    // queue at entry - 4 bytes 000
    lda Q_Y
    sta SpriteQueueData+0,x
    lda Q_X
    sta SpriteQueueData+1,x
    lda Q_TILE
    sta SpriteQueueData+2,x
    lda Q_ATTR
    sta SpriteQueueData+3,x
	inc SpriteQueueCount

!nextSprite:
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



/*
// ------------------------------------------------------------
// ComputeBase8FromSprite16
// IN:  Q_TILE, Q_ATTR (bit0 is msb of sprite16)
// OUT: THi:TLo = base8 (8x8 tile index of TL)
// Clobbers: A, X
// ------------------------------------------------------------
ComputeBase8FromSprite16:
    // sprite16 = (Q_ATTR&1)<<8 | Q_TILE  -> THi:TLo
    lda Q_TILE
    sta TLo
    lda Q_ATTR
    and #$01
    sta THi

    // col = sprite16 & 7  (save in X)
    lda TLo
    and #$07
    tax                 // X = col 0..7

    // row = sprite16 >> 3  (shift THi:TLo right 3)
    lsr THi
    ror TLo
    lsr THi
    ror TLo
    lsr THi
    ror TLo             // now TLo=row, THi=0

    // base = row * 32  (<<5)  -- THi already 0, no need to clear
    asl TLo
    rol THi
    asl TLo
    rol THi
    asl TLo
    rol THi
    asl TLo
    rol THi
    asl TLo
    rol THi             // THi:TLo = row*32

    // + col*2
    txa                 // A = col
    asl                 // A = col*2
    clc
    adc TLo
    sta TLo
    bcc !+
    inc THi
!:   rts



ComputeBase8FromSprite16:
    // sprite16 = (Q_ATTR&1)<<8 | Q_TILE  -> THi:TLo
    lda Q_TILE
    sta TLo
    lda Q_ATTR
    and #$01
    sta THi

    // col = sprite16 & 7  (save)
    lda TLo
    and #$07
    sta Q_TMP          // col 0..7

    // row = sprite16 >> 3  (shift THi:TLo right 3)
    lsr THi
    ror TLo
    lsr THi
    ror TLo
    lsr THi
    ror TLo            // now TLo=row, THi=0

    // base = row * 32  (<<5)
    lda #0
    sta THi
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

    // + col*2
    lda Q_TMP
    asl                // col*2
    clc
    adc TLo
    sta TLo
    bcc !+
    inc THi
!:
    rts
*/

RRB_BuildRow:
    // ---------------------------------------------
    // init counters
    // ---------------------------------------------
    lda #0
    sta RowCount
   
    // ---------------------------------------------
    // single pass: build compact RowOrder[]
    // ---------------------------------------------
    ldx #0
!scanAll:
    cpx PixieCount
    beq !scanDone+

    lda PixieActive,x
    beq !nextPixie+

    lda PixieRow,x
    cmp CurrentRow
    bne !nextPixie+

    // match: store pixie index in RowOrder[RowCount]
    ldy RowCount
    txa
    sta RowOrder,y

    inc RowCount
    inc RRB_NeededThisRow

!nextPixie:
    inx
    bne !scanAll-
!scanDone:

    // ---------------------------------------------
    // clamp RowCount to RRB_PixiesPerRow (37)
    // (RRB_NeededThisRow keeps full count for stats)
    // ---------------------------------------------
    lda RowCount
    cmp #RRB_PixiesPerRow
    bcc !noClamp+
    lda #RRB_PixiesPerRow
    sta RowCount
	lda #0
	sta RRB_NeededThisRow
	
!noClamp:

    // ---------------------------------------------
    // insertion sort RowOrder[0..RowCount-1] by PixieXLo
    // ---------------------------------------------
    ldx #1                  // i = 1
!sortOuter:
    cpx RowCount
    bcs !sortDone+          // i >= RowCount -> done

    stx SORT_I

    ldy RowOrder,x           // keyIndex = RowOrder[i]
    sty Q_TMP               // save keyIndex

    lda PixieXLo,y
    sta KEY_X                // keyX = PixieXLo[keyIndex]

    dex                     // j = i - 1
!sortInner:
    bmi !insertKey+         // j < 0 -> insert at 0

    ldy RowOrder,x           // candidate index
    lda PixieXLo,y
    cmp KEY_X                // candidateX ? keyX
    bcc !insertKey+         // candidateX <= keyX -> stop shifting

    // shift RowOrder[j] -> RowOrder[j+1]
    lda RowOrder,x
    sta RowOrder+1,x

    dex
    jmp !sortInner-
!insertKey:
    inx                     // j+1
    ldy Q_TMP               // keyIndex
    sty RowOrder,x           // RowOrder[j+1] = keyIndex

    ldx SORT_I                // restore i
    inx                     // i++
    jmp !sortOuter-
!sortDone:

    
    // ---------------------------------------------
    // Emit tail for this row
    // byte_0/1   = screen tail pointer
    // COLPTR0..3 = colour tail pointer
    // RowCount   = number of pixies to emit (<= 37)
    // RowOrder[]  = sorted pixie indices
    // ---------------------------------------------
    ldy #0
    ldz #0
    ldx #0                  // slot index 0..RowCount-1

!emitLoop:
    cpx RowCount
    lbeq !emitFinal+

    stx P_IDX               // save slot index

    // X = pixie index for this slot
    lda RowOrder,x
    tax

    // -------- colour for THIS pixie (X = pixie index) --------
    lda #$98
    sta ((COLPTR0)),z
    inz
    lda PixieMask,x
    sta ((COLPTR0)),z
    inz
    lda #0
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

    // -------- screen for THIS pixie (X = pixie index) --------
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

    // gotoX = next pixie X else 320
    ldx P_IDX
    inx
    cpx RowCount
    beq !lastPixie+

    lda RowOrder,x
    tax

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
    ldx P_IDX
    inx
    jmp !emitLoop-

!emitFinal:
    // -------------------------------------------------
    // pad remaining slots up to RRB_PixiesPerRow
    // NOTE: X currently = slot index (RowCount..)
    // -------------------------------------------------
!padLoop:
    cpx #RRB_PixiesPerRow
    lbeq !writeFinal+

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
    lda RRB_PixieProtoType+4
    sta (byte_0),y
    iny
    lda RRB_PixieProtoType+5
    sta (byte_0),y
    iny

    // colour prototype (6 bytes)
    lda RRB_ColorProtoType+0
    sta ((COLPTR0)),z
    inz
    lda RRB_ColorProtoType+1
    sta ((COLPTR0)),z
    inz
    lda RRB_ColorProtoType+2
    sta ((COLPTR0)),z
    inz
    lda RRB_ColorProtoType+3
    sta ((COLPTR0)),z
    inz
    lda RRB_ColorProtoType+4
    sta ((COLPTR0)),z
    inz
    lda RRB_ColorProtoType+5
    sta ((COLPTR0)),z
    inz

    inx
    jmp !padLoop-

!writeFinal:
    // -------------------------------------------------
    // final screen words (EOL + dummy tile)
    // -------------------------------------------------
    lda #<320
    sta (byte_0),y
    iny
    lda #>320
    sta (byte_0),y
    iny

    lda RRB_PixieProtoType+2     // dummy tile lo (match your prototype)
    sta (byte_0),y
    iny
    lda RRB_PixieProtoType+3     // dummy tile hi
    sta (byte_0),y
    iny

    // -------------------------------------------------
    // final colour words (goto ctrl + dummy attrs)
    // -------------------------------------------------
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
    lda CurrentRow
    and #1
    cmp RRB_FramePhase
    bne !skipBuild+

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


// ============================================================
// BuildPixieListFromSpriteQueue
// Correct for tilesheet layout:
//   [TL][BL]
//   [TR][BR]
//
// Tile offsets:
//   TL = base + 0
//   BL = base + 1
//   TR = base + 16
//   BR = base + 17
//
// No diagonal swap in code — tilesheet already rearranged.
// ============================================================

BuildPixieListFromSpriteQueue:

	/* Clear our variables */
    lda #0
    sta PixieCount
    sta P_IDX
    sta Q_IDX

!loop:
    lda Q_IDX
    cmp SpriteQueueCount
    lbeq !done+

    // qOff = Q_IDX * 4
    //lda Q_IDX
    asl
    asl
    tay

    // ------------------------------------------------------------
    // Load queue entry (arcade Y is inverted)
    // ------------------------------------------------------------
    lda SpriteQueueData+0,y
    sta Q_Y
    lda SpriteQueueData+1,y
    sta Q_X
    lda SpriteQueueData+2,y
    sta Q_TILE
    lda SpriteQueueData+3,y
    sta Q_ATTR

	
	/* Invert Y, arcade coordinates are inverted
		yinv = (~Y)+1
	*/
	lda Q_Y
	eor #$ff
	clc
	adc #1
	sta Q_TMP
	
	
	/* apply bias */
	sec
	lda Q_TMP
	sbc #Y_BIAS
	sta Q_TMP
	
	/* Fine Y */
	lda Q_TMP
	and #$07
	sta Q_YSUB
	
	lda Q_YSUB
    asl
    asl
    asl
    asl
    asl
    sta Q_YSUB5        // fine-y bits 5..7
	
	/* Coarse row */
	lda Q_TMP
	lsr
	lsr
	lsr
	sta Q_ROW			// index for coarse row.
	
    // compute base8 tile index
    jsr ComputeBase8FromSprite16

	// Draw the pixies.
    lda Q_ROW
    cmp #(CHARS_HIGH-2)
    bcs !next+

    lda P_IDX
    cmp #(PIXIE_MAX-8)
    bcs !next+

    // load masks
    ldy Q_YSUB
    lda TopMask,y
    sta Q_TOP
    lda BotMask,y
    sta Q_BOT

    jsr Emit_TL_R_top
    jsr Emit_TR_R_top
	
    jsr Emit_TL_R1_bot
    jsr Emit_TR_R1_bot

	jsr Emit_BL_R1_top
    jsr Emit_BR_R1_top
	
    jsr Emit_BL_R2_bot
    jsr Emit_BR_R2_bot
	
!next:
    inc Q_IDX
    jmp !loop-

!done:
    rts
	
	
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
	jsr StoreTile_TL
	inc P_IDX
	inc PixieCount
	rts


// ------------------------------------------------------------
// Emit TR @ row R, topmask
// ------------------------------------------------------------
Emit_TR_R_top:
	ldx P_IDX
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
	jsr StoreTile_TR
	inc P_IDX
	inc PixieCount
	rts
	
// ------------------------------------------------------------
// Emit TL @ row R+1, botmask
// ------------------------------------------------------------
Emit_TL_R1_bot:
	ldx P_IDX
	lda #1
	sta PixieActive,x
	lda Q_ROW
	clc
	adc #1
	sta PixieRow,x

	lda Q_X
	sta PixieXLo,x
	lda #FCM_YOFFS_DIR  
	ora Q_YSUB5
	sta PixieXHi,x
	lda Q_BOT
	sta PixieMask,x

	jsr StoreTile_BL
	inc P_IDX
	inc PixieCount
	rts


// ------------------------------------------------------------
// Emit TR @ row R+1, botmask
// ------------------------------------------------------------
Emit_TR_R1_bot:
	ldx P_IDX
	lda #1
	sta PixieActive,x
	lda Q_ROW
	clc
	adc #1
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

	jsr StoreTile_BR
	inc P_IDX
	inc PixieCount
	rts
	
// ------------------------------------------------------------
// Emit BL @ row R+1, topmask
// ------------------------------------------------------------

Emit_BL_R1_top:
	ldx P_IDX
	lda #1
	sta PixieActive,x

	lda Q_ROW
	clc
	adc #1
	sta PixieRow,x

	lda Q_X
	sta PixieXLo,x

	lda #FCM_YOFFS_DIR
	ora Q_YSUB5
	sta PixieXHi,x

	lda Q_TOP                // TopMask[sub]
	sta PixieMask,x

	jsr StoreTile_BL
	inc P_IDX
	inc PixieCount
	rts


// ------------------------------------------------------------
// Emit BR @ row R+1, topmask
// ------------------------------------------------------------
Emit_BR_R1_top:
	ldx P_IDX
	lda #1
	sta PixieActive,x
	lda Q_ROW
	clc
	adc #1
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

	jsr StoreTile_BR
	inc P_IDX
	inc PixieCount
	rts
	
// ------------------------------------------------------------
// Emit BL @ row R+2, botmask
// ------------------------------------------------------------
Emit_BL_R2_bot:
    ldx P_IDX
    lda #1
    sta PixieActive,x

    lda Q_ROW
    clc
    adc #2
    sta PixieRow,x

    lda Q_X
    sta PixieXLo,x

    lda #FCM_YOFFS_DIR
    ora Q_YSUB5
    sta PixieXHi,x

    lda Q_BOT
    sta PixieMask,x

    jsr StoreTile_B1   // <-- NOT BL
    inc P_IDX
    inc PixieCount
    rts

// ------------------------------------------------------------
// Emit BR @ row R+2, botmask
// ------------------------------------------------------------
Emit_BR_R2_bot:
    ldx P_IDX
    lda #1
    sta PixieActive,x

    lda Q_ROW
    clc
    adc #2
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

    jsr StoreTile_B2   // <-- NOT BR
    inc P_IDX
    inc PixieCount
    rts

RRB_FramePhase:		.byte 0    // 0 or 1
RRB_NeededThisRow:	.byte 0    // temp for current row
RowCount:			.byte 0
PixieCount:			.byte 0
PixieActive:			.fill PIXIE_MAX, 0   // 1=active
PixieRow:				.fill PIXIE_MAX, 0   // coarse row 0..31
PixieXLo:				.fill PIXIE_MAX, 0
PixieXHi:				.fill PIXIE_MAX, 0   // only bits0-1 used
PixieTileLo:			.fill PIXIE_MAX, 0
PixieTileHi:			.fill PIXIE_MAX, 0
// Temp working set for one row build
RowOrder:				.fill RRB_PixiesPerRow, 0
PixieMask:				.fill PIXIE_MAX,0
RowHead:				.fill CHARS_HIGH, $ff   // head index per row
PixieNext:				.fill PIXIE_MAX, 0      // next pointer

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
