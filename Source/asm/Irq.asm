
*=* "Irq handler - Irq.asm"


irq_handler:
    pha
    phx
    phy
    phz

    lda vicii_irq
    and #$01
    beq noIrq
	
	//lda RRB_FramePhase
    //eor #1
    //sta RRB_FramePhase
	
    // ACK IMMEDIATELY
    lda #$01
    sta vicii_irq
	
	//lda #$02
	//sta $d020  // start work colour
    jsr loc_897d
    //lda #$00
	//sta $d020  // end work colour
  
noIrq:
    plz
    ply
    plx
    pla
    rti
	
//nmi_handler:
//    rti


