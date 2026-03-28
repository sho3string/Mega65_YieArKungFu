*=* "VideoRamHelper.asm"

.const byte_fd_arc = $d2
.const byte_fe_arc = $d3
.const byte_dst_lo = $d4
.const byte_dst_hi = $d5
.const byte_colidx = $d6



RowPrefixBytes:
	.byte $00,$00,$00,$00,$00,$00,$10,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	


.function ArcadeToMegaTextByte(addr) {
    .var off   = addr - ARCADE_VRAM_BASE
    .var row   = off >> 6
    .var col   = off & $3f
    .var cell  = col >> 1
    .var lane  = col & 1
    .var base  = SCREEN_BASE + (row * ROW_STRIDE) + (cell * 2)
    .return base + (lane == 1 ? 0 : 1)
}


/************************************************
* Attract playfield column start pointers
*
* Original sequence begins from:
*   $59BF + 2 = $59C1
*
* Then advances by 2 bytes per column.
************************************************/

PlayfieldColumnPtrs:
.for (var i = 0; i < $21; i++) {
    .word ArcadeToMegaTextByte($59c1 + (i * 2))
}



/************************************************
* TranslateArcadeTextPtrToMega
*
* Input:
*   byte_fd_arc / byte_fe_arc = arcade VRAM address
*                               (e.g. $59BF, $59C1, ...)
*
* Output:
*   byte_fd / byte_fe = translated MEGA65 tile-byte address
*
* Notes:
*   - arcade layout is [attr][tile]
*   - MEGA65 layout is [tile][attr]
*   - this helper is for TILE-byte arcade addresses
************************************************/

TranslateArcadeTextPtrToMega:

	// off = arcade_ptr - $5800
	sec
	lda byte_fd_arc
	sbc #<ARCADE_VRAM_BASE
	sta byte_7              // off lo
	lda byte_fe_arc
	sbc #>ARCADE_VRAM_BASE
	sta byte_8              // off hi

	// row = off >> 6
	lda byte_8
	sta byte_9
	lda byte_7
	lsr byte_9
	ror
	lsr byte_9
	ror
	lsr byte_9
	ror
	lsr byte_9
	ror
	lsr byte_9
	ror
	lsr byte_9
	ror
	sta byte_10             // row (low)
	// byte_9 now effectively zero for our range

	// col = off & $3F
	lda byte_7
	and #$3f
	sta byte_11

	// cell = col >> 1
	lda byte_11
	lsr
	sta byte_12

	// base = SCREEN_BASE + row * ROW_STRIDE
	lda #<SCREEN_BASE
	sta byte_fd
	lda #>SCREEN_BASE
	sta byte_fe

	ldx byte_10
	!row_add:
	cpx #0
	beq !row_done+
	clc
	lda byte_fd
	adc #<($40 + (RRB_Tail_words * 2))
	sta byte_fd
	lda byte_fe
	adc #>($40 + (RRB_Tail_words * 2))
	sta byte_fe
	dex
	bra !row_add-
	!row_done:

	// add row prefix bytes
	ldx byte_10
	lda RowPrefixBytes,x
	clc
	adc byte_fd
	sta byte_fd
	bcc !no_prefix_carry+
	inc byte_fe
	!no_prefix_carry:

	// add cell*2
	lda byte_12
	asl
	clc
	adc byte_fd
	sta byte_fd
	bcc !done+
	inc byte_fe
!done:
    rts
