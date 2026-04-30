// 6809 emulation

*=* "6809 Emulation - 6809.asm"

// Flags bit layout:
// bit0 = Carry
// bit1 = Zero
// bit2 = Negative

// Flags bit layout:
// bit0 = Carry (C)
// bit1 = Zero  (Z)
// bit2 = Negative (N)

/*

tmp = A
Flags.C = tmp & 1
A = (tmp >> 1) | (tmp & $80)
Flags.Z = (A == 0)
Flags.N = (A & $80)

*/

.macro ASRA() {

    // tmp = original A
    lda A_Register
    sta tmp

    // Carry = bit 0
    lda tmp
    and #$01
    sta Flags

    // shifted = tmp >> 1
    lda tmp
    lsr
    sta A_Register        // store shifted result

    // restore sign bit
    lda tmp
    and #$80              // isolate sign bit
    ora A_Register        
    sta A_Register

    // Update Z flag (bit1)
    lda A_Register
    bne !nz+
    lda Flags
    ora #%00000010
    sta Flags
    jmp !zdone+
!nz:
    lda Flags
    and #%11111101
    sta Flags
!zdone:

    // Update N flag (bit2)
    lda A_Register
    and #$80
    beq !clear_n+
    lda Flags
    ora #%00000100
    sta Flags
    jmp !done+
!clear_n:
    lda Flags
    and #%11111011
    sta Flags
!done:
}


.macro LDA(addr) {
    lda addr
    sta A_Register
}

// Branch Macros

.macro BCS(label) {
    lda Flags
    and #1
    lbne label
}

.macro BCC(label) {
    lda Flags
    and #1
    lbeq label
}

.macro BNE(label) {
	lda Flags
	and #%00000010
	lbeq label
}

.macro BEQ(label) {
	lda Flags
	and #%00000010
	lbne label
}

// if X >= addr then branch
.macro BR_IF_X_GE(addr, label) {
    lda X_H
    cmp #>addr
    bne !cmpdone+
    lda X_L
    cmp #<addr
!cmpdone:
    bcs label
}

// Branch to label if U < imm16  (matches 6809: CMPU / BCS)
.macro BR_IF_U_LT(imm, label) {
    lda U_H
    cmp #>imm
    lbcc label          // U_H < imm_H  => U < imm
    bne !done+         // U_H > imm_H  => U > imm
    lda U_L
    cmp #<imm
    lbcc label          // U_L < imm_L  => U < imm
!done:
}

// Branch to label if U != imm16
.macro BR_IF_U_NE(imm, label) {
    lda U_H
    cmp #>imm
    bne label
    lda U_L
    cmp #<imm
    bne label
}


.macro LDU(addr) {
    lda #<addr
    sta U_L
    lda #>addr
    sta U_H
}

.macro LDD(imm) {
	lda #>imm
	sta A_Register
	lda #<imm
	sta B_Register
}

.macro LDD_X() {
	ldy #0
	lda (X_L),y
	sta A_Register
	iny
	lda (X_L),y
	sta B_Register
}

.macro LDD_Y_OFF(off) {
	clc
	lda Y_L
	adc #<off
	sta byte_5
	lda Y_H
	adc #>off
	sta byte_6

	ldy #$00
	lda (byte_5),y
	sta A_Register
	iny
	lda (byte_5),y
	sta B_Register
}

.macro LDY(addr) {
	pha
    lda #<addr
    sta Y_L
    lda #>addr
    sta Y_H
	pla
}

.macro LDX(addr) {
	pha
    lda #<addr
    sta X_L
    lda #>addr
    sta X_H
	pla
}

.macro ASLB() {
	pha
	lda B_Register
	asl
	sta B_Register
	pla
}



// Arithmetic

.macro ADDX(imm) {
	pha
    clc
    lda X_L
    adc #<imm
    sta X_L
    lda X_H
    adc #>imm
    sta X_H
	pla
}

.macro ADDY(imm) {
	pha
    clc
    lda Y_L
    adc #<imm
    sta Y_L
    lda Y_H
    adc #>imm
    sta Y_H
	pla
}


// U += imm16
.macro ADDU(imm) {
	pha
    clc
    lda U_L
    adc #<imm
    sta U_L
    lda U_H
    adc #>imm
    sta U_H
	pla
}


.macro DEX16() {
	pha
	lda X_L
	bne !+
	dec X_H
!:
	dec X_L
	pla
}

.macro INC16(lo,hi) {
	inc lo
	bne !+
	inc hi
!:
}

.macro DEC_Y(off) {
	pha
	ldy #off
	lda (Y_L),y
	sec
	sbc #$01
	sta (Y_L),y

	tax                    // save result in X

	// preserve carry only
	lda Flags
	and #%00000001
	sta Flags

	txa
	bne !not_zero+
	lda Flags
	ora #%00000010         // Z
	sta Flags
!not_zero:

	txa
	and #%10000000
	beq !not_negative+
	lda Flags
	ora #%00000100         // N
	sta Flags
!not_negative:
	pla
}

.macro DEC_U(off) {
	pha
	ldy #off
	lda (U_L),y
	sec
	sbc #$01
	sta (U_L),y

	tax
	lda Flags
	and #%00000001
	sta Flags

	txa
	bne !+
	lda Flags
	ora #%00000010
	sta Flags
!:
	txa
	and #%10000000
	beq !+
	lda Flags
	ora #%00000100
	sta Flags
!:
	pla
}

.macro DEC_B() {
	pha
	lda B_Register
	sec
	sbc #$01
	sta B_Register

	tax
	lda Flags
	and #%00000001
	sta Flags

	txa
	bne !+
	lda Flags
	ora #%00000010
	sta Flags
!:
	txa
	and #%10000000
	beq !+
	lda Flags
	ora #%00000100
	sta Flags
!:
	pla
}

.macro DEC_A() {
	pha
	lda A_Register
	sec
	sbc #$01
	sta A_Register

	tax
	lda Flags
	and #%00000001
	sta Flags

	txa
	bne !+
	lda Flags
	ora #%00000010
	sta Flags
!:
	txa
	and #%10000000
	beq !+
	lda Flags
	ora #%00000100
	sta Flags
!:
	pla
}

.macro DEC_Y_NEG(off) {
	pha

	sec
	lda Y_L
	sbc #off
	sta byte_5
	lda Y_H
	sbc #$00
	sta byte_6

	ldy #$00
	lda (byte_5),y
	sec
	sbc #$01
	sta (byte_5),y

	tax
	lda Flags
	and #%00000001
	sta Flags

	txa
	bne !+
	lda Flags
	ora #%00000010
	sta Flags
!:
	txa
	and #%10000000
	beq !+
	lda Flags
	ora #%00000100
	sta Flags
!:
	pla
}



.macro MUL() {
	// 6809 MUL
	// in : A_Register * B_Register
	// out: A_Register:B_Register = 16-bit result
	//      A_Register = hi, B_Register = lo
	//
	// uses: byte_40-byte_44

	lda A_Register
	sta byte_40          // multiplier

	lda B_Register
	sta byte_41          // multiplicand lo

	lda #$00
	sta byte_42          // multiplicand hi
	sta byte_43          // result lo
	sta byte_44          // result hi

    ldx #$08
!loop:
	lsr byte_40
	bcc !skip+

	clc
	lda byte_43
	adc byte_41
	sta byte_43

	lda byte_44
	adc byte_42
	sta byte_44

!skip:
	asl byte_41
	rol byte_42

	dex
	bne !loop-

	lda byte_44
	sta A_Register
	lda byte_43
	sta B_Register
}

.macro LEAU_SUB(val) {
	sec
	lda U_L
	sbc #<val
	sta U_L
	lda U_H
	sbc #>val
	sta U_H
}


// Memory operations


.macro CLRA() {
	pha
	lda #$00
	sta A_Register

	// C=0, Z=1, N=0
	lda #$02
	sta Flags
	pla
}
.macro CLRB() {
	lda #$00
	sta B_Register
}


.macro DAA_A() {
    cmp #$0a
    bcc !no_low+
    clc
    adc #$06
!no_low:
    cmp #$a0
    bcc !done+
    clc
    adc #$60
!done:
}

.macro TFR_A_B() {
	lda A_Register
	sta B_Register
}

.macro TFR_B_A() {
	lda B_Register
	sta A_Register
}

.macro TFR_U_X() {
	pha
	lda U_L
	sta X_L
	lda U_H
	sta X_H
	pla
}

.macro TFR_Y_U() {
	pha
	lda Y_L
	sta U_L
	lda Y_H
	sta U_H
	pla
}

.macro INC_A() {
	pha
	lda A_Register
	clc
	adc #$01
	sta A_Register

	tax
	lda Flags
	and #%00000001
	sta Flags

	txa
	bne !+
	lda Flags
	ora #%00000010
	sta Flags
!:
	txa
	and #%10000000
	beq !+
	lda Flags
	ora #%00000100
	sta Flags
!:
	pla
}

.macro INC_B() {
	pha
	lda B_Register
	clc
	adc #$01
	sta B_Register

	tax
	lda Flags
	and #%00000001
	sta Flags

	txa
	bne !+
	lda Flags
	ora #%00000010
	sta Flags
!:
	txa
	and #%10000000
	beq !+
	lda Flags
	ora #%00000100
	sta Flags
!:
	pla
}


.macro INC_U(off) {
	pha
	ldy #off
	lda (U_L),y
	clc
	adc #$01
	sta (U_L),y

	tax
	lda Flags
	and #%00000001
	sta Flags

	txa
	bne !+
	lda Flags
	ora #%00000010
	sta Flags
!:
	txa
	and #%10000000
	beq !+
	lda Flags
	ora #%00000100
	sta Flags
!:
	pla
}

.macro INC_Y(off) {
	pha
	ldy #off
	lda (Y_L),y
	clc
	adc #$01
	sta (Y_L),y

	pha                    /* save result */
	lda Flags
	and #%00000001         /* keep carry only */
	sta Flags
	pla                    /* restore result */

	cmp #$00
	bne !not_zero+
	lda Flags
	ora #%00000010
	sta Flags
!not_zero:
	cmp #$80
	bcc !not_negative+
	lda Flags
	ora #%00000100
	sta Flags
!not_negative:
	pla
}

.macro INX16() {
	inc X_L
	bne !+
	inc X_H
!:
}

.macro INY16() {
	inc Y_L
	bne !+
	inc Y_H
!:
}

.macro INC_U_NEG(off) {
	pha
	sec
	lda U_L
	sbc #off
	sta byte_5
	lda U_H
	sbc #$00
	sta byte_6

	ldy #$00
	lda (byte_5),y
	clc
	adc #$01
	sta (byte_5),y

	tax
	lda Flags
	and #%00000001
	sta Flags

	txa
	bne !+
	lda Flags
	ora #%00000010
	sta Flags
!:
	txa
	and #%10000000
	beq !+
	lda Flags
	ora #%00000100
	sta Flags
!:
	pla
}

.macro INC_Y_NEG(off) {
	pha

	/* compute Y - off */
	sec
	lda Y_L
	sbc #off
	sta byte_5
	lda Y_H
	sbc #$00
	sta byte_6

	/* increment */
	ldy #$00
	lda (byte_5),y
	clc
	adc #$01
	sta (byte_5),y

	/* update 6809-style flags: Z / N (C unchanged) */
	tax
	lda Flags
	and #%00000001
	sta Flags

	txa
	bne !+
	lda Flags
	ora #%00000010
	sta Flags
!:
	txa
	and #%10000000
	beq !+
	lda Flags
	ora #%00000100
	sta Flags
!:
	pla
}



.macro CMPU(val) {
    // compare U with val, set Flags bit0 like 6809 C
    // C6809 = 1 if U < val, else 0

    // first compare high
	pha
    lda U_H
    cmp #>val
    bcc !u_less+          // U_H < const_H → U < val
    bne !u_greater+       // U_H > const_H → U > val

    // high equal → compare low
    lda U_L
    cmp #<val
    bcc !u_less+          // U_L < const_L → U < val

    // U >= val
!u_greater:
    lda #0
    sta Flags
    jmp !done+

!u_less:
    lda #1
    sta Flags

!done:
	pla
}

.macro CMPX(val) {
	pha
	lda X_H
	cmp #>val
	bcc !x_less+
	bne !x_greater+

	lda X_L
	cmp #<val
	bcc !x_less+
	bne !x_greater+

	/* equal */
	lda #%00000010
	sta Flags
	jmp !done+

!x_greater:
	lda #$00
	sta Flags
	jmp !done+

!x_less:
	lda #%00000001
	sta Flags

!done:
	pla
}

.macro CMPY(val) {
	pha
	lda Y_H
	cmp #>val
	bcc !y_less+
	bne !y_greater+

	lda Y_L
	cmp #<val
	bcc !y_less+
	bne !y_greater+

	/* equal */
	lda #%00000010
	sta Flags
	jmp !done+

!y_greater:
	lda #$00
	sta Flags
	jmp !done+

!y_less:
	lda #%00000001
	sta Flags

!done:
	pla
}

.macro CMPA_U_NEG(off) {
	sta tmp

	sec
	lda U_L
	sbc #off
	sta byte_5
	lda U_H
	sbc #$00
	sta byte_6

	ldy #$00
	lda tmp
	cmp (byte_5),y
}

.macro CMPB_U_NEG(off) {
	sta tmp+1              /* preserve host A */

	lda B_Register
	sta tmp

	sec
	lda U_L
	sbc #off
	sta byte_5
	lda U_H
	sbc #$00
	sta byte_6

	ldy #$00
	lda tmp
	cmp (byte_5),y

	/* do NOT restore A here if caller branches on native flags */
}


// FB = X + (SPRITE_RAM2 - SPRITE_RAM1), but PRESERVE A
.macro SYNC_FB_FROM_X_PRESERVE_A() {
    sta tmp
    clc
    lda X_L
    adc #<(SPRITE_RAM2 - SPRITE_RAM1)
    sta FB_L
    lda X_H
    adc #>(SPRITE_RAM2 - SPRITE_RAM1)
    sta FB_H
    lda tmp
}


// maps 6809: sta $400,x   (sprite RAM2 byte0)
.macro STA_SPR2_0() {
    ldx X_L
    sta SPRITE_RAM2,x
}

// maps 6809: sta $401,x   (sprite RAM2 byte1)
.macro STA_SPR2_1() {
    ldx X_L
    sta SPRITE_RAM2+1,x
}

// maps 6809: sta ,x+      (sprite RAM1 write + increment absolute X pointer)
.macro STA_SPR1_POSTINC() {
    ldx X_L
    sta SPRITE_RAM1,x

    inc X_L
    bne !+
    inc X_H
!:
}


.macro STD_ZERO_POSTINC_X() {
    lda #0
    ldy #0
    sta (X_L),y
    iny
    sta (X_L),y
    INC16(X_L, X_H)
    INC16(X_L, X_H)
}

.macro STA_X_OFFS(offs) {
    pha
    clc
    lda X_L
    adc #<offs
    sta byte_5
    lda X_H
    adc #>offs
    sta byte_6
    pla
    ldy #0
    sta (byte_5),y
}

.macro STD_U_NEG(off) {
	sec
	lda U_L
	sbc #off
	sta byte_5
	lda U_H
	sbc #$00
	sta byte_6

	ldy #$00
	lda A_Register
	sta (byte_5),y
	iny
	lda B_Register
	sta (byte_5),y
	}

.macro STD_PTR(ptrlo) {
    ldy #0
    lda A_Register
    sta (ptrlo),y
    iny
    lda B_Register
    sta (ptrlo),y
}

.macro LEAY_NEG_TO_TMP(off) {
	pha
	sec
	lda Y_L
	sbc #off
	sta byte_5
	lda Y_H
	sbc #$00
	sta byte_6
	pla
}

.macro LEAU_NEG_TO_TMP(off) {
	pha
	sec
	lda U_L
	sbc #off
	sta byte_5
	lda U_H
	sbc #$00
	sta byte_6
	pla
}

.macro LDA_Y_NEG(off) {
	LEAY_NEG_TO_TMP(off)
	ldy #$00
	lda (byte_5),y
}

.macro LDB_Y_NEG(off) {
	pha
	LEAY_NEG_TO_TMP(off)
	ldy #$00
	lda (byte_5),y
	sta B_Register

	/* update flags like 6809 LDB */
	tax
	lda Flags
	and #%00000001        /* preserve carry */
	sta Flags

	txa
	bne !+
	lda Flags
	ora #%00000010        /* Z */
	sta Flags
!:
	txa
	and #%10000000
	beq !+
	lda Flags
	ora #%00000100        /* N */
	sta Flags
!:
	pla
}


.macro LDA_U_NEG(off) {
	pha
	sec
	lda U_L
	sbc #off
	sta byte_5
	lda U_H
	sbc #$00
	sta byte_6
	ldy #$00
	lda (byte_5),y
	sta A_Register

	/* update emulated flags: Z / N, C unchanged */
	tax
	lda Flags
	and #%00000001
	sta Flags

	txa
	bne !+
	lda Flags
	ora #%00000010
	sta Flags
!:
	txa
	and #%10000000
	beq !+
	lda Flags
	ora #%00000100
	sta Flags
!:	
	pla
}

.macro LDB_U_NEG(off) {
	pha
	sec
	lda U_L
	sbc #off
	sta byte_5
	lda U_H
	sbc #$00
	sta byte_6
	ldy #$00
	lda (byte_5),y
	sta B_Register
	pla
}

.macro STA_Y_NEG(off) {
	LEAY_NEG_TO_TMP(off)
	ldy #$00
	lda A_Register
	sta (byte_5),y
}

.macro STB_Y_NEG(off) {
	LEAY_NEG_TO_TMP(off)
	ldy #$00
	lda B_Register
	sta (byte_5),y
}

.macro STD_Y_NEG(off) {
	
    sec
    lda Y_L
    sbc #off
    sta byte_5
    lda Y_H
    sbc #$00
    sta byte_6

    ldy #$00
    lda A_Register
    sta (byte_5),y
    iny
    lda B_Register
    sta (byte_5),y
}

.macro STA_U_NEG(off) {
	pha
	sec
	lda U_L
	sbc #off
	sta byte_5
	lda U_H
	sbc #$00
	sta byte_6
	pla
	ldy #$00
	sta (byte_5),y
}

.macro CLR_U_NEG(off) {
	CLRA()
	STA_U_NEG(off)
}

.macro CLR_Y(off) {
	pha
	ldy #off
	lda #$00
	sta (Y_L),y
	lda #$02
	sta Flags
	pla
}

.macro CLR_Y_NEG(off) {
	pha
	sec
	lda Y_L
	sbc #off
	sta byte_5
	lda Y_H
	sbc #$00
	sta byte_6

	ldy #$00
	lda #$00
	sta (byte_5),y

	/* 6809 CLR flags: C=0, Z=1, N=0 */
	lda #$02
	sta Flags
	pla
}

.macro TST_Y_NEG(off) {
	sec
	lda Y_L
	sbc #off
	sta byte_5
	lda Y_H
	sbc #$00
	sta byte_6

	ldy #$00
	lda (byte_5),y

	/* update 6809 flags: Z / N, C unchanged */
	tax
	lda Flags
	and #%00000001
	sta Flags

	txa
	bne !+
	lda Flags
	ora #%00000010
	sta Flags
!:
	txa
	and #%10000000
	beq !+
	lda Flags
	ora #%00000100
	sta Flags
!:

}


// other helpers


// ------------------------------------------------------------
// 32-bit helpers - for access rom data in bank 1,2, 3 ..etc
// ------------------------------------------------------------

.macro LD32_IMM(ptrLo, addr) {
	lda #<addr
	sta ptrLo
	lda #>addr
	sta ptrLo+1
	lda #((addr >> 16) & $ff)
	sta ptrLo+2
	lda #((addr >> 24) & $ff)
	sta ptrLo+3
}

.macro LD32_BASE_PLUS_16(ptrLo, base, off16) {
	pha
	clc
	lda #<base
	adc off16
	sta ptrLo

	lda #>base
	adc off16+1
	sta ptrLo+1

	lda #((base >> 16) & $ff)
	adc #$00
	sta ptrLo+2

	lda #((base >> 24) & $ff)
	adc #$00
	sta ptrLo+3
	pla
}

.macro ADD32_IMM(ptrLo, val) {
	pha
	clc
	lda ptrLo
	adc #<val
	sta ptrLo
	lda ptrLo+1
	adc #>val
	sta ptrLo+1
	lda ptrLo+2
	adc #((val >> 16) & $ff)
	sta ptrLo+2
	lda ptrLo+3
	adc #((val >> 24) & $ff)
	sta ptrLo+3
	pla
}

.macro ADD16_MEM(addr, val) {
	pha
	clc
	lda addr
	adc #<val
	sta addr

	lda addr+1
	adc #>val
	sta addr+1
	pla
}

.macro ADDY_D() {
	clc
	lda Y_L
	adc B_Register
	sta Y_L
	lda Y_H
	adc A_Register
	sta Y_H
}


