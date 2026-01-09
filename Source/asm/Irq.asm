
*=* "Irq handler - Irq.asm"

/*
irq_handler:
    pha
    // Test for raster IRQ
    lda vicii_irq
    bit #$01
    beq noIrq  // not raster IRQ

    // Acknowledge raster IRQ
    lda #$01  // write a 1 to bit 0
    sta vicii_irq

    // White border bar from 100 to 200
    lda vicii_rcl
    cmp #101
    bcs whiteBorder

    // This is the raster interrupt for line 100.
    // Set the raster interrupt position to 200.
    lda #200
    sta vicii_rcl
    lda #$0f  // white
    sta $d020
    bra noIrq

    // This is the raster interrupt for line 200.
    // Set the raster interrupt position to 100.
whiteBorder:
    lda #100
    sta vicii_rcl
    lda #0  // black
    sta $d020

noIrq:
    pla
    rti
	
nmi_handler:
    rti
*/


irq_handler:
    pha
    phx
    phy
    phz
    // Test for raster IRQ
    lda vicii_irq
    bit #$01
    beq noIrq  // not raster IRQ

    // White border bar from 248 to 249
    lda vicii_rcl
    cmp #249
    bcs whiteBorder

    // This is the raster interrupt for line 248
    // Set the raster interrupt position to 249
    lda #249
    sta vicii_rcl
    lda #$0f
    sta $d020
    bra noIrq

    // This is the raster interrupt for line 249
    // Set the raster interrupt position to 248
whiteBorder:
    lda #248
    sta vicii_rcl
    lda #0  // black
    sta $d020
	
/************
*VBL ROUTINE*
************/	
	// VBI routine.
	jsr	loc_897d	
	 // Acknowledge raster IRQ
    lda #$01  // write a 1 to bit 0
    sta vicii_irq

noIrq:
    plz
    ply
    plx
    pla
    rti
	
//nmi_handler:
//    rti


