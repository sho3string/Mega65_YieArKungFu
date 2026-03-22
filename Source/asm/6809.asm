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

	
	
// register operations, load, store ..etc
	
.macro CLRB() {
    pha
    lda #0
    sta B_Register

    // Z=1, N=0, C unchanged
    lda Flags
    and #%00000001      // keep carry only
    ora #%00000010      // set Z
    sta Flags
    pla
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
    beq label
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

.macro LDY(addr) {
    lda #<addr
    sta Y_L
    lda #>addr
    sta Y_H
}

.macro LDX(addr) {
    lda #<addr
    sta X_L
    lda #>addr
    sta X_H
}

.macro INC16(lo,hi) {
    inc lo
    bne !+
    inc hi
!:
}

.macro ADDX(imm) {
    clc
    lda X_L
    adc #<imm
    sta X_L
    lda X_H
    adc #>imm
    sta X_H
}

.macro ADDY(imm) {
    clc
    lda Y_L
    adc #<imm
    sta Y_L
    lda Y_H
    adc #>imm
    sta Y_H
}


// U += imm16
.macro ADDU(imm) {
    clc
    lda U_L
    adc #<imm
    sta U_L
    lda U_H
    adc #>imm
    sta U_H
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

.macro CMPU(val) {
    // compare U with val, set Flags bit0 like 6809 C
    // C6809 = 1 if U < val, else 0

    // first compare high
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
}

.macro CMPX(val) {
    lda X_H
    cmp #>val
    bcc !x_less+
    bne !x_greater+

    lda X_L
    cmp #<val
    bcc !x_less+

!x_greater:
    lda #0
    sta Flags
    jmp !done+

!x_less:
    lda #1
    sta Flags

!done:
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
