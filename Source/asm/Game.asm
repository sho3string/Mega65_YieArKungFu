

*=* "Game Code - Game.asm"

loc_8000:
	// byte_0 = pointer low
	// byte_1 = pointer high
	// byte_2 = low byte of D (B)
	// byte_3 = high byte of D (A)

	// X starts at $5000
	lda #<SPRITE_RAM1
	sta byte_0
	lda #>SPRITE_RAM1
	sta byte_1
	
	lda #$00
	sta byte_2
	lda #$00
	sta byte_3
	ldy #0
loc_8005:
    // store high byte (A)
    lda byte_3
    sta (byte_0),y

    // store low byte (B)
    lda byte_2
    iny
    sta (byte_0),y
    dey

    // increment pointer by 2
    clc
    lda byte_0
    adc #2
    sta byte_0
    lda byte_1
    adc #0
    sta byte_1

    // compare pointer to $5700
    lda byte_1
    cmp #>WORK_RAM2 + $2D0
    bcc loc_8005
    bne loc_800f
    lda byte_0
    cmp #<WORK_RAM2 + $2D0
    bcc loc_8005
	
loc_800f:
	lda #<WORK_RAM1
	sta byte_0
	lda #>WORK_RAM1
	sta byte_1
	
	lda #$00
	sta byte_2
	lda #$00
	sta byte_3
	ldy #0
loc_8012:
	 // store high byte (A)
    lda byte_3
    sta (byte_0),y

    // store low byte (B)
    lda byte_2
    iny
    sta (byte_0),y
    dey

    // increment pointer by 2
    clc
    lda byte_0
    adc #2
    sta byte_0
    lda byte_1
    adc #0
    sta byte_1

    // compare pointer to $5730
    lda byte_1
    cmp #>WORK_RAM2 + $300
    bcc loc_8012
    bne loc_801c
    lda byte_0
    cmp #<WORK_RAM2 + $300
    bcc loc_8012

loc_801c:
	lda #$ff // kludge Flip Screen Off, Single controls, Service Mode Off
	and #$4
	bne loc_802e	
	
/******************
* Test Mode       *
******************/

/*******************
* Game Mode        *
*******************/

/*******************
*Crosshatch Pattern*
*******************/
loc_802e:
	jsr	sub_8218	// draws the crosshatch

/***************************************
* Sets up variables                    *
* at 52c0, 52c2.. etc                  *
* Reads dip switches for lives..etc    *
***************************************/

loc_8031:
	lda #<CMD_QUEUE // low byte
    sta byte_d8
    sta byte_da
	sta byte_f0	 // use a separate temp pointer to walk 52C0..52FE

    lda #>CMD_QUEUE // high byte
    sta byte_d9
    sta byte_db
	sta byte_f1	 // use a separate temp pointer to walk 52C0..52FE

	
	lda #$ff
    sta byte_0
    sta byte_1

    ldy #0
loc_803b:
    // store low byte
    lda #$FF
    sta (byte_f0),y

    // store high byte
    iny
    lda #$FF
    sta (byte_f0),y
    dey

    // increment pointer by 2
    clc
    lda byte_f0
    adc #2
    sta byte_f0
    lda byte_f1
    adc #0
    sta byte_f1

    // compare pointer to CMD_QUEUE+$40 ($8300)
    lda byte_f1
    cmp #>(CMD_QUEUE + $40)
    bcc loc_803b
    bne loc_8042
    lda byte_f0
    cmp #<(CMD_QUEUE + $40)
    bcc loc_803b

loc_8042:
    // store low byte first, then high byte (6502 pointer order)
    lda #<(CMD_QUEUE + $40)
    sta byte_dc      // $DC low
    sta byte_de      // $DE low
    lda #>(CMD_QUEUE + $40)
    sta byte_dd      // $DD high
    sta byte_df      // $DF high

	// clear word_5606+1  (i.e., $5607)
    lda #$00
    sta WORK_RAM2 + $1d7
	// clear word_5608 (low byte)
    sta WORK_RAM2 + $1d8
	// Read DIPs
	jsr sub_80c5
	// Sets options to flip Screen
	jsr sub_80b5  
    lda byte_c3
    beq loc_8062          // if zero, skip
    // D8 = $52C0
    lda #<CMD_QUEUE
    sta byte_d8
    lda #>CMD_QUEUE
    sta byte_d9
    // store $FFFF at $52C0
    lda #$FF
    sta CMD_QUEUE
    sta CMD_QUEUE+1
    // store $FFFF at $52C2
    sta CMD_QUEUE+2
    sta CMD_QUEUE+3
	
/**************************
* Set up IRQs on Arcade   *
* RST = 0x8163  - 0xfff0  *
* NMI = 0xC78E  - 0xfffc  *
* SRQ = 0x8163  - 0xfffa  *
* IRQ = 0x897D VBL 0xfff8 *
**************************/

loc_8062:
    // A = word_5600 low byte (6809 loads 16-bit, but only A is used)
    lda SPRITE_RAM2+$200
    jsr sub_86d7 // (ROM→RAM high score copy)
    //jsr sub_C737 (sound/speech init) - Look at this later
    // B = 6 → A = 6
	
	//bit 1 - NMI enable   (0x02)
	//bit 2 - IRQ enable   (0x04)
    lda #$06
    // A = A XOR C1
    eor byte_c1
    // store back into C1
    sta byte_c1
	
/***********************************
*0x4000 W  control port            *
*bit 0 - flip screen			0x1   *
*bit 1 - NMI enable			0x2   *
*bit 2 - IRQ enable			0x4   *
*bit 3 - coin counter A		0x8   *
*bit 4 - coin counter B		0x10  *
***********************************/

	sta byte_4000_shadow
	
/*******************************
* Set up our interrupt handler *
*******************************/
	ldx #<irq_handler
	stx hw_irq_vec
	ldy #>irq_handler
	sty hw_irq_vec+1

	lda #248        		 // raster interrpupt at line 248
	sta vicii_rcl  		 // raster compare
	lda #%00000001
	sta vicii_irqmask      // enable raster IRQ
	cli				 		// enable interrupts*/
	
	

/*


Description: The 6809 code uses a command queue in RAM, a ring buffer at $52C0 that stores 16 bit “commands” the game engine processes one by one.

On the 6502 implementation, this queue has two pointers:
- $D8/D9 → write pointer
- $DA/DB → read pointer
Those two pointers behave exactly like:
- Producer pointer → writes new commands into the queue
- Consumer pointer → reads and processes commands from the queue


┌──────────────────────────────────────────────────────────────┐
│                     COMMAND QUEUE (RAM)                      │
│                                                              │
│   $52C0   $52C2   $52C4   $52C6   ...   $52FE   (16-bit each)│
│   ┌────┐ ┌────┐ ┌────┐ ┌────┐         ┌────┐                 │
│   │    │ │    │ │    │ │    │   ...   │    │                 │
│   └────┘ └────┘ └────┘ └────┘         └────┘                 │
│                                                              │
└──────────────────────────────────────────────────────────────┘

Producer pointer → $D8/D9
Consumer pointer → $DA/DB

*/

	
/******************
* Consumer section*
******************/

loc_807c:
	php					
	sei					// disable interrupts

	// Load X from $DA (pointer) into temp pointer byte_dc/dd
	lda byte_da	
	sta byte_7			// actually read the flag byte
	lda byte_db
	sta byte_8

	ldy #0
	lda (byte_7),y		//  derived index into d56a
	sta A_Register
	iny
	lda (byte_7),y
	sta B_Register

	lda A_Register
	asl
	bcs !busy+

	and #$7f
	sta tmp

	lda B_Register
	sta zp_cmd_param

	// A now is the (2 * index) for the jump table later
    // -----------------------------
    // Store $FFFF at [byte_da] and advance pointer by 2
    // -----------------------------
	lda #$ff
	ldy #0
	sta (byte_7),y
	iny
	sta (byte_7),y

	// X++ (by 2) and circular wrap 52C0–52FF
	clc
	lda byte_da
	adc #2
	sta byte_da
	lda byte_db
	adc #0
	sta byte_db

	// ------------------------------------------------------------
	// Wrap pointer if > $52FF  (6809: CMPX #$52FF / BLS)
	// ------------------------------------------------------------
	
	lda byte_db
	cmp #>CMD_QUEUE			// 0x52c0
	bcc !ptr_ok+			// < $52xx → OK
	bne !wrap+				 // > $52xx → wrap
	
	// high byte == $52, check low
	lda byte_da
	cmp #<CMD_QUEUE+$3f		// c0+$3f = 0xff.
	bcc !ptr_ok+			// < $52FF → OK
	beq !ptr_ok+			// == $52FF → OK

!wrap:
	lda #<CMD_QUEUE
	sta byte_da
	lda #>CMD_QUEUE
	sta byte_db

!ptr_ok:
	plp

	// pointer already stored in byte_da/db
	// X already = 0,2,4,6 from and #$7F / tax
	
	// fake return address for RTS -> loc_807c
	lda #>(loc_807c-1)
	pha
	lda #<(loc_807c-1)
	pha

	ldx tmp
	lda d562,x
	sta byte_25
	lda d562+1,x
	sta byte_26
	jmp (byte_25)

!busy:
	plp
	jmp loc_807c
	

/******************
* Producer section*
******************/
	
sub_80a1:
	lda #$00
	sta byte_f3

loc_80a2:
	/* pshs x */
	pha
	txa

	/* ldx $D8 → into temp pointer */
	lda byte_d8
	sta byte_f0
	lda byte_d9
	sta byte_f1

	/* std ,x++ */
	ldy #0
	lda byte_f3
	sta (byte_f0),y
	iny
	lda byte_f2
	sta (byte_f0),y

	/* x += 2 */
	clc
	lda byte_f0
	adc #2
	sta byte_f0
	lda byte_f1
	adc #0
	sta byte_f1

	/* cmpx #$5300 */
	lda byte_f1
	cmp #>(WORK_RAM1+$2d0)
	bcc store_ptr
	bne wrap_ptr
	lda byte_f0
	cmp #<(WORK_RAM1+$2d0)
	bcc store_ptr

wrap_ptr:
	lda #<CMD_QUEUE
	sta byte_f0
	lda #>CMD_QUEUE
	sta byte_f1

store_ptr:
	lda byte_f0
	sta byte_d8
	lda byte_f1
	sta byte_d9

	/* puls x */
	pla
	tax
	rts
	
sub_80b5:
    lda #$00
    sta byte_c8        // default: no flip

    lda byte_f0
    and #$01
    beq loc_80bd

    lda #$01
    sta byte_c8        // flip enabled

loc_80bd:
    jsr sub_842c   	// check cocktail mode
    lda byte_c1        // return value
    rts


/****************************************
* sub_80C5 — DIP switch stub for MEGA65 *
****************************************/
sub_80c5:

// Hard coded DIP values (same as Amiga version I toyed with)
// EE = ~FF = 00
// EF = ~58 = A7
// F0 = ~FF = 00

	//lda #$f0 - This is FreePlay mode - Coin A.
    lda #$FF		 //  DSW #2 0x4e03
    eor #$FF        // invert
    sta byte_ee
	
	// 5 lives, Upright, Bonus 30000 & 80000, Normal, Attract sounds on
    lda #$58		//  DSW #0 0x4c00
    eor #$FF
    sta byte_ef

	// Flip Screen Off, Single controls, Service Mode Off
    lda #$FF		//  DSW #1 0x4d00
    eor #$FF
    sta byte_f0

/****************************************
* Now reproduce the arcade logic:       *
* EE & $0F → index into table at $D412  *
****************************************/

    lda byte_ee
    and #$0F        // low nibble
    asl             // ×2 (word index)
    tax             // X = offset into table

    lda d412,x     // low byte
    sta byte_e7
    lda d412+1,x   // high byte
    sta byte_e8

// If the 16 bit value is zero, increment $520F
    lda byte_e7
    ora byte_e8
    bne loc_80e8
    inc WORK_RAM1 + $1DF // word_520E+1

loc_80e8:

/**************************************
*EE upper nibble → D412 lookup → EC/ED*
**************************************/

    lda byte_ee
    and #$f0
    lsr
    lsr
    lsr            // A = (EE >> 4)
    tax            // X = index * 1 (but table is words)

    lda d412,x     // low byte
    sta byte_ec
    lda d412+1,x   // high byte
    sta byte_ed

    lda byte_ec
    ora byte_ed
    bne loc_80fb
    inc WORK_RAM1 + $1DF  // word_520E+1

loc_80fb:

/*********************************
*EF low 2 bits → D432 lookup → C9*
*********************************/
	// get lives from $EF
    lda byte_ef
    and #$03
    tax
    lda d432,x
	// store actual lives in C9
    sta byte_c9

/*****************************************
*EF bit 3 → ASCII pairs → CB/CC and CD/CE*
*****************************************/

    lda byte_ef	// 0xa7 when game set to 5 lives, Upright, Bonus 30000 & 80000, Normal, Attract sounds on.
    and #$08       // isolate bit 3
    asl            // shift left once
    tay            // Y = 0 or 16

    // ---- store 00 YY+30 into CB/CC ----
    lda #$00
    sta byte_cb    // high byte = 00
    tya
    clc
    adc #$30       // low byte = 30 or 40
    sta byte_cc

	// ---- store 00 YY+80 into CD/CE ----
    lda #$00
    sta byte_cd   // high byte = 00
    tya
    clc
    adc #$80      // low byte = 80 or 90
    sta byte_ce
    rts
	
sub_8115:
    lda byte_c5
    bne loc_8129
	
/**********************************
* R=>L Clear Routine              *
* Initialization (first call only)*
***********************************/
    // Start ONE tile past the last visible column.
   // Because the step does: dec count, then ptr -= 2, then clears.
    lda #<(SCREEN_BASE + (CHARS_WIDE*2)) 
    sta byte_fd
    lda #>(SCREEN_BASE + (CHARS_WIDE*2))
    sta byte_fe

    lda #CHARS_WIDE+1     // IMPORTANT: clears (count-1) columns => 32
    sta byte_ff

    lda #1
    sta byte_ca

    inc byte_c5
    lda #1
    rts

/*****************
* R=>L clear step*
******************/
loc_8129:
	
    dec byte_ca
    bne locret_8149
	
    lda #1
    sta byte_ca

    dec byte_ff
    beq loc_814a

    // FD:FE = FD:FE - 2 (move one tile left)
	
	// :000001FD:4058
    lda byte_fd
    sec
    sbc #2
    sta byte_fd

    lda byte_fe
    sbc #0
    sta byte_fe
	

    // B = $20 (row counter) → use X as 0x20
	ldx #CHARS_WIDE
	lda byte_fd
	sta byte_f0 // back up for rows
	lda byte_fe
	sta byte_f1 // back up for rows


loc_813f:
	ldy #0
	
	lda #$10				// tile number
	clc
	adc #<(TILE_OFFSET)
	sta (byte_f0),y
	iny
	lda #$00
	clc
	adc #>(TILE_OFFSET)
	sta (byte_f0),y
	

	// tmp_ptr = tmp_ptr + $40 (next row)
	lda byte_f0
    clc
    adc #<LINESTEP_BYTES
    sta byte_f0
    lda byte_f1
    adc #>LINESTEP_BYTES
    sta byte_f1

	dex
	bne loc_813f
	

locret_8149:
	
    lda #1                  // return nonzero (still clearing)
    rts

loc_814a:
    lda #0                  // return zero (finished)
    rts
	

/*************************
* Clears work RAM block  *
* $5030-$51AF            *
*************************/
sub_814c:
    LDX(WORK_RAM1)          // emulated 6809 X = $5030
loc_8152:
	lda #$00
    ldy #0
    sta (X_L),y             // first byte of STD ,x++
    iny
    sta (X_L),y             // second byte of STD ,x++

    INC16(X_L, X_H)         // x++
    INC16(X_L, X_H)         // x++ again  => total +2

    CMPX(WORK_RAM1 + $180)  // compare against $51B0
    BCS(loc_8152)           // 6809 BCS = branch while X < end
    rts

/************************************
* loc_8163  - RST vector         	*
************************************/

loc_8163:
	sei                    //disable interrupts
	cld
	ldx #$ff
	txs						// set stack pointer to $ff
	jsr sub_c81b			// not implemented yet, not sure what this is.
	//bcs	loc_8172		// no flip.
loc_8172:                               
	ldx     #0

loc_8175:
	//sta     $4F00
	//sta     $4000
	//leax    1,x
	//bne     loc_8175
	//lda     #$51 // 'Q'
	//tfr     a, dp
	// clra
	lda #$0

/*******************************
* Ram Test - wont implement yet*
********************************

loc_8184:
loc_8187:
loc_819B:
loc_81A1:
loc_81BA:
loc_81BF:
loc_81DD:

/*******END OF HARDWARE TESTS********/

loc_81ec:
	jsr	sub_820c					//pause on software/hw tests.
	jsr	sub_821a					//clear ram
	jmp	loc_8000					//setup, crosshatch

sub_820c:
loc_820f:
    lda #$00
    sta byte_0
    sta byte_1
delay_loop:
    //MUL substitute (11 cycles on 6809)
    nop
    nop
    nop
    nop
    //16-bit decrement
    dec byte_0
    bne delay_loop
    dec byte_1
    bne delay_loop
    rts


/*************************************
* Set crosshatch 						 *
*************************************/

// byte_0 = pointer low
// byte_1 = pointer high
// byte_2 = B register

sub_8218:
    lda #$2e
    sta byte_2          // Crosshatch value
	
/*************************************
* Clear RAM							 *
*************************************/

// byte_0 = pointer low
// byte_1 = pointer high
// byte_2 = tile number



// ------------------------------------------------------------
// sub_821a  (FIXED)
// Draw 32xCHARS_HIGH grid into visible 32 columns,
// then write RRB tail init for the rest of the row.
//
// Assumes:
//   SCREEN_BASE      = $2400 (or wherever)
//   VISIBLE_COLS     = 32
//   CHARS_HIGH       = 32
//   LINESTEP_BYTES   = TOTAL_CHARS * 2  (includes tail words)
//   TILE_OFFSET      = base tile page offset for screen words
//   byte_0/byte_1    = screen pointer
//   byte_2           = tile index (0..255) for crosshatch
// ------------------------------------------------------------
// Draw visible 32 cols crosshatch + init RRB tail for each row.
// Uses a streaming pointer so we never overflow Y.
// Requires: LINESTEP_BYTES = (TAIL_OFF + (RRB_PixiesPerRow*6) + 4)
// ------------------------------------------------------------

sub_821a:
    lda #<SCREEN_BASE
    sta byte_0
    lda #>SCREEN_BASE
    sta byte_1

    ldx #CHARS_HIGH

row_loop:
    // stream pointer write: always use Y=0
    ldy #0

    // -------------------------
    // visible 32 columns (64 bytes)
    // -------------------------
    ldz #CHARS_WIDE            // 32 cells

vis_loop:
    // tile lo = byte_2 + TILE_OFFSET(lo)
    lda byte_2
    clc
    adc #<TILE_OFFSET
    sta (byte_0),y
    // advance pointer by 1
    inc byte_0
    bne !+
    inc byte_1
!:
    // tile hi = TILE_OFFSET(hi) + carry
    lda #>TILE_OFFSET
    adc #0
    sta (byte_0),y
    // advance pointer by 1
    inc byte_0
    bne !+
    inc byte_1
!:
    dez
    bne vis_loop

    // -------------------------
    // tail init: RRB_PixiesPerRow slots, 6 bytes each
    // -------------------------
    phx
    ldx #RRB_PixiesPerRow

pix_loop:
    // byte 0
    lda RRB_PixieProtoType+0
    sta (byte_0),y
    inc byte_0
    bne !+
    inc byte_1
!:
    // byte 1
    lda RRB_PixieProtoType+1
    sta (byte_0),y
    inc byte_0
    bne !+
    inc byte_1
!:
    // byte 2 (tile lo + TILE_OFFSET lo)
    lda RRB_PixieProtoType+2
    clc
    adc #<TILE_OFFSET
    sta (byte_0),y
    inc byte_0
    bne !+
    inc byte_1
!:
    // byte 3 (tile hi + TILE_OFFSET hi + carry)
    lda RRB_PixieProtoType+3
    adc #>TILE_OFFSET
    sta (byte_0),y
    inc byte_0
    bne !+
    inc byte_1
!:
    // byte 4
    lda RRB_PixieProtoType+4
    sta (byte_0),y
    inc byte_0
    bne !+
    inc byte_1
!:
    // byte 5
    lda RRB_PixieProtoType+5
    sta (byte_0),y
    inc byte_0
    bne !+
    inc byte_1
!:

    dex
    bne pix_loop

    // -------------------------
    // final GOTOX (2 bytes)
    // -------------------------
    lda RRB_PixieProtoType+4
    sta (byte_0),y
    inc byte_0
    bne !+
    inc byte_1
!:
    lda RRB_PixieProtoType+5
    sta (byte_0),y
    inc byte_0
    bne !+
    inc byte_1
!:

    // -------------------------
    // dummy tile word (2 bytes) MUST match prototype tile word
    // -------------------------
    lda RRB_PixieProtoType+2
    clc
    adc #<TILE_OFFSET
    sta (byte_0),y
    inc byte_0
    bne !+
    inc byte_1
!:
    lda RRB_PixieProtoType+3
    adc #>TILE_OFFSET
    sta (byte_0),y
    inc byte_0
    bne !+
    inc byte_1
!:

    plx

    // At this point, pointer has advanced exactly one whole row:
    // 64 + (RRB_PixiesPerRow*6) + 4 bytes.
    // So byte_0/byte_1 is already at next row start.
    dex
    lbne row_loop

    rts

	
loc_8242: // from function table at D9F0, to do.
	jmp *

sub_841e:
    lda byte_ef
    and #$04
    bne sub_842c

    lda byte_e1
    beq sub_842c

    lda byte_e0
    bne loc_8436


/*************************
* Check Cocktail mode    *
*************************/
	
sub_842c:
    lda byte_c8
    bne loc_843a        // if flip option enabled, go to flip logic

/*************************************
*loc_8430 — normal mode (clear bit 0)*
**************************************/

loc_8430:
    lda byte_c1
    and #$FE            // clear bit 0
	bra loc_8443

/******************************************
*loc_8436 — unreachable in original flow  *
******************************************/

loc_8436:
    lda byte_c8
    bne loc_8430

/***************************
*loc_843A — flip mode logic*
****************************/

loc_843a:
    lda byte_c1
    lsr                  // bit 0 → carry
    bcs locret_8445     // if bit 0 already 1, return

    lda byte_c1
    eor #$01            // toggle bit 0

/****************************
*loc_8443 — store updated C1*
*****************************/
loc_8443:
    sta byte_c1

/*********************
*locret_8445 — return*
**********************/
locret_8445:
    rts	
	
/***********
* Game Over*
***********/

sub_8446: // to do
loc_844e: // to do
sub_85b3: // to do
	jmp *
	
.const zp_script_lo		= byte_0    // pointer into current text script
.const zp_script_hi		= byte_1
.const zp_tile_lo			= byte_2    // pointer into tilemap
.const zp_tile_hi			= byte_3
.const zp_script_idx		= byte_4    // index into script (offset from script base)
.const zp_glyph_index		= byte_6


loc_867e:
    lda #$1f
    sta B_Register
    jsr sub_80a1
    //LDX(SCREEN_BASE+(RRB_Tail_words*2*($1d1>>arcadeRowSize))+$1d1-1) // $59d1
	LDX(ArcadeToMegaTextByte($59d1))
	
    lda X_L
    sta byte_fd
    lda X_H
    sta byte_fe

    LDU(data_5520) 	// $5520, pointer to high score table.
    lda U_L
    sta WORK_RAM1+$1D0 // word_5200
    lda U_H
    sta WORK_RAM1+$1D1 // word_5200+1

    lda #$0a
    sta byte_ff

loc_8692:
    lda byte_fd
    sta X_L
    lda byte_fe
    sta X_H

    lda WORK_RAM1+$1D0 // word_5200
    sta U_L
    lda WORK_RAM1+$1D1 // word_5200+1
    sta U_H

    jsr sub_88c5	// prints high scores
    jsr sub_8922	// prints high scores
	
loc_869d:
	lda byte_fd
	sta X_L
	lda byte_fe
	sta X_H

	lda WORK_RAM1+$1D0 // word_5200
    sta U_L
    lda WORK_RAM1+$1D1 // word_5200+1
    sta U_H

	ADDU(1)
	ADDX($12)
	jsr sub_890f

	lda byte_fd
	sta X_L
	lda byte_fe
	sta X_H

	lda WORK_RAM1+$1D0 // word_5200
    sta U_L
    lda WORK_RAM1+$1D1 // word_5200+1
    sta U_H

	ADDX($1a)
	ADDU(4)

/****************************
*Player name high score loop*
*****************************/
    lda #10
    sta Y_L
    lda #0
    sta Y_H
loc_86b8:
    ldy #0
    lda (U_L),y          // read one name byte
    sta (X_L),y          // write to cell low byte
    ADDU(1)              // next source byte

    INC16(X_L, X_H)      // skip cell high byte
    INC16(X_L, X_H)      // next cell low byte

    dec Y_L
    bne loc_86b8

    lda byte_fd
    sta X_L
    lda byte_fe
    sta X_H
    //ADDX($80) // advance two rows.
	
	/*
	translated_row_step = $40 + (RRB_Tail_words * 2)
                    = $40 + $F4
                    = $134
					
	translated_2row_step = 2 * $134 = $268
	
	*/
	
	ADDX(($40 + (RRB_Tail_words * 2))<<1) // #$268
    lda X_L
    sta byte_fd
    lda X_H
    sta byte_fe

    lda WORK_RAM1+$1D0 // word_5200
    sta U_L
    lda WORK_RAM1+$1D1 // word_5200+1
    sta U_H
    ADDU($0e)
    lda U_L
	sta WORK_RAM1+$1D0 // word_5200
	lda U_H
	sta WORK_RAM1+$1D1 // word_5200+1
	
    dec byte_ff
    lbne loc_8692
    rts
	

/***********************************************************
* sub_86D7 – Initialise High Score Table                   *
*                                                          *
* Original arcade behaviour:                               *
* Copies the default high score table from ROM (D477 )     *
* into work RAM ($5520). This provides the initial high    *
* score entries when the machine boots.                    *
*                                                          *
* In this port this routine is unnecessary because the     *
* program is not running from a fixed ROM image and the    *
* high score table can be initialised directly in RAM      *
* (or loaded from disk/save data). Therefore this copy     *
* routine can be omitted.                                  *
************************************************************/
sub_86d7:

/************************************************
* Copy high score from high score table ($5520) *
* to active high score variable ($521C) used    *
* for display at top of screen during gameplay. *
*************************************************/

loc_86e9:
	lda data_5520+0	    // word_551F+1
	sta WORK_RAM1+$1EC	 // word_521C
	lda data_5520+1		// unk_5521 (hi byte of D)
	sta WORK_RAM1+$1ED	// word_521C+1
	lda data_5520+2
	sta WORK_RAM1+$1EE	// word_521C+2
	rts

	
sub_86f6:
    lda WORK_RAM1+$1D6      // word_5206
    lbne loc_8782			  // draws the game playfield
	
    jsr loc_c6a6
	//LDU(e172)
	LD32_IMM(U_L,PLAYFIELD)
    lda WORK_RAM2+$01       // word_5430+1
    cmp #5
    bcc loc_8710
    jsr loc_c6be
    LDU(dbb2)

/*********************************************
* Generate Enemy Name                        *
* - Chooses enemy name from table at $D503   *
* - Caps index at 10                         *
* - Each table entry is a .word pointer      *
* - Walks the chosen string backwards        *
* - Converts encoded chars with A -= $30     *
* - Stops when result becomes 0              *
* - Writes right-to-left into screen memory  *
**********************************************/
loc_8710:
	// stu word_5200
	lda U_L
	sta WORK_RAM1+$1D0
	lda U_H
	sta WORK_RAM1+$1D1
	
	lda #0
    sta byte_colidx
	
	// ldx #$59BF
	//LDX(SCREEN_BASE+(RRB_Tail_words*2*($1bf>>arcadeRowSize))+$1bf-1)	// $59bf
	
	// Set the beginning of playfield.
	// far right, then set to far left in loc_8782
	//lda #<$59bf
    //sta byte_fd_arc
    //lda #>$59bf
    //sta byte_fe_arc
	
	LDX(ArcadeToMegaTextByte($59bf))
	
	jsr TranslateArcadeTextPtrToMega
	// stx $FD
	lda X_L
	sta byte_fd
	lda X_H
	sta byte_fe

	lda #$21
	sta byte_ff

	lda #1
	sta byte_ca

	lda #0
	sta B_Register
	sta byte_f2          // low byte of D = B = 0

	lda #3
	sta byte_f3          // high byte of D = A = 3
	jsr loc_80a2

	lda #$0c
	sta B_Register
	jsr sub_80a1

	lda #$0b
	sta B_Register
	jsr sub_80a1
	
	//LDX(SCREEN_BASE+(RRB_Tail_words*2*($17f>>arcadeRowSize))+$17f-1)	// $597f - Enemy Name
	LDX(ArcadeToMegaTextByte($597f))

	// ldu #$D503   // table of word pointers
	LDU(d503)
	// ldb word_5430+1
	lda WORK_RAM2+$01
	sta B_Register

	cmp #$0a
	bcc loc_873f_prep
	lda #$0a
	sta B_Register

loc_873f_prep:
	// aslb  // word table => *2
	lda B_Register
	asl
	sta B_Register

	// ldu b,u  // load word pointer from table at U + B
	clc
	lda U_L
	adc B_Register
	sta byte_5
	lda U_H
	adc #0
	sta byte_6

	ldy #0
	lda (byte_5),y
	sta U_L
	iny
	lda (byte_5),y
	sta U_H
loc_8742:
	// lda ,-u   // predecrement U, then read
	sec
	lda U_L
	sbc #1
	sta U_L
	lda U_H
	sbc #0
	sta U_H

	ldy #0
	lda (U_L),y

	sec
	sbc #$30
	beq loc_874c

	sta tmp                 // save glyph
	// move left one visible cell
	sec
	lda X_L
	sbc #2
	sta X_L
	lda X_H
	sbc #0
	sta X_H
	lda tmp                 // restore glyph
	ldy #0
	sta (X_L),y
	bra loc_8742
	
	

/**************************
*Generate player one score*
**************************/
loc_874c:
	LDU(WORK_RAM1+$1e0)													 // original $5210
	//LDX(SCREEN_BASE+(RRB_Tail_words*2*($0c3>>arcadeRowSize))+$0c3-1)   // original $58C3
	LDX(ArcadeToMegaTextByte($58c3))
	jsr sub_88c5
	jsr sub_8922
	
	
	
/*******************************
*Generate player one high score*
*******************************/
loc_8758:
	LDU(WORK_RAM1+$1EC)													 // original $521C
	//LDX(SCREEN_BASE+(RRB_Tail_words*2*($0db>>arcadeRowSize))+$0db-1)   // original $58DB
	LDX(ArcadeToMegaTextByte($58db))
	jsr sub_88c5
	jsr sub_8922

/*************************************************
* Initialise energy bar                          *
*                                                *
* Arcade writes attribute bytes only to flip the *
* energy bar - Player one only                   *
* actual bar is drawn later using tile $0F       *
**************************************************/

loc_8764:
	/*
	Initialise high word colour pointers for safety
	and move this out of scope of the loop since they won't ever hange.
	*/
	lda #$F8
	sta COLPTR2
	lda #$0F
	sta COLPTR3
	
	// Start at translated arcade $5980 attr byte.
    // Existing direct formula is still valid here.
    //LDX(SCREEN_BASE+(RRB_Tail_words*2*($180>>arcadeRowSize))+$180-1)
	LDX(ArcadeToMegaTextByte($5980))

    lda #$0f
    sta B_Register          // 15 cells
loc_876a:
    // ------------------------------------------------
    // Screen high byte MEGA65:
    // ------------------------------------------------
    ldy #0
    lda #>TILE_OFFSET // MSB tile index
    sta (X_L),y

    // ------------------------------------------------
    // Colour RAM byte on MEGA65:
    // arcade used $80 for Flip X in attr byte
    // MEGA65 uses $40 for Flip X in colour RAM
    // ------------------------------------------------
	sec
	lda X_L
	// SCREEN_BASE+1 is required because the arcade code positions X on the
	// attribute byte lane, while MEGA65 colour RAM corresponds to the tile
	// cell byte. The +1 realigns the colour write with the correct cell.
	sbc #<(SCREEN_BASE+1)
	sta COLPTR0

	lda X_H
	sbc #>(SCREEN_BASE+1)
	sta COLPTR1

    ldz #0
    lda #$40                // MEGA65 Flip X
    sta ((COLPTR0)),z

    ADDX(2)
    dec B_Register
    bne loc_876a
	

/******************************
* Prints player two score     *
* When player 2 is active     *
*******************************/

loc_876f:
	lda byte_e0
	beq loc_877e // player 2 is not active.

	lda #$0a
	sta B_Register
	jsr sub_80a1
	jsr sub_88bf
	jsr sub_8922
	
loc_877e:
	inc WORK_RAM1+$1D6 // $5206
	rts
	

/***************************************
* Draw the playfield, left to right    *
*                                      *
* Source data now lives in another     *
* bank and is accessed via a 32-bit    *
* playfield pointer (PF_*).            *
*                                      *
* word_5200 is no longer treated as a  *
* raw address. It is now a 16-bit      *
* offset into PLAYFIELD.               *
***************************************/

loc_8782:
	/*
	Initialise high word colour pointers once.
	*/
	
	lda #$F8
	sta COLPTR2
	lda #$0F
	sta COLPTR3

	dec byte_ca
	lbne locret_87ce

	lda #$01
	sta byte_ca

	dec byte_ff
	lbeq loc_87b2

	lda #$17
	sta B_Register

	/*
	Load translated destination column pointer.
	*/
	lda byte_colidx
	asl
	tax

	lda PlayfieldColumnPtrs,x
	sta X_L
	lda PlayfieldColumnPtrs+1,x
	sta X_H

	lda X_L
	sta byte_fd
	lda X_H
	sta byte_fe

	inc byte_colidx

	/*
	Build 32-bit source pointer from:
		PLAYFIELD + word_5200

	Original arcade sequence:
		ldu word_5200
		leau 1,u
		stu word_5200

	So both the live source pointer and the saved
	16-bit offset must advance by 1 before the loop.
	*/
	LD32_BASE_PLUS_16(U_L, PLAYFIELD, WORK_RAM1+$1D0)
	ADD32_IMM(U_L,1)
	ADD16_MEM(WORK_RAM1+$1D0, 1)

loc_879e:
	/*
	Read tile byte from playfield source.
	*/
	ldz #$00
	lda ((PTR_L)),z

	/*
	Write tile byte to screen.
	*/
	ldy #$00
	sta (X_L),y

	/*
	Read corresponding arcade attribute byte from:
		source + $02E0
	*/
	clc
	lda PTR_L
	adc #<$02E0
	sta PTR2_L

	lda PTR_H
	adc #>$02E0
	sta PTR2_H

	lda PTR_B2
	adc #$00
	sta PTR2_B2

	lda PTR_B3
	adc #$00
	sta PTR2_B3

	ldz #$00
	lda ((PTR2_L)),z
	sta tmp

	/*
	Screen tile page bit comes from source attribute bit 4.
	*/
	and #$10
	lsr
	lsr
	lsr
	lsr
	sta tmp3

	/*
	Convert destination screen address into colour RAM offset.
	*/
	sec
	lda X_L
	sbc #<SCREEN_BASE
	sta COLPTR0

	lda X_H
	sbc #>SCREEN_BASE
	sta COLPTR1

	/*
	Colour RAM byte 0

	Arcade hardware:
		bit 6 = Flip Y
		bit 7 = Flip X

	MEGA65 colour RAM:
		bit 7 = Vertical flip
		bit 6 = Horizontal flip
	*/
	lda tmp
	and #$40
	asl
	sta tmp2

	lda tmp
	and #$80
	lsr
	ora tmp2

	ldz #$00
	sta ((COLPTR0)),z

	/*
	Write tile high byte / page bit.
	*/
	lda tmp3
	
	ora #>TILE_OFFSET
	sta tmp
	clc
	lda X_L
	adc #$01
	sta byte_5
	lda X_H
	adc #$00
	sta byte_6
	lda tmp

	ldy #$00
	sta (byte_5),y

	/*
	Advance destination to next row.
	*/
	ADDX(ROW_STRIDE)
	/*
	Advance source to next playfield row.
	*/
	ADD32_IMM(U_L,$20)

	dec B_Register
	lbne loc_879e
	rts

loc_87b2:
	lda #$20
	sta byte_fd

	inc byte_c6

	lda #$00
	sta byte_c7

	/*
	Original #$543D
	*/
	LDX(WORK_RAM2+$0D)

	/*
	std ,x
	*/
	LDD($328A)
	STD_PTR(X_L)

	/*
	std 2,x
	*/
	clc
	lda X_L
	adc #$02
	sta byte_5
	lda X_H
	adc #$00
	sta byte_6
	LDD($3B8A)
	STD_PTR(byte_5)

	/*
	std 4,x
	*/
	clc
	lda X_L
	adc #$04
	sta byte_5
	lda X_H
	adc #$00
	sta byte_6
	LDD($3898)
	STD_PTR(byte_5)

	/*
	clr -1,x
	*/
	sec
	lda X_L
	sbc #$01
	sta byte_5
	lda X_H
	sbc #$00
	sta byte_6

	ldy #$00
	lda #$00
	sta (byte_5),y

locret_87ce:
	rts


	
/*****************
*Splash Screen   *
*Prints          *
*(c) KONAMI 1985 *
*****************/

/**************************************************************
*  sub_87cf – Text Script Interpreter (6809 → MEGA65 port)    *
*                                                             *
*  Purpose:                                                   *
*    Decodes a text script selected via zp_cmd_param and      *
*    renders it into the MEGA65 tilemap. Used for splash      *
*    screens such as:                                         *
*        (c) KONAMI 1985                                      *
*                                                             *
*  Inputs:                                                    *
*    zp_cmd_param  – index into d56a script table (0,1,2,...) *
*                                                             *
*  Working State:                                             *
*    zp_script_lo/zp_script_hi – pointer to current script    *
*    zp_tile_lo/zp_tile_hi     – pointer to tilemap dest      *
*    zp_script_idx             – index into script bytes      *
*                                                             *
*  Table Format (d56a):                                       *
*    .word script0, script1, script2, ...                     *
*                                                             *
*  Script Format:                                             *
*    label:                                                   *
*        .word tilemap_address   // MEGA65 tilemap location    *
*        .byte encoded chars     // '/', '?', etc.             *
*        .byte $3F               // terminator                 *
***************************************************************/

/**************************************************************
*  sub_87cf – Text Script Interpreter (6809 → MEGA65 port)    *
*                                                             *
*  zp_cmd_param bit layout:                                   *
*    bit 7 = 0 -> draw text                                   *
*    bit 7 = 1 -> clear text                                  *
*    bits 0-6 = script index                                  *
***************************************************************/

sub_87cf:

    //-------------------------------------------
    // 1. Use command parameter to select script
    //-------------------------------------------
    lda zp_cmd_param       // original used B
    asl                    // *2 for .word table, bit7 -> carry = clear mode
    tax

    lda d56a,x             // low byte of script pointer
    sta zp_script_lo
    lda d56a+1,x           // high byte
    sta zp_script_hi

    bcs ClearInit          // original: bcs loc_87F0


    //-------------------------------------------------
    // DRAW MODE
    //-------------------------------------------------
DrawInit:
    ldy #0
    lda (zp_script_lo),y   // low byte of tilemap address
    sta zp_tile_lo
    iny
    lda (zp_script_lo),y   // high byte
    sta zp_tile_hi
    iny
    sty zp_script_idx      // script index now points to first encoded char


DrawLoop:
    ldy zp_script_idx
    lda (zp_script_lo),y   // A = next encoded byte
    iny
    sty zp_script_idx

    cmp #$3F               // '?' = end of script
    lbeq TextDone

    cmp #$2F               // '/' = new line
    beq DrawNewLine

    //------------------------------
    // Normal character:
    //   tile_index = A - $30
    //------------------------------
    sec
    sbc #$30               // A = glyph index
    sta zp_glyph_index

    // write low byte of tile entry
    ldy #0
    lda #<(TILE_OFFSET)
    clc
    adc zp_glyph_index
    sta (zp_tile_lo),y

    // write high byte of tile entry
    iny
    lda #>(TILE_OFFSET)
    adc #0
    sta (zp_tile_lo),y

    // advance tile pointer by 2 bytes
    clc
    lda zp_tile_lo
    adc #2
    sta zp_tile_lo
    bcc DrawLoop
    inc zp_tile_hi
    jmp DrawLoop


DrawNewLine:
    ldy zp_script_idx
    lda (zp_script_lo),y   // low byte of new tilemap address
    sta zp_tile_lo
    iny
    lda (zp_script_lo),y   // high byte
    sta zp_tile_hi
    iny
    sty zp_script_idx
    jmp DrawLoop


    //-------------------------------------------------
    // CLEAR MODE
    // Same script walk, but every printable char
    // becomes glyph $10 instead of (char - $30)
    //-------------------------------------------------
ClearInit:
    ldy #0
    lda (zp_script_lo),y   // low byte of tilemap address
    sta zp_tile_lo
    iny
    lda (zp_script_lo),y   // high byte
    sta zp_tile_hi
    iny
    sty zp_script_idx


ClearLoop:
    ldy zp_script_idx
    lda (zp_script_lo),y   // read next script byte
    iny
    sty zp_script_idx

    cmp #$3F               // '?' = end of script
    beq TextDone

    cmp #$2F               // '/' = new line
    beq ClearNewLine

    //------------------------------
    // Clear character:
    //   always write glyph $10
    //------------------------------
    ldy #0
    lda #<(TILE_OFFSET + $10)
    sta (zp_tile_lo),y

    iny
    lda #>(TILE_OFFSET + $10)
    sta (zp_tile_lo),y

    // advance tile pointer by 2 bytes
    clc
    lda zp_tile_lo
    adc #2
    sta zp_tile_lo
    bcc ClearLoop
    inc zp_tile_hi
    jmp ClearLoop


ClearNewLine:
    ldy zp_script_idx
    lda (zp_script_lo),y   // low byte of new tilemap address
    sta zp_tile_lo
    iny
    lda (zp_script_lo),y   // high byte
    sta zp_tile_hi
    iny
    sty zp_script_idx
    jmp ClearLoop


TextDone:
    jmp loc_807c
   
     
	
loc_8808: // called when you press start
	jmp *

loc_8824:	// to do - gets called during demo.
	jmp *
	
/*********************
*Player 2 score setup*
**********************/
sub_88bf:
	//LDX(SCREEN_BASE+(RRB_Tail_words*2*($0f1>>arcadeRowSize))+$0f1-1)	// original $58F1
	LDX(ArcadeToMegaTextByte($58f1))
	LDU(WORK_RAM1+$1E3)													// original $5213
 
sub_88c5:
    ldy #0
    lda (U_L),y
    bne loc_88d1

    lda #$10
    jsr sub_891f
    jsr sub_891f
    bra loc_88df

loc_88d1:
	lsr
	lsr
	lsr
	lsr
	bne loc_88d9
	lda #$10
	
loc_88d9:
	jsr sub_891f
	ldy #0
	lda (U_L),y
	jsr loc_891d
	
loc_88df:
	ldy #0
	lda (U_L),y

	ldy #1
	ora (U_L),y
	bne loc_88ed

	lda #$10
	jsr sub_891f
	jsr sub_891f
	bra loc_8901
	
loc_88ed:
	ldy #1
	lda (U_L),y
	lsr
	lsr
	lsr
	lsr
	bne loc_88fb

	ldy #0
	lda (U_L),y
	bne loc_88fb

	lda #$10
	
loc_88fb:
	jsr sub_891f

	ldy #1
	lda (U_L),y
	jsr loc_891d

loc_8901:
	ldy #0
	lda (U_L),y
	ldy #1
	ora (U_L),y
	beq sub_890f

	ldy #2
	lda (U_L),y
	lsr
	lsr
	lsr
	lsr
	bra loc_8919

	
sub_890f:
	ldy #2
	lda (U_L),y
	lsr
	lsr
	lsr
	lsr
	bne loc_8919
	lda #$10
	
loc_8919:
	jsr sub_891f

	ldy #2
	lda (U_L),y

loc_891d:
    and #$0f
	
	
sub_891f:
    ldy #0
    sta (X_L),y        // write character/tile low byte only
    INC16(X_L, X_H)    // skip high byte
    INC16(X_L, X_H)    // advance to next cell low byte
    rts
	
	
sub_8922:
    // lda -4,x
    sec
    lda X_L
    sbc #4
    sta tmp
    lda X_H
    sbc #0
    sta tmp+1

    ldy #0
    lda (tmp),y
    cmp #$10
    bne loc_892a

    // sta -2,x   (store the same A we just loaded)
    sec
    lda X_L
    sbc #2
    sta tmp
    lda X_H
    sbc #0
    sta tmp+1

    ldy #0
    lda #$10     // same value as loaded, because branch only falls through if A == $10
    sta (tmp),y

loc_892a:
    // clr ,x
    ldy #0
    lda #0
    sta (X_L),y
    rts
	
/*****************************
* Player 1 and Player 2 lives*
******************************/

/**********************************************
* Queue command handler
*
* Fills top-screen score/life fields with '0'
* at fixed screen positions.
*
* 892C: return to dispatcher (loc_807c)
* 892D: fill left-side field at $5903
* 8942: optionally fill right-side field at $593D
**********************************************/

locret_892c:
    rts


loc_892d:
	// ldd #$1009
	LDD($1009)
	jsr loc_8967

	lda WORK_RAM2+$30     // word_5460
	sta B_Register
	beq loc_8942

	dec B_Register
	beq loc_8942

	lda B_Register
	cmp #$0a
	bcc loc_8940
	lda #$0a
	sta B_Register

loc_8940:
	jsr loc_8965			// prints lives

loc_8942:
	lda WORK_RAM1+$1B0    // word_51E0
	beq locret_892c

	// ldd #$1009
	LDD($1009)				// blank tile and count
	jsr loc_8972

	lda WORK_RAM2+$60     // word_5490
	sta B_Register
	beq locret_892c

	dec B_Register
	beq locret_892c

	lda B_Register
	cmp #$0a
	bcc loc_895a
	lda #$0a
	sta B_Register

loc_895a:
	bra loc_8970


sub_895c:
	lda WORK_RAM2+$00     // word_5430
	sta B_Register
	dec B_Register

	lda WORK_RAM1+$1B1    // word_51E0+1
	bne loc_8970


/*
	Display Player 1 lives 
*/

loc_8965:
	lda #$30
	sta A_Register			/* life glyph */
loc_8967:
	LDX(ArcadeToMegaTextByte($5903))
loc_896a:
	ldy #$00
	lda A_Register
	sta (X_L),y
	ADDX(2)
	DEC_B()
	BNE(loc_896a)
	rts

/*
	Display Player 2 lives 
*/

loc_8970:
	lda #$30
	sta A_Register              /* life glyph */

loc_8972:
	LDX(ArcadeToMegaTextByte($593d))

loc_8975:
	ldy #$00
	lda A_Register
	sta (X_L),y

	sec
	lda X_L
	sbc #$02
	sta X_L
	lda X_H
	sbc #$00
	sta X_H

	DEC_B()
	BNE(loc_8975)
	rts


	
/******************************
*loc_897D — VBLANK IRQ handler*
******************************/

loc_897d:
    // clear bit 2 of ByteC1
    lda byte_c1
    and #$fb
    sta byte_c1

    // increment frame counter
    inc byte_d4

	
    // call main VBLANK routine (Sprites) 

loc_898f:
    jsr sub_8b30

	jsr BuildRowListsFromArcadeRAM
	jsr RRB_BuildAllRows
	
    // call secondary routine (Other functions)
    jsr sub_899e

loc_8994:
    // toggle bit 2 of ByteC1
    lda byte_c1
    eor #4
    sta byte_c1
    rts

sub_899e:
	//shift input history downward (5 frame pipeline)
    lda byte_fb
    sta byte_fc

    lda byte_f6
    sta byte_fb

    lda byte_f1
    sta byte_f6

    lda byte_f2
    sta byte_f7

    lda byte_f3
    sta byte_f8

    // lda $4e00 - read system port (placeholder for now)
    lda #$FF		// read coin1,coin2,service,start1,start2. This is kludged for now
    eor #$FF       // active‑low → 00
    sta byte_f1
	
	// Check game state
    lda byte_c4
    cmp #$01
    beq loc_89c2
    // Check ByteE2
    lda byte_e2
    beq loc_89ce

loc_89c2:
/************************
*Read Player 1 joystick *
************************/
    // TODO: replace placeholder with real MEGA65 input
	// Read left,right,up,down, button 1,2,3
    lda #$FF
    eor #$FF          // active-low → 00
    sta byte_f2

/************************
*Read Player 2 joystick *
************************/
    lda #$FF
    eor #$FF
    sta byte_f3

loc_89ce:
    lda byte_ee
    cmp #$f0
    lbcc loc_8b0e

    lda byte_c3
    cmp #3
    lbeq loc_8b0e

    lda WORK_RAM1 + $1DF // $520f
    beq loc_8a00

    lda byte_e2
    lbne loc_8b0e

    lda byte_f1
    and #$18
    lbeq loc_8b0e

    inc byte_e2

    lda #6
    lda byte_f1
    and #8
    bne loc_89fb

    lda #8

loc_89fb:
    lda #1
    sta byte_c3
    rts


loc_8a00:
    lda byte_e6
    beq loc_8a12        // if E6 == 0 → skip

    dec byte_e6         // E6--

    lda byte_e6
    cmp #4
    bne loc_8a25        // only trigger when E6 == 4

    lda byte_c1
    and #$f7            // clear bit 3
    sta byte_c1
    bra loc_8a20
	
loc_8a12:
    lda byte_e4
    beq loc_8a25        // if E4 == 0 → skip

    dec byte_e4         // E4--

    lda #8
    sta byte_e6         // E6 = 8

    lda byte_c1
    eor #8              // toggle coin counter A

loc_8a20:
    sta byte_c1
    sta byte_4000_shadow 

loc_8a25:
    lda byte_eb
    beq loc_8a37        // if EB == 0, skip

    dec byte_eb         // eb--

    lda byte_eb
    cmp #4
    bne loc_8a4a        // only trigger when EB == 4

    lda byte_c1
    and #$ef            // clear bit 4
    sta byte_c1
    bra loc_8a45
	

loc_8a37:
	lda byte_e9
	beq loc_8a4a

	dec byte_e9

	/* ldb #8 */
	lda #$08
	sta B_Register

	/* stb $eb */
	sta byte_eb

	lda byte_c1
	eor #$10

loc_8a45:
	sta byte_c1
	sta byte_4000_shadow
	

loc_8a4a:
	/* B = $F1 | $F6 */
	lda byte_f1
	ora byte_f6
	sta B_Register

	/* comb */
	eor #$ff
	sta B_Register

	/* andb $FB */
	lda B_Register
	and byte_fb
	sta B_Register

	/* andb $FC */
	lda B_Register
	and byte_fc
	sta B_Register

	/* andb #7 */
	lda B_Register
	and #$07
	sta B_Register
	lbeq loc_8b0e

	/* pshs a,b */
	lda A_Register
	pha
	lda B_Register
	pha

	/* lda $C3 */
	lda byte_c3
	cmp #$02
	beq loc_8a66

	/* ldb #$0F */
	lda #$0f
	sta B_Register
	jsr sub_80a1

loc_8a66:
	/* puls b,a */
	pla
	sta B_Register
	pla
	sta A_Register

    lda byte_c2
    cmp #$90
    lbcs loc_8b0e        // if C2 >= $90 → exit

    lda byte_b
    and #1
    beq loc_8a96        // if B & 1 == 0 → exit

    inc byte_e4
    inc byte_e5

    lda byte_e5
    cmp byte_e7
    bne loc_8a96

    // A = ByteE8 + ByteC2 (BCD)
    lda byte_e8
    clc
    adc byte_c2

    // manual DAA (6809-style)
    // adjust low nibble
    cmp #$0A
    bcc DAA_LowDone
    adc #$06
DAA_LowDone:
    // adjust high nibble
    cmp #$A0
    bcc DAA_HighDone
    adc #$60
DAA_HighDone:
    cmp #$91
    bcc loc_8a89        // if < $91 → branch
    lda #$90            // clamp

loc_8a89:
    sta byte_c2        // byte_C2 = A

    // pshs b  → push B onto stack
    lda byte_b
    pha

    lda #1
    jsr loc_80a2

    // puls b  → restore B
    pla
    sta byte_b

    lda #0
    sta byte_e5          // clr byte_E5

loc_8a96:
    // bitb #2  → test bit 1 of B
    lda byte_b
    and #$02
    beq loc_8abc          // if (B & 2) == 0 → bail

    inc byte_e9
    inc byte_ea

    lda byte_ea
    cmp byte_ec
    bne loc_8abc          // wait until EA == EC

    // A = ED + C2 (BCD)
    lda byte_ed
    clc
    adc byte_c2

    // ----- DAA: adjust low nibble -----
    cmp #$0a
    bcc daa_8a96_lowdone
    adc #$06
daa_8a96_lowdone:

    // ----- DAA: adjust high nibble -----
    cmp #$A0
    bcc daa_8a96_highdone
    adc #$60
daa_8a96_highdone:

    cmp #$91
    bcc loc_8aaf          // if < $91, keep result and fall into 8AAF

    lda #$90              // else clamp to $90 and fall into 8AAF
    // (next: loc_8AAF)


loc_8aaf:
    sta byte_c2
    // pshs b  → push B onto stack
    lda byte_b
    pha

    lda #1
    jsr loc_80a2

    // puls b  → restore B
    pla
    sta byte_b

    lda #0
    sta byte_ea
	
loc_8abc:
    // bitb #4  → test bit 2 of B
    lda byte_b
    and #$04
    beq loc_8ad2          // if (B & 4) == 0 → bail

    // A = C2 + 1 (BCD)
    lda byte_c2
    clc
    adc #1

    // ----- DAA: adjust low nibble -----
    cmp #$0A
    bcc daa_8abc_lowdone
    adc #$06
daa_8abc_lowdone:

    // ----- DAA: adjust high nibble -----
    cmp #$A0
    bcc daa_8abc_highdone
    adc #$60
daa_8abc_highdone:

    cmp #$91
    bcc loc_8acb          // if < $91 → use result

    lda #$90              // else clamp to $90
    // fall through to loc_8ACB
	
loc_8acb:
    // sta $C2
    sta byte_c2
    // lda #1
    lda #1
    // jsr loc_80A2
    jsr loc_80a2

loc_8ad2:
    // tst $C2  → load and test
    lda byte_c2
    beq loc_8b0e        // if C2 == 0 → bail

    // lda #1 / sta $E2
    lda #1
    sta byte_e2

    // lda $5608
    lda #(WORK_RAM2 + $1d8)
    bne loc_8ae2        // if nonzero → skip
    jsr sub_c6f3		 // to do.
	
	
loc_8ae2:
    // tst $E2  → load and test
    lda byte_e2
    beq loc_8aea          // if E2 == 0 → skip

    // lda $c3
    lda byte_c3
    bne loc_8b02          // if C3 != 0 → jump

loc_8aea:
    // lda $c4
    lda byte_c4
    cmp #5
    beq loc_8af3          // if C4 == 5 → jump
    jsr sub_8ca5
	
loc_8af3:
    // lda #1
    lda #1

    // sta $c3
    sta byte_c3

    // sta $e2
    sta byte_e2

    // clr $c4
    lda #0
    sta byte_c4

    // clr $c5
    sta byte_c5

    // jsr sub_814c
    jsr sub_814c

    bra loc_8b0e
    
loc_8b02:
    // cmpa #2
    cmp #2
    beq loc_8b0e        // if a == 2 → bail

    // lda $c4
    lda byte_c4
    cmp #2
    bne loc_8b0e        // if c4 != 2 → bail

    // dec $c4
    dec byte_c4

loc_8b0e:
    // Load script pointer
    ldx byte_de
    cpx byte_dc
    beq loc_8b28

    // Read next script byte
    lda 0,x
    inx
    sta WORK_RAM2 + $1D7  // store command byte - 0X5607
    lda #1
    sta WORK_RAM2 + $1D8  // mark command ready - 0X5608

    // Wrap if past end
    cpx #(WORK_RAM1 + $2EF) // 0x531f
    bcs loc_8b26
    ldx #(WORK_RAM1 + $2D0) // 0x5300

loc_8b26:
    stx byte_de

/***********************************
*VBlank driven function dispatcher *
************************************/

loc_8b28:
    lda byte_c3
    asl
    tax
    jmp (d9f0,x)
	

/******************************************************
*Main VBLANK routine (Sprites)                        *
*sub_8B30 - locret_8BDC                               *
*Implemented in Sprite.asm                            *
*                                                     *
*sub_8B30 is NOT a sprite engine.                     *
*It's a sprite RAM copier + weird looping structure.  *
*This routine simply:                                 *
•Walks a table of sprite definitions in ROM           *
•Copies them into the arcade’s sprite RAM at          *
•Applies a tiny bit of per frame adjustment           *
•Handles a multi page sprite table                    *
******************************************************/

/*

This is our Sprite Producer.

Each sprite entry is 4 bytes
5000-502f    W  sprite RAM 1 (18 sprites)
                    byte 0 - bit 0 - sprite code MSB
                             bit 6 - flip X
                             bit 7 - flip Y
                    byte 1 - Y position
					
5400-542f    W  sprite RAM 2
                    byte 0 - X position
                    byte 1 - sprite code LSB

- Starts reading sprite definitions from ROM at $5000 - $502f and $5400 - $542f
- Copies each sprite’s 4 bytes
- Moves to the next sprite definition (leau $10,u = next sprite block)
- Loops until all sprites are copied
- Handles a second page of sprite definitions if needed (leau $40,u)
- Applies a tiny animation tweak (inca or deca depending on bit in $C1)
*/


sub_8b30:

    CLRB()
    // ldu #$5030
    LDU(WORK_RAM1)
    // ldx #$5000
    LDX(SPRITE_RAM1)
    // lda $C1
    LDA(byte_c1)
    // asra
    ASRA()
    // bcs loc_8B8A
    BCS(loc_8b8a)
	
// ROM:8B3C loc_8B3C:

loc_8b3c:
    // lda 4,u -> SPRITE_RAM2 byte0
    ldy #4
    lda (U_L),y
    STA_SPR2_0()

    // lda $0e,u -> SPRITE_RAM2 byte1
    ldy #$0e
    lda (U_L),y
    STA_SPR2_1()

    // lda $0f,u -> SPRITE_RAM1 byte0 (attr)
    ldy #$0f
    lda (U_L),y
    STA_SPR1_POSTINC()

    // lda 6,u  (candidate Y)
    ldy #6
    lda (U_L),y

    // cmpx #$5026 / bcc loc_8b60  (X is offset now)
    cpx #$27	// workaround - applied for the last sprite offset in the title
    bcs loc_8b60

    // save Y (DO NOT use tmp// ASRA uses tmp)
    sta byte_fc

    // ASRA(byte_c1) -> Flags bit0
    lda byte_c1
    sta A_Register
    ASRA()

    // put Flags bit0 into CPU carry
    lda Flags
    lsr

    // restore Y
    lda byte_fc

    // carry set => DEC
    bcs loc_8b5f

    // INC
    clc
    adc #1
    bra loc_8b60
	
loc_8b5f:
    sec
    sbc #1

loc_8b60:
    // sta ,x+
    STA_SPR1_POSTINC()

    // leau $10,u
    ADDU($0010)

    // cmpu #$5050 / bcs loc_8B3C   (U < $5050)
    BR_IF_U_LT(WORK_RAM1 + $20, loc_8b3c)    // $5030 + $20 = $5050

    // bne loc_8B78   (U != $5050)
    BR_IF_U_NE(WORK_RAM1 + $20, loc_8b78)

    // tstb / bne loc_8B78
    lda B_Register
    bne loc_8b78

    // lda word_5221+1 / beq loc_8B78
    lda WORK_RAM1 + $01f2   // == $5222
	beq loc_8b78

    // leau $40,u
    ADDU($0040)

loc_8b78:
    // cmpx #$5030 / bcc locret_8B89
    // (branch if X >= $5030)
    lda X_H
    cmp #>WORK_RAM1          // $5030
    bcc !x_lt+
    bne locret_8b89
    lda X_L
    cmp #<WORK_RAM1
    bcs locret_8b89
!x_lt:

    // cmpu #$51B0 / bcs loc_8B3C
    // (branch if U < $51B0, consistent with earlier port usage)
    lda U_H
    cmp #>WORK_RAM1 + $180
    lbcc loc_8b3c
    bne !u_not_lt+
    lda U_L
    cmp #<WORK_RAM1 + $180
    lbcc loc_8b3c
!u_not_lt:

    // ldu #$5050
    lda #<(WORK_RAM1 + $20)  // $5050
    sta U_L
    lda #>(WORK_RAM1 + $20)
    sta U_H

    // incb
    inc B_Register
    lbra loc_8b3c

locret_8b89:
    rts


loc_8b8a:
    // lda 4,u / coma / suba #$0f  -> SPRITE_RAM2 byte0
    ldy #4
    lda (U_L),y
    eor #$ff
    sec
    sbc #$0f
    STA_SPR2_0()

    // lda $0e,u -> SPRITE_RAM2 byte1
    ldy #$0e
    lda (U_L),y
    STA_SPR2_1()

    // lda $0f,u / eor #$40 -> SPRITE_RAM1 byte0
    ldy #$0f
    lda (U_L),y
    eor #$40
    STA_SPR1_POSTINC()

    // lda 6,u  (candidate Y)
    ldy #6
    lda (U_L),y

    // cmpx #$5026 / bcc loc_8bb3  (X is offset now)
    ldx X_L
    cpx #$26
    bcs loc_8bb3

    // save Y safely
    sta byte_fc

    // ASRA(byte_c1) -> Flags bit0
    lda byte_c1
    sta A_Register
    ASRA()

    // Flags bit0 -> CPU carry
    lda Flags
    lsr

    // restore Y
    lda byte_fc

    bcs loc_8bb2

    // INC
    clc
    adc #1
    bra loc_8bb3

loc_8bb2:
    // DEC
    sec
    sbc #1

loc_8bb3:
    // store Y -> SPRITE_RAM1 byte1
    STA_SPR1_POSTINC()

    // leau $10,u
    clc
    lda U_L
    adc #<$0010
    sta U_L
    lda U_H
    adc #>$0010
    sta U_H

    // cmpu #$5050
    // bcs loc_8B8A
    // (branch if U < $5050, consistent with earlier port usage)
    lda U_H
    cmp #>(WORK_RAM1 + $20)      // $5050
    lbcc loc_8b8a
    bne !u_not_lt_5050+
    lda U_L
    cmp #<(WORK_RAM1 + $20)
    lbcc loc_8b8a
!u_not_lt_5050:

    // bne loc_8BCB
    lda U_H
    cmp #>(WORK_RAM1 + $20)
    bne loc_8bcb
    lda U_L
    cmp #<(WORK_RAM1 + $20)
    bne loc_8bcb

    // tstb / bne loc_8BCB
    lda B_Register
    bne loc_8bcb

    // lda word_5221+1 / beq loc_8BCB
    lda WORK_RAM1 + $01f2   // == $5222
    beq loc_8bcb

    // leau $40,u
    clc
    lda U_L
    adc #<$0040
    sta U_L
    lda U_H
    adc #>$0040
    sta U_H

loc_8bcb:
    // cmpx #$5030
    // bcc locret_8BDC
    // (branch if X >= $5030)
    lda X_H
    cmp #>WORK_RAM1              // $5030
    bcc !x_lt_5030+
    bne locret_8bdc
    lda X_L
    cmp #<WORK_RAM1
    bcs locret_8bdc
!x_lt_5030:

    // cmpu #$51B0
    // bcs loc_8B8A
    // (branch if U < $51B0, consistent with earlier port usage)
    lda U_H
    cmp #>WORK_RAM1 + $180
    lbcc loc_8b8a
    bne !u_not_lt_51b0+
    lda U_L
    cmp #<WORK_RAM1 + $180
    lbcc loc_8b8a
!u_not_lt_51b0:

    // ldu #$5050
    lda #<(WORK_RAM1 + $20)
    sta U_L
    lda #>(WORK_RAM1 + $20)
    sta U_H

    // incb
    inc B_Register

    lbra loc_8b8a

locret_8bdc:
    rts


/************************
*Vblank driven Functions*
*Function table at D9F0 *
*And at  D9F8           *
************************/


/************************
*R=>L Clear Function    *
*************************/
loc_8bdd://R=>L state
	lda byte_c4        // load sub‑state index
    asl                // multiply by 2 (word entries)
    tax                // X = offset into table
    jmp (d9f8,x)      // jump to handler

loc_8be5://R=>L State
    jsr sub_8115        // step R→L clear
    cmp #0
    bne locret_8bf7     // if not finished, return


	lda #$a0
    sta byte_ca         // ByteCA = #$A0
    inc byte_c4         // advance sub_state

    jsr sub_842c		// check coctail mode
    jsr sub_814c		// Clear work ram
locret_8bf7:
    rts
	
	
/************************
*Splash Screen Function *
************************/
loc_8bf8:
    dec byte_ca
    bne loc_8c06        // still waiting → stay in splash

    inc byte_c4         // advance to next game state
    lda #0
    sta byte_c5         // reset sub_state


    jsr sub_814c        // clear work RAM (5030–51BC)
    jmp sub_8ca5        // clear tile bits for Konami logo + copyright


loc_8c06:
    lda byte_ca
    cmp #$9F
    lbne locret_8c43

    jsr sub_92ad
    // X = #$5030
    lda #<WORK_RAM1
    sta byte_30
    lda #>WORK_RAM1
    sta byte_31

    // U = #$DA46
    lda #<da46
    sta byte_46
    lda #>da46
    sta byte_47

    // Y = #$000A  (we only need low byte)
    lda #$0a
    sta byte_20

    // B = #$38
    lda #$38
    sta logoX
	
loc_8c1b:
	//Title: Shift YIE AR KUNG FU logo by 1px to eliminate worst-case RRB row pressure
    lda #$A0-1
    jsr sub_8c30
    beq done_first_loop
    jmp loc_8c1b
done_first_loop:
 
    // Reset Y count for second loop
	lda #$0a
	sta logoCount
	lda #$38  
	sta logoX 
loc_8c27:
	//Title: Shift YIE AR KUNG FU logo by 1px to eliminate worst-case RRB row pressure
    lda #$90-1 
	jsr sub_8c30
    beq done_second_loop
    jmp loc_8c27
	
done_second_loop:
	jmp loc_8cb3
sub_8c30:
    // A on entry = Y position (like d0 -> 6(a0))
    ldy #6
    sta (sprPtrLo),y        // [sprPtr+6] = Y

    // load next tile index: A = (logoPtr)
    ldy #0
    lda (logoPtrLo),y
    // increment logoPtr++
    inc logoPtrLo
    bne dontInclogoPtrHi
    inc logoPtrHi
dontInclogoPtrHi:
    // store tile index at [sprPtr+E]
    ldy #$0E
    sta (sprPtrLo),y

    // write attribute $41 at [sprPtr+F]
    lda #$41
    iny                     // Y = $0F
    sta (sprPtrLo),y

    // X position from logoX → [sprPtr+4]
    lda logoX
    ldy #4
    sta (sprPtrLo),y

    // logoX += $10
    clc
    lda logoX
    adc #$10
    sta logoX

    // sprPtr += $10
    clc
    lda sprPtrLo
    adc #$10
    sta sprPtrLo
    bcc dontIncsprPtrHi
    inc sprPtrHi
dontIncsprPtrHi:
    // logoCount--
    lda logoCount
    sec
    sbc #1
    sta logoCount
    // Z now reflects end of row, just like 6809
locret_8c43:
	rts
	
/**********************
HighScore state       *
Draws High Score Table*
***********************/

loc_8c44:    
    dec byte_ca
    bne loc_8c4f

    inc byte_c4
    lda #0
    sta byte_c5
    sta byte_cf
    rts

locret_8c4e:
    rts
	
loc_8c4f:
    lda byte_ca
    cmp #$9a
    bne locret_8c4e
	jsr loc_867e
    jmp loc_8cde

loc_8c5b:
    lda byte_ca
    cmp #$a0
    bne loc_8c83

    lda byte_e2
    bne locret_8c82

    LDX(da06)          // X = address of table da06
    CLRB()

    lda byte_cf
    bne loc_8c6e
    inc B_Register
	
loc_8c6e: // location after clearing high score
    lda B_Register
    sta byte_cf

    asl B_Register              // ASLB: multiply table index by 2

    // tmp = X + B_Register
    clc
    lda X_L
    adc B_Register
    sta tmp
    lda X_H
    adc #0
    sta tmp+1

    // load word from [tmp] into X
    ldy #0
    lda (tmp),y
    sta X_L
    iny
    lda (tmp),y
    sta X_H

    // stx word_520A
    lda X_L
    sta WORK_RAM1+$1DA          // adjust if your word_520A is elsewhere
    lda X_H
    sta WORK_RAM1+$1DB

    lda #1
    sta byte_ca
    sta WORK_RAM1+$1DE          // word_520E low byte? see note below

    jsr sub_8d71

    lda #0
    sta byte_c5
    rts
	
locret_8c82:
	rts


loc_8c83:
	lda WORK_RAM1+$1DA
	sta X_L
	lda WORK_RAM1+$1DB
	sta X_H

	lda WORK_RAM1+$1DE
	sta B_Register

	clc
	lda X_L
	adc #1
	sta tmp
	lda X_H
	adc #0
	sta tmp+1

	ldy #0
	lda (tmp),y
	sta B_Register
	sta FB_L

	dec WORK_RAM1+$1DE
	bne loc_8ca2

    ADDX(2)

    lda X_L
    sta WORK_RAM1+$1DA
    lda X_H
    sta WORK_RAM1+$1DB

    ldy #0
    lda (X_L),y
    sta WORK_RAM1+$1DE
    iny
    lda (X_L),y
    sta B_Register
    sta FB_L

loc_8ca2:
    jmp loc_8de2
	
// clear tile bits for Konami logo + copyright

sub_8ca5:
	/*
	ROM:8CA5                 ldd     #$1090
	ROM:8CA8                 sta     word_5E65
	ROM:8CAB                 sta     word_5EA5
	ROM:8CAE                 sta     word_5EA7
	ROM:8CB1                 bra     loc_8CE0
	*/
	
	lda #$90
    sta byte_f2          // emulated B
	lda #$10
    sta byte_f3          // emulated A
   
    sta SCREEN_BASE+(RRB_Tail_words*2*($665>>arcadeRowSize))+$665-1
    sta SCREEN_BASE+(RRB_Tail_words*2*($6A5>>arcadeRowSize))+$6A5-1
    sta SCREEN_BASE+(RRB_Tail_words*2*($6A7>>arcadeRowSize))+$6A7-1
    lbra loc_8ce0
	
/************************************************************
* loc_8CB3 — Write Sprite Data and characters (i, ® cluster)*
************************************************************/

loc_8cb3:
	
    lda #<WORK_RAM1 + $140  //$5170
    sta sprPtrLo
    lda #>WORK_RAM1 + $140
    sta sprPtrHi

    // Y = 3 sprites
    lda #3
    sta logoCount

    // U = $DA5A (sprite data table)
    lda #<da5a
    sta logoPtrLo
    lda #>da5a
    sta logoPtrHi

// X = $5170 already reflected in sprPtrLo/Hi
// U = $DA5A already in logoPtrLo/Hi
// logoCount = 3

loc_8cbd:
    // ----------------------------------------
    // First word: Ypos, Xpos
    // ----------------------------------------

    // Ypos at sprPtr + 6
    ldy #0
    clc
    lda sprPtrLo
    adc #6
    sta tmpPtrLo
    lda sprPtrHi
    adc #0
    sta tmpPtrHi

    lda (logoPtrLo),y      // Ypos
    ldy #0
    sta (tmpPtrLo),y

    // Xpos at sprPtr + 4
    ldy #1   // second byte in DA5A entry
    clc
    lda sprPtrLo
    adc #4
    sta tmpPtrLo
    lda sprPtrHi
    adc #0
    sta tmpPtrHi

    lda (logoPtrLo),y      // Xpos
    ldy #0
    sta (tmpPtrLo),y

    // U += 2 (past Ypos/Xpos)
    clc
    lda logoPtrLo
    adc #2
    sta logoPtrLo
    bcc no_inc_hi1
    inc logoPtrHi
no_inc_hi1:

    // ----------------------------------------
    // Second word: tile, attr
    // ----------------------------------------

    // tile at sprPtr + $0E
    ldy #0
    clc
    lda sprPtrLo
    adc #$0E
    sta tmpPtrLo
    lda sprPtrHi
    adc #0
    sta tmpPtrHi

    lda (logoPtrLo),y      // tile
    ldy #0
    sta (tmpPtrLo),y

    // attr at sprPtr + $0F
    ldy #1
    clc
    lda sprPtrLo
    adc #$0F
    sta tmpPtrLo
    lda sprPtrHi
    adc #0
    sta tmpPtrHi

    lda (logoPtrLo),y      // attr
    ldy #0
    sta (tmpPtrLo),y

    // U += 2 (past tile/attr)
    clc
    lda logoPtrLo
    adc #2
    sta logoPtrLo
    bcc no_inc_hi2
    inc logoPtrHi
no_inc_hi2:

    // ----------------------------------------
    // sprPtr += $10 (next sprite)
    // ----------------------------------------
    clc
    lda sprPtrLo
    adc #$10
    sta sprPtrLo
    bcc no_inc_hi3
    inc sprPtrHi
no_inc_hi3:

    // logoCount--
    lda logoCount
    sec
    sbc #1
    sta logoCount
    lbne loc_8cbd

/**********************************
* Character RAM writes (dot, i, ®)*
**********************************/

/**
 * Character RAM writes (dot, i, ®)
 * Store accumulator to calculated screen position
 * 
 * This calculates a specific screen position for placing a character:
 * - SCREEN_BASE: Base address of screen memory
 * - RRB_Tail: Variable representing offset for RRB
 * - $665/$40: Division (calculating row/column positioning)
 * - Note: arcade uses a rowsize of $40 / 64 for each row.
 * - $665-1: Final offset adjustment
 * $665>>6 is effectively $665/$40 which calculates the row
 * Arcade uses a rowsize of $40 / 64
 * The comment indicates this places a "dot above the i" character
 * at a specific calculated screen coordinate
 */


    lda #$AE
	//sta $5E65-1
    sta SCREEN_BASE+(RRB_Tail_words	*2*($665>>arcadeRowSize))+$665-1 // dot above the i
	lda #$9F
	//sta $5EA5-1
    sta SCREEN_BASE+(RRB_Tail_words	*2*($6a5>>arcadeRowSize))+$6a5-1 // the i
	lda #$BD
	sta SCREEN_BASE+(RRB_Tail_words	*2*($6a7>>arcadeRowSize))+$6a7-1 // (r)
	//sta $5EA7-1
	
loc_8cde:
	lda #$10
    sta byte_f2      // B = $10
loc_8ce0:
	jmp	sub_80a1
	

loc_8cf6:// to do. code goes here when credit is inserted
	jmp *

loc_8d0c: // to do.
	jmp *
	
sub_8d71:
	lda #0
	sta byte_e0
	bra loc_8d8b


loc_8d75:
	lda #$98
	sta A_Register
	lda #$01
	sta B_Register

loc_8d78:
	lda B_Register
	sta byte_e0

	lda WORK_RAM1+$1DF       // word_520E+1
	bne loc_8d89

	lda A_Register
	clc
	adc byte_c2
	DAA_A()
	sta byte_c2
	sta A_Register

	lda #1
	jsr loc_80a2

loc_8d89:
	inc byte_c3
	
loc_8d8b:
	lda byte_e2
	beq loc_8d9b

	lda #0
	sta WORK_RAM1+$1E0       // word_5210 low
	sta WORK_RAM1+$1E1       // word_5210 high
	sta WORK_RAM1+$1E2       // word_5212 low
	sta WORK_RAM1+$1E3       // word_5212 high
	sta WORK_RAM1+$1E4       // word_5214 low
	sta WORK_RAM1+$1E5       // word_5214 high
	
loc_8d9b:
    sta byte_c6
    sta byte_e1
    sta byte_c5
    sta WORK_RAM1+$1F1       // word_5221

    jsr sub_814c
    jsr sub_8dc7

    lda byte_c9
    sta WORK_RAM2+$30       // word_5460
    sta WORK_RAM2+$60       // word_5490

    lda byte_cb
    sta WORK_RAM2+$33       // word_5463 low
    sta WORK_RAM2+$63       // word_5493 low

    lda byte_cc
    sta WORK_RAM2+$34      // word_5463 high
    sta WORK_RAM2+$64      // word_5493 high

    lda byte_e2
    bne locret_8dc6

    lda byte_cf
    beq loc_8dc3

    lda #2
loc_8dc3:
    sta WORK_RAM2+$31       // word_5460+1
	
locret_8dc6:
    rts
	
sub_8dc7:
	LDX(WORK_RAM2)          /* $5430 */
	LDD($0000)
loc_8dcd:
	STD_ZERO_POSTINC_X()
	CMPX(WORK_RAM2+$8d)     /* $54bd */
	BCS(loc_8dcd)

loc_8dd4:
	LDX(WORK_RAM2+$90)      /* $54c0 */
	LDD($0000)
loc_8dda:
	STD_ZERO_POSTINC_X()
	CMPX(WORK_RAM2+$ed)     /* $551d */
	BCS(loc_8dda)
    rts
	
/*****************************
* DA70 - Jump Table Handler 1*
******************************/	
	
loc_8de2:
	lda byte_c6
	asl
	tax
	lda da70,x		// ptr to jump table.
	sta byte_5
	lda da70+1,x
	sta byte_6
	jmp (byte_5)

loc_8dea:
    jsr sub_8115
    bne locret_8df2
loc_8df0:
    inc byte_c6

locret_8df2:
    rts						// returns to 0x8994
	
loc_8df3:
    LDU(WORK_RAM2)			// #$5430		
    LDX(WORK_RAM2+$30)		// #$5460

    lda byte_e0
    beq loc_8e04

    lda byte_e1
    beq loc_8e04

    LDX(WORK_RAM2+$60)		// #$5490

loc_8e04:
    // ldd ,x++
    ldy #0
    lda (X_L),y
    sta A_Register
    iny
    lda (X_L),y
    sta B_Register
    INC16(X_L, X_H)
    INC16(X_L, X_H)

    // std ,u++
    ldy #0
    lda A_Register
    sta (U_L),y
    iny
    lda B_Register
    sta (U_L),y
    INC16(U_L, U_H)
    INC16(U_L, U_H)

    CMPU(WORK_RAM2+$30)	  // $5460
    BCS(loc_8e04)

    inc byte_c6

    lda #0
    sta WORK_RAM1+$1D6      // word_5206 low
    sta byte_c7

    lda WORK_RAM2+$2       // word_5432
    bne locret_8e1d

    inc WORK_RAM2+$2       // word_5432
locret_8e1d:
    rts

/****************************
*DA70 - Jump Table Handler 2*
*****************************/	

loc_8e1e:
	lda byte_c7
	asl
	tax
	lda da82,x
	sta byte_5
	lda da82+1,x
	sta byte_6
	jmp (byte_5)


loc_8e26:
	jsr sub_8115
	bne locret_8e4e

	jsr loc_c67a

	lda byte_e0
	beq loc_8e3a

	lda #7
	clc
	adc byte_e1
	sta B_Register
	jsr sub_80a1
	
	
/*********************
* Prints Stage Number*
**********************/

loc_8e3a:
	lda #$0d
	sta B_Register
	jsr sub_80a1
	//LDX(SCREEN_BASE+(RRB_Tail_words*2*($4a3>>arcadeRowSize))+$4a3-1)		// $5ca3
	LDX(ArcadeToMegaTextByte($5ca3))
	LDU(WORK_RAM2)	// $5430
	jsr sub_890f	// prints 1 for stage for stage 1.
	lda #$20
	sta byte_fd
	inc byte_c7
locret_8e4e:
	rts

loc_8e4f:
	dec byte_fd
	bne locret_8e57
	inc byte_c7
	lda #0
	sta byte_c5
locret_8e57:
	rts


loc_8e58: // code is active when game has started - stage 1
    jsr sub_8115
    bne locret_8e57
    inc byte_c7

loc_8e60:
    lda #0
    sta WORK_RAM1+$1D6      // word_5206
    jmp loc_a7db

loc_8e66:
    jsr sub_86f6
	lda #$0
	sta A_Register
    sta B_Register
	sta WORK_RAM2+$09       // word_5439 low
    sta WORK_RAM2+$0A       // word_5439 high
    rts
	
sub_8e6f:
	// ldd ,x
	ldy #0
	lda (X_L),y
	sta A_Register          // high byte
	iny
	lda (X_L),y
	sta B_Register          // low byte

	// addd #1
	clc
	lda B_Register
	adc #1
	sta B_Register
	lda A_Register
	adc #0
	sta A_Register

	// std ,x
	ldy #0
	lda A_Register
	sta (X_L),y
	iny
	lda B_Register
	sta (X_L),y

	// bne locret_8e7c   // test 16-bit result
	lda A_Register
	ora B_Register
	bne locret_8e7c

	// coma / comb / std ,x
	lda #$ff
	sta A_Register
	sta B_Register

	ldy #0
	lda A_Register
	sta (X_L),y
	iny
	lda B_Register
	sta (X_L),y

locret_8e7c:
	rts

/*****************
* Game Play Loop *
******************/
loc_8e7d:

	LDX(WORK_RAM2 + $7)		// $5437
	jsr sub_8e6f
	ADDX(2)
	jsr sub_8e6f

	lda byte_f0
	and #$02
	bne loc_8e92
	
	lda byte_ef
	and #$04
	bne loc_8ea2
	

loc_8e92:
	lda byte_e0
	beq loc_8ea2
	
	lda byte_e1
	beq loc_8ea2

	lda U_L         // $F3
	sta B_Register // $F2

	lda FB_H       // $F8
	sta FB_L       // $F7
	
loc_8ea2:  
	jsr sub_923f		// Check status for waterfall
	jsr sub_9084		// 1UP flasher 0x8b=blank, B=1UP
	jsr sub_9315		// Game vars and set up, inits sprite positions in the game/attract. ( 5315 -> 5415 )
	//jsr sub_a86d	// Sprite routines [27/04/2025]
	jsr sub_9ea5		// Draws energy bars
	
	
	/* ldd word_5439 */
	lda WORK_RAM2+$09          /* word_5439 */
	sta A_Register
	lda WORK_RAM2+$0a          /* word_5439+1 */
	sta B_Register

	/* cmpa #$3c */
	lda A_Register
	cmp #$3c
	bcc loc_8ec9

	/* tstb */
	lda B_Register
	bne loc_8ec9
	
	jsr sub_a737
	jsr loc_c696
	jsr loc_c6b2
	
	lda #$23
	sta B_Register
	jsr sub_80a1
	
loc_8ec9:
	lda WORK_RAM2+$05          /* word_5435 */
	sec
	sbc #$01
	beq loc_8ed7

	lda WORK_RAM2+$06          /* word_5435+1 */
	sec
	sbc #$01
	lbne locret_8e7c
	bra loc_8ee2


loc_8ed7:
	lda #$00
	sta WORK_RAM2+$05          /* word_5435 */
	sta WORK_RAM2+$06          /* word_5435+1 */

	dec WORK_RAM2+$00          /* word_5430 */
	inc byte_c6

loc_8ee2:
	inc byte_c6

	lda #$00
	sta WORK_RAM1+$1d6         /* word_5206 */

	lda WORK_RAM1+$5c          /* word_508c */
	cmp #$08
	bne loc_8ef3

	lda #$01
	sta WORK_RAM2+$0b          /* word_543b */
			
loc_8ef3:
	lbra loc_8f5b

loc_8ef5:
	lda WORK_RAM1+$1D6      // word_5206 low
	asl
	tax
	lda da8e,x
	sta byte_5
	lda da8e+1,x
	sta byte_6
	jmp (byte_5)
	
sub_8efe:
	lda byte_e0
	beq loc_8f0c

	lda #$08
	sta B_Register

	lda byte_e1
	bne loc_8f09

	/* decb */
	lda B_Register
	sec
	sbc #$01
	sta B_Register

loc_8f09:
	jsr sub_80a1

loc_8f0c:
	lda #$09
	sta B_Register
	jsr sub_80a1
	jmp loc_c6b6
	
loc_8f14: // to do
	jmp *

loc_8f86:
	dec byte_fd
	bne locret_8f8e

	lda #0
	sta byte_c6
	sta byte_c5

locret_8f8e:
    rts
	
loc_8f8f:
	lda byte_c1
	and #$bf
	sta byte_c1
	jsr sub_8446

	lda byte_f1
	sta B_Register

	lda byte_c2
	beq locret_8f8e

	dec
	beq loc_8fa5

	lda B_Register
	and #$10
	bne loc_8fb8

loc_8fa5:
    lda B_Register
    and #$08
    bne loc_8fbf

    lda byte_c6
    bne locret_8f8e

    jsr sub_85b3

    lda #0
    sta A_Register          // preserve 6809 CLRA for next routine

loc_8fb1:
    lda #1
    sta B_Register          // LDB #1
    sta byte_c3             // STB $C3
    jmp loc_8d0c

loc_8fb8:
    jsr sub_85b3
    lda #8
    bra loc_8fb1

loc_8fbf:
    jsr sub_85b3
    lda #6
    bra loc_8fb1

loc_8fc6:
	lda #$02
	sta A_Register
	lda #$02
	sta B_Register
	jsr loc_80a2
	lda byte_d4
	sta A_Register
	ASRA()
	BCS(loc_8fd7)
	ASRA()
	BCS(loc_8fd7)
	jsr loc_c692

loc_8fd7:
    LDU(WORK_RAM1+$20)					  // $5050
    jsr sub_a663

    // ldd word_508C
    lda WORK_RAM1+$5C       // $508C - $5030 = $5C
    sta A_Register
    lda WORK_RAM1+$5D
    sta B_Register

    // subd #$0010
    sec
    lda B_Register
    sbc #$10
    sta B_Register
    lda A_Register
    sbc #$00
    sta A_Register

    bcs loc_8fe7            // 6809 BCC after SUBD => no borrow// 6502 C=1 means no borrow

    lda #0
    sta A_Register
    sta B_Register
	
loc_8fe7:
    // std word_508C
    lda A_Register
    sta WORK_RAM1+$5C
    lda B_Register
    sta WORK_RAM1+$5D
    lda A_Register
    ora B_Register
    beq loc_8ff0
    rts
	
loc_8fed:
    inc WORK_RAM1+$1D6      // word_5206

loc_8ff0:
    inc WORK_RAM1+$1D6      // word_5206
    rts
	
loc_8ff4:
	lda WORK_RAM2+$0B        // word_543B
	beq loc_8fed

	lda #$00
	sta A_Register
	lda #$08
	sta B_Register           // D = $0008
	//LDX(SCREEN_BASE+(RRB_Tail_words*2*($18e>>arcadeRowSize))+$18e-1) // $598e
	LDX(ArcadeToMegaTextByte($598e))

loc_8fff: // to do
loc_901b: // to do
loc_902b: // to do
loc_9052: // to do
loc_9076: // to do
	jmp *

// ------------------------------------------------------------
// sub_9084
// 1UP flasher
//
// 0x0B = "1UP"
// 0x8B = blanked version
// ------------------------------------------------------------

sub_9084:
	// dec $FD
	dec byte_fd
	bne loc_9090

	// lda #$20
	lda #$20
	sta byte_fd

	// ldb #$0B
	lda #$0b
	sta B_Register

	// bra loc_9098
	bra loc_9098


loc_9090:
	// lda $FD
	lda byte_fd

	// cmpa #$10
	cmp #$10
	bne locret_90ac

	// ldb #$8B
	lda #$8b
	sta B_Register


loc_9098:
	/* pshs b */
	lda B_Register
	pha

	lda byte_e1
	beq loc_909f

	dec B_Register

loc_909f:
	jsr sub_80a1

	/* puls b */
	pla
	sta B_Register

	lda B_Register
	eor #$82
	sta B_Register

	lda byte_e2
	bne locret_90ac
	lbra sub_80a1

locret_90ac:
	rts

loc_90ad:
    lda #5
    sta byte_c7
    jmp loc_8e60


loc_90b4:
    jsr sub_841e

    lda #0
    sta WORK_RAM1+$1F2      // word_5221+1

    lda byte_e2
    beq loc_90ad

    jsr loc_c6a2
    jsr sub_92ad

    lda #3
    sta B_Register

    lda WORK_RAM2+$01       // word_5430+1
    cmp #5
    bcc loc_90ce
    inc B_Register

loc_90ce: // to do
	jmp *

loc_919e: // to do
	jmp *

/*****************************
* Waterfall dispatcher code  *
*****************************/

locret_923e:
	rts


sub_923f:
	// ldb word_5430+1
	lda WORK_RAM2 + $01        // $5431	
	sta B_Register			 // 0x02

	// cmpb #4 / bhi locret_923e
	cmp #$05
	bcs locret_923e           // if B >= 5, then B > 4

	// ldu #$5190
	lda #<WORK_RAM1+$160
	sta U_L
	lda #>WORK_RAM1+$160
	sta U_H

	// ldx #$DABA
	LDX(daba)

	// lda word_543B+1
	lda WORK_RAM2 + $0C

	// asla
	asl                        // word index * 2
	tay

	// jmp [a,x]
	lda (X_L),y
	sta byte_5
	iny
	lda (X_L),y
	sta byte_6
	jmp (byte_5)


loc_9252:
	// lda word_5B11
	lda WATERFALL_TILE

	// cmpa #$77 / bne loc_925d_set77
	cmp #$77
	bne loc_925d_set77

	// ldb #$3E
	lda #$3e
	sta B_Register
	bne loc_925d_store      // always branches

loc_925d_set77:
	// ldb #$77
	lda #$77
	sta B_Register

loc_925d_store:
	// stb word_5B11
	lda B_Register
	sta WATERFALL_TILE

	// lda #$E4
	lda #$e4
	ldy #$0e
	sta (U_L),y

	// ldd word_543D
	lda WORK_RAM2 + $0d     // $543D
	sta A_Register
	lda WORK_RAM2 + $0e     // $543E
	sta B_Register

	// sta 4,u
	lda A_Register
	ldy #$04
	sta (U_L),y

	// stb 6,u
	lda B_Register
	ldy #$06
	sta (U_L),y

	// bra loc_929B
	bra loc_929b
	
loc_926d:
	lda #$e2
	ldy #$0e
	sta (U_L),y

	/* ldd word_543f */
	lda WORK_RAM2+$0f          /* word_543f */
	sta A_Register
	lda WORK_RAM2+$10          /* word_543f+1 */
	sta B_Register

	/* sta 4,u */
	ldy #$04
	lda A_Register
	sta (U_L),y

	/* stb 6,u */
	ldy #$06
	lda B_Register
	sta (U_L),y

	/* subb #6 */
	lda B_Register
	sec
	sbc #$06
	sta B_Register

	/* cmpb #$70 / bhi loc_9280 */
	cmp #$70
	beq loc_9280
	bcs loc_9280

	lda #$8a
	sta B_Register

loc_9280:
	/* std word_543f */
	lda A_Register
	sta WORK_RAM2+$0f
	lda B_Register
	sta WORK_RAM2+$10

	bra loc_929b


loc_9285:
	lda #$e3
	ldy #$0e
	sta (U_L),y

	/* ldd word_5441 */
	lda WORK_RAM2+$11          /* word_5441 */
	sta A_Register
	lda WORK_RAM2+$12          /* word_5441+1 */
	sta B_Register

	/* sta 4,u */
	ldy #$04
	lda A_Register
	sta (U_L),y

	/* stb 6,u */
	ldy #$06
	lda B_Register
	sta (U_L),y

	/* subb #6 */
	lda B_Register
	sec
	sbc #$06
	sta B_Register

	/* cmpb #$70 */
	cmp #$70
	bcc loc_9298

	lda #$8a
	sta B_Register

loc_9298:
	/* std word_5441 */
	lda A_Register
	sta WORK_RAM2+$11          /* word_5441 */
	lda B_Register
	sta WORK_RAM2+$12          /* word_5441+1 */

loc_929b:
	lda #$40
	ldy #$0f
	sta (U_L),y

	inc WORK_RAM2+$0c          /* word_543b+1 */

	lda WORK_RAM2+$0c          /* word_543b+1 */
	cmp #$03
	bcc locret_92ac

	lda #$00
	sta WORK_RAM2+$0c          /* word_543b+1 */

locret_92ac:
	rts

sub_92ad:
    // if F1 != $18 → return
    lda byte_f1
    cmp #$18
    lbne locret_92ec

    // if F2 != $38 → return
    lda byte_f2
    cmp #$38
    lbne locret_92ec

    // B = 0
    lda #0
    sta byte_21

    // Y = 15
    lda #$0F
    sta byte_20

    // X = $5F6D by default
    lda #<SCREEN_BASE + $76D
    sta byte_30
    lda #>SCREEN_BASE + $76D
    sta byte_31

    // if C4 == 1, override X = $5DAD
    lda byte_c4
    cmp #1
    bne loc_92ca    // just skip override, but DO NOT RETURN

    lda #<SCREEN_BASE + $5AD
    sta byte_30
    lda #>SCREEN_BASE + $5AD
    sta byte_31

loc_92ca:
    // U = $DABA
    lda #<daba
    sta byte_46
    lda #>daba
    sta byte_47

    // first call to sub_92df
    jsr sub_92df

    // Y = 19 ($13)
    lda #$13
    sta byte_20

    // X = $5EF1 (default)
    lda #<SCREEN_BASE + $6F1
    sta byte_30
    lda #>SCREEN_BASE + $6F1
    sta byte_31

    // if C4 == 1, X = $5D31
    lda byte_c4
    cmp #1
    bne sub_92df
    lda #<SCREEN_BASE + $531
    sta byte_30
    lda #>SCREEN_BASE + $531
    sta byte_31

// U pointer  = byte_46 (lo), byte_47 (hi)
// X pointer  = byte_30 (lo), byte_31 (hi)
// B register = byte_21
// Y counter  = byte_20
sub_92df:
    // A = B
    lda byte_21

    // A += *--U   (pre-decrement U, then read)
    // U = U - 1
    lda byte_46
    bne u_lo_ok
    dec byte_47
u_lo_ok:
    dec byte_46

    ldy #0
    clc
    adc (byte_46),y    // A = B + *U

    // A -= $30
    sec
    sbc #$30

    // *--X = A   (pre-decrement X, then write)
    // X = X - 1
    lda byte_30
    bne x_lo_ok
    dec byte_31
x_lo_ok:
    dec byte_30

    ldy #0
    sta (byte_30),y

    // B++
    inc byte_21

    // Y--, loop if not zero
    dec byte_20
    bne sub_92df
    rts
	
locret_92ec:
    rts
	

sub_92ed:
	lda #$10				// #16 for what ?

	// suba word_5430+1
	sec
	sbc WORK_RAM2 + $01	// 0x10 - 0x2 ( player id ) = 0xE

	// cmpa #8
	cmp #$08				// 0x2 ( nuncha ) != 0x8 ( sword )
	bne loc_92f7			// not sword ?

	// inca
	clc
	adc #$01				// 0x8 becomes 0x9  when enemy id = 8.

loc_92f7:
	// sta word_51A7
	sta WORK_RAM1 + $177	// nuncha id , this is read at 97C5, seems to be read when an attack is made by player 
	rts
	
loc_92fb: // to do, part of sub_9315
	jmp *
	
loc_92fe: // to do, part of sub_9315
	jmp *

// ------------------------------------------------------------
// sub_9315
// game vars and set up
// inits sprite positions in the game/attract. ( 9315 -> 9415 )
// ------------------------------------------------------------

sub_9315:
	// jsr sub_A270
	jsr sub_a270				// FEEDLE & non FEEDLE

	// jsr sub_92ED
	jsr sub_92ed				// has player jumped, 0-landed, 1-jump, 2-diagonal jump

	// lda WORK_RAM2 + $94
	lda WORK_RAM2 + $94
	bne loc_932d				// handle jump.

	// ldu #$5050
	lda #<WORK_RAM1+$20
	sta U_L
	lda #>WORK_RAM1+$20
	sta U_H

	// lda word_5435
	lda WORK_RAM2 + $05		// is player still alive ? ( e8 = dead )
	bne loc_92fb				// player died, set timer to 0xe8 and count to 0

	// lda word_5435+1
	lda WORK_RAM2 + $06		// is enemy still alive ? 
	bne loc_92fe				// enemy died.

loc_932d:
	// lda WORK_RAM2 + $92
	lda WORK_RAM2 + $92
	sta WORK_RAM2 + $96

	// ldb WORK_RAM2 + $94
	lda WORK_RAM2 + $94
	sta B_Register
	cmp #$02
	beq loc_9386

	// ldb word_5430+1
	lda WORK_RAM2 + $01		// enemy name id
	sta B_Register
	cmp ea1c+1 				// is the enemy FEEDLE ?
	bne loc_936c				// non feedle enemy

	// FEEDLE
	lda WORK_RAM2 + $94		// 0-landed, 1-jump, 2-diagonal jump	
	sta B_Register
	bne loc_9367				// player has jumped

	// jsr sub_9BBC
	jsr sub_9bbc				// player hasn't jumped.

	// cmpa #0
	cmp #$00
	beq loc_9386

	// cmpa #3
	cmp #$03
	bcs loc_9386

loc_9352:
	// ldb WORK_RAM2 + $92+1
	lda WORK_RAM2 + $93
	sta B_Register
	beq loc_935c

	// deca
	dec
	beq loc_9383
	bra loc_9360

loc_935c:
	// cmpa #2
	cmp #$02
	beq loc_9383

loc_9360:
	// lda #1
	lda #$01
	sta WORK_RAM2 + $93
	bne loc_9386

loc_9367:
	// clr WORK_RAM2 + $92+1
	lda #$00
	sta WORK_RAM2 + $93
	bne loc_9386

loc_936c:
	// clr WORK_RAM2 + $92+1
	lda #$00
	sta WORK_RAM2 + $93

	// ldu #$5050
	lda #<WORK_RAM1+$20
	sta U_L
	lda #>WORK_RAM1+$20
	sta U_H

	// ldb 4,u
	ldy #$04
	lda (U_L),y
	sta B_Register

	// cmpb $44,u
	ldy #$44
	cmp (U_L),y
	bcc loc_9386

	// ldb WORK_RAM2 + $94
	lda WORK_RAM2 + $94
	sta B_Register
	bne loc_9386

	// inc WORK_RAM2 + $92+1
	inc WORK_RAM2 + $93
	bne loc_9386

loc_9383:
	// clr WORK_RAM2 + $92+1
	lda #$00
	sta WORK_RAM2 + $93

loc_9386:
	// jsr sub_9BFA
	jsr sub_9bfa

	// lda WORK_RAM2 + $90
	lda WORK_RAM2 + $90
	lbeq loc_9415

	// deca
	dec
	lbne loc_9458
	rts


// ------------------------------------------------------------
// sub_9395
// ------------------------------------------------------------

sub_9395:
	// sta word_54CC+1
	sta WORK_RAM2 + $9d
	lbeq loc_93ff

	// ldx #$E758
	LDX(e758)

	// ldb word_5430+1
	lda WORK_RAM2 + $01
	sta B_Register

	// andb #3
	and #$03
	sta B_Register

	// aslb
	asl
	sta B_Register

	// clra
	lda #$00

	// ldx d,x
	clc
	adc X_L
	sta byte_5
	lda X_H
	adc B_Register
	sta byte_6
	ldy #$00
	lda (byte_5),y
	sta X_L
	iny
	lda (byte_5),y
	sta X_H

	// lda word_5030
	lda WORK_RAM1 + $00
	asl

	// leax a,x
	clc
	adc X_L
	sta X_L
	bcc !+
	inc X_H
	!:

	// lda ,x+
	ldy #$00
	lda (X_L),y
	inc X_L
	bne !+
	inc X_H
	!:

	beq loc_93c9
	cmp #$ff
	beq loc_93ff

	// preserve original A from ,x+
	sta A_Register

	// ldb word_54C2+1
	lda WORK_RAM2 + $93
	sta B_Register
	beq loc_93c9

	// tfr a,b
	sta A_Register
	TFR_A_B()	     // tfr a,b


	// andb #$FC
	lda B_Register
	and #$fc
	sta B_Register
	sta WORK_RAM1 + $1c2

	// anda #3
	lda A_Register
	and #$03
	beq loc_93c6

	// eora #3
	eor #$03
	

loc_93c6:
	ora WORK_RAM1 + $1c2

loc_93c9:
	sta WORK_RAM1 + $1c2
	sta WORK_RAM1 + $1c7

	cmp #$10
	bcc loc_93dd

	// lda  WORK_RAM1 + $00+1
	lda WORK_RAM1 + $01
	bne loc_93dd

	// lda WORK_RAM1 + $1c7
	lda WORK_RAM1 + $1c7
	STA_U_NEG($03)	// -3,u

loc_93dd:
	// lda ,x
	ldy #$00
	lda (X_L),y

	cmp #$ff
	beq loc_93ff

	cmp WORK_RAM1 + $01
	bcc loc_93f7

	inc WORK_RAM1 + $01

loc_93eb:
	lda WORK_RAM2 + $90
	cmp #$02
	lbeq loc_932d
	jmp loc_9462

loc_93f7:
	lda #$00
	sta WORK_RAM1 + $01
	inc  WORK_RAM1 + $00
	bne loc_93eb

loc_93ff:
	inc WORK_RAM2 + $90
	lda #$00
	sta  WORK_RAM1 + $00
	sta WORK_RAM1 + $01

	lda #$01
	sta WORK_RAM2 + $92

	jsr sub_9e4f

	lda #$00
	jsr sub_9979
	rts	
	
/*
	Updates Sprite Coordinates 
*/	
loc_9415:
	
	// ldy #$E7FC
	lda #<e7fc				// sprite frame table.
	sta byte_5
	lda #>e7fc
	sta byte_6

	// ldu #$5050			// work ram address to write to.
	lda #<WORK_RAM1+$20
	sta U_L
	lda #>WORK_RAM1+$20
	sta U_H

	// ldd #$2030
	LDD($2030)				// data to write.

	// sta 6,u				// ypos for oolong
	lda A_Register
	ldy #$06
	sta (U_L),y

	// stb 4,u				// xpos for oolong.
	lda B_Register
	ldy #$04
	sta (U_L),y

	// clra
	// jsr sub_9E1F
	CLRA()
	
	/* preserve original Y=e7fc across sub_9e1f */
	lda byte_5
	pha
	lda byte_6
	pha

	
	jsr sub_9e1f		
	
	/* restore original Y=e7fc */
	pla
	sta byte_6
	pla
	sta byte_5


	// lda #4
	lda #$04
	// sta $A,u
	ldy #$0a
	sta (U_L),y

	/* arcade: sty ,u */
	/* store original frame pointer table address */
	ldy #$00
	lda byte_5
	sta (U_L),y
	iny
	lda byte_6
	sta (U_L),y

	// lda #1
	lda #$01

	// sta $C,u
	ldy #$0c
	sta (U_L),y

	// lda #$FF
	lda #$ff

	// sta $D,u
	ldy #$0d
	sta (U_L),y

	// sta $B,u
	ldy #$0b
	sta (U_L),y

	// clra
	CLRA()

	// jsr sub_9979
	jsr sub_9979

	// clr word_54C4
	lda #$00
	sta WORK_RAM2 + $94

	// clr word_54C0+1
	sta WORK_RAM2 + $91

	// ldu #$5050
	lda #<WORK_RAM1+$20
	sta U_L
	lda #>WORK_RAM1+$20
	sta U_H

	// ldd #$0800
	lda #$08
	sta A_Register
	lda #$00
	sta B_Register

	// std $3A,u
	lda A_Register
	ldy #$3a
	sta (U_L),y
	lda B_Register
	iny
	sta (U_L),y

	// std $3C,u
	lda A_Register
	ldy #$3c
	sta (U_L),y
	lda B_Register
	iny
	sta (U_L),y

	// inc word_54C0
	inc WORK_RAM2 + $90

	// clr word_5435
	lda #$00
	sta WORK_RAM2 + $05

	// clr word_5435+1
	sta WORK_RAM2 + $06
	rts

sub_9953: // to do
	jmp *
	
loc_9458: // to do, part of sub_9315
	jmp *

loc_9462: // to do, part of sub_9315
	jmp *
	
sub_996d:
	// sta 2,u
	ldy #$02
	sta (U_L),y

	// stb 5,u
	lda B_Register
	ldy #$05
	sta (U_L),y

	// clr 3,u
	lda #$00
	ldy #$03
	sta (U_L),y

	// clr 7,u
	ldy #$07
	sta (U_L),y

	// jsr sub_9CF0
	jsr sub_9cf0

locret_9978:
	rts
	
sub_9979:
	// cmpa word_5069
	cmp WORK_RAM1 + $39 // player moved ? 0x1 - left, 0x2 - right, 0x3 - jump, 0xA - punch
	beq loc_9986		// hasn't moved	

	// cmpa #9
	cmp #$09			// Upforward Punch attack ? ( Written at 0x9992 )
	bcs loc_9986		// Upforward Punch attack

	// ldb #$F0
	
	pha
	lda #$f0
	sta B_Register
	ldy #$0b
	sta (U_L),y
	pla

loc_9986:
	/* ldb word_54CE -- preserve A */
	pha
	lda WORK_RAM2+$9e
	sta B_Register
	pla

	lda B_Register
	beq loc_998f

	/* cmpa #8 -- compare original A */
	cmp #$08
	bcc locret_9978

loc_998f:
	/* sta word_5069 -- original A */
	sta WORK_RAM1+$39

sub_9992:
	// ldu #$5050
	lda #<WORK_RAM1 + $20
	sta U_L
	lda #>WORK_RAM1 + $20
	sta U_H

	// ldb word_54C4
	lda WORK_RAM2 + $94
	sta B_Register
	lbne loc_99f6

	// ldb word_54C4+1
	lda WORK_RAM2 + $95
	sta B_Register
	lbne loc_99f6

	// ldb -$10,u
	LDB_U_NEG($10)
    lda B_Register
	sta B_Register
	cmp #$01
	lbne loc_99f6

	// ldb $32,u
	ldy #$32
	lda (U_L),y
	sta B_Register
	lbne loc_99f6

	// lda $19,u
	ldy #$19
	lda (U_L),y
	pha

	// lda #2
	lda #$02

	// sta -$10,u
	STA_U_NEG($10)

	// clr $11,u
	ldy #$11
	lda #$00
	sta (U_L),y

	LDA_U_NEG($20) 				// lda -$20,u
	lda A_Register
	// cmpa #$10
	cmp #$10
	bcc loc_99bf

	// suba #8
	sec
	sbc #$08
	
loc_99bf:
	// cmpa #9
	cmp #$09
	beq loc_99cb

	// cmpa #$0C
	cmp #$0c
	beq loc_99cb

	// cmpa #$0F
	cmp #$0f
	bne loc_99ce
	
loc_99cb:
	// inc $11,u
	INC_U($11)
	
loc_99ce:
	// ldb -$0F,u
	LDB_U_NEG($0f)
	sta B_Register

	// clra
	lda #$00

	// ldy #$E960
	lda #<e960
	sta byte_5
	lda #>e960
	sta byte_6

	// aslb
	lda B_Register
	asl
	sta B_Register

	// leay d,y
	lda B_Register
	clc
	adc byte_5
	sta byte_5
	lda byte_6
	adc #$00
	sta byte_6

	// lda ,y+
	lda byte_5
	sta X_L
	lda byte_6
	sta X_H
	ldy #$00
	lda (X_L),y
	inc X_L
	bne !+
	inc X_H
!:
	lda X_L
	sta byte_5
	lda X_H
	sta byte_6

	jsr sub_9953

	// nega
	eor #$ff
	clc
	adc #$01

	// ldb word_51A5
	sta A_Register
	lda WORK_RAM1 + $175
	sta B_Register

	// stb word_54C2+1
	sta WORK_RAM2 + $93

	// ldb ,y
	lda byte_5
	sta X_L
	lda byte_6
	sta X_H
	ldy #$00
	lda (X_L),y
	sta B_Register

	// jsr sub_996D
	lda B_Register
	jsr sub_996d

	CLR_U_NEG($1e) // clr -$1e,u
	// puls a
	pla
	
loc_99ee:
	// cmpa #9
	cmp #$09
	bcc loc_99f6

	// suba #8
	sec
	sbc #$08

	bra loc_99ee


loc_99f6:
	// sta $35,u
	ldy #$35
	sta (U_L),y
	sta tmp	// preserve our index into table

	// ldu #$5050
	lda #<WORK_RAM1 + $20
	sta U_L
	lda #>WORK_RAM1 + $20
	sta U_H

	// cmpa #9
	cmp #$09
	bcs loc_9a02

	// inc -3,u
	INC_U_NEG($03)

loc_9a02:

	// ldy #$E7C0
	lda #<e7c0
	sta byte_5
	lda #>e7c0
	sta byte_6
	// ldx #$E7FC
	LDX(e7fc) // Player sprite frames
	lda tmp   // restore index into table


	/* asla */
	asl
	sta tmp                 /* save doubled frame index */

	/* leay a,y */
	clc
	lda byte_5
	adc tmp
	sta byte_5
	lda byte_6
	adc #$00
	sta byte_6

	/* leax a,x */
	clc
	lda X_L
	adc tmp
	sta X_L
	lda X_H
	adc #$00
	sta X_H

	// ldd ,x
	ldy #$00
	lda (X_L),y
	sta A_Register
	iny
	lda (X_L),y
	sta B_Register

	// std ,u
	lda A_Register
	ldy #$00
	sta (U_L),y
	lda B_Register
	iny
	sta (U_L),y

	// lda $23,u
	ldy #$23
	lda (U_L),y
	lbne loc_9a46

	// ldd word_54C4
	lda WORK_RAM2 + $94
	sta A_Register
	lda WORK_RAM2 + $95
	sta B_Register
	ora A_Register
	bne loc_9a2c

	// lda $17,u
	ldy #$17
	lda (U_L),y
	cmp #$03
	bcs loc_9a2c

	// cmpa word_54C6
	cmp WORK_RAM2 + $96
	bne loc_9a2c

	// lda $C,u
	ldy #$0c
	lda (U_L),y
	lbne loc_9a46
	
loc_9a2c:
	// lda -$10,u
	LDA_U_NEG($10)
	lda A_Register

	// cmpa #2
	cmp #$02
	beq loc_9a3a

	// lda ,y+
	lda byte_5
	sta X_L
	lda byte_6
	sta X_H
	ldy #$00
	lda (X_L),y
	inc X_L
	bne !+
	inc X_H
!:
	lda X_L
	sta byte_5
	lda X_H
	sta byte_6

	// cmpa #2
	cmp #$02
	bcs loc_9a42
	bra loc_9a3c

loc_9a3a:
	// clr -$10,u
	CLR_U_NEG($10)
loc_9a3c:
	// ldb #$80
	lda #$80
	sta B_Register
	bra loc_9a44

loc_9a42:
	// ldb ,y
	lda byte_5
	sta X_L
	lda byte_6
	sta X_H
	ldy #$00
	lda (X_L),y
	sta B_Register

loc_9a44:
	// std $0C,u
	lda A_Register
	ldy #$0c
	sta (U_L),y
	lda B_Register
	iny
	sta (U_L),y

loc_9a46:
	// clr $23,u
	ldy #$23
	lda #$00
	sta (U_L),y

	// lda #4
	lda #$04

	// sta $0A,u
	ldy #$0a
	sta (U_L),y

	// clra
	lda #$00
	sta A_Register
	// jsr sub_9C19
	jsr sub_9c19
	rts

sub_9bbc:
	// ldx #$51F2
	LDX(WORK_RAM1 + $1c2)

	// clra
	lda #$00
	sta A_Register
	
	// leax a,x
	clc
	adc X_L
	sta X_L
	bcc !+
	inc X_H
!:

	// lda ,x
	ldy #$00
	lda (X_L),y

	// oraa 5,x
	ldy #$05
	ora (X_L),y

	// ldb word_54C2+1
	sta A_Register
	lda WORK_RAM2 + $93
	sta B_Register
	beq loc_9bdf

	// tfr a,b
	lda A_Register
	sta B_Register

	// andb #3
	and #$03
	sta B_Register
	beq loc_9bdf

	// cmpb #2
	cmp #$02
	beq loc_9bdb

	// anda #$FC
	lda A_Register
	and #$fc
	ora #$02
	sta A_Register
	bra loc_9bdf

loc_9bdb:
	// anda #$FC
	lda A_Register
	and #$fc
	ora #$01
	sta A_Register

loc_9bdf:
	// cmpa #$10
	lda A_Register
	cmp #$10
	bcc locret_9bf9

	// tfr a,b
	sta B_Register

	// andb #$0F
	and #$0f
	sta B_Register

	// cmpb #1
	cmp #$01
	beq loc_9bf5

	// cmpb #6
	cmp #$06
	bne locret_9bf9

	// anda #$30
	lda A_Register
	and #$30
	ora #$01
	sta A_Register
	bra locret_9bf9

loc_9bf5:
	// anda #$30
	lda A_Register
	and #$30
	ora #$06
	sta A_Register

locret_9bf9:
	lda A_Register
	rts
	
	
sub_9bfa:
	// jsr sub_9BBC
	jsr sub_9bbc

	// anda #$0F
	and #$0f

	// cmpa #3
	cmp #$03
	bcc loc_9c09

	// deca
	dec

	// cmpa #6
	cmp #$06
	bcc loc_9c09

	// deca
	dec

loc_9c09:
	// sta word_54C2
	sta WORK_RAM2 + $92
	rts
	
sub_9c0d:
	ldy #$35
	lda (U_L),y
	cmp #$0f
	bne !+
	lda #$05
	sta A_Register
!:
	rts


sub_9c19:
	jsr sub_9c0d

	lda A_Register
	pha
	lda U_L
	pha
	lda U_H
	pha

	jsr sub_9e03

	pla
	sta U_H
	pla
	sta U_L
	pla
	sta A_Register

	lda WORK_RAM2+$94
	sta B_Register
	beq loc_9c42

	lda WORK_RAM2+$95
	sta B_Register
	beq loc_9c42

	LDB_U_NEG($0f)
	
	cmp #$09
	bcs loc_9c3d

	lda #$80
	ldy #$0d
	sta (U_L),y
	ldy #$0b
	sta (U_L),y

	lda #$01
	ldy #$0c
	sta (U_L),y

loc_9c3d:
	lda WORK_RAM2+$96
	sta B_Register
	bra loc_9c4a

loc_9c42:
	lda WORK_RAM2+$92
	sta B_Register
	bra loc_9c4a


sub_9c47:
	lda B_Register
	sta WORK_RAM2+$9a

loc_9c4a:
	pha
	ldy #$0c
	lda (U_L),y
	beq loc_9c53
	lda B_Register
	ldy #$2b
	sta (U_L),y
loc_9c53:
	pla
	sta A_Register

	ldy #$00
	lda (U_L),y
	sta X_L
	iny
	lda (U_L),y
	sta X_H

	lda B_Register
	lbeq loc_9cb2

	lda A_Register
	ldy #$1b
	sta (U_L),y

	ldy #$0a
	lda (U_L),y
	ldy #$1a
	sta (U_L),y

	ldy #$0c
	lda (U_L),y
	ldy #$1c
	sta (U_L),y
	lbeq loc_9cda

	LDY(WORK_RAM2+$a0)

loc_9c6e:
	ldy #$1b
	lda (U_L),y
	asl
	tax
	lda e79d,x
	sta X_L
	lda e79d+1,x
	sta X_H

	lda Y_L
	sta WORK_RAM2+$c4
	lda Y_H
	sta WORK_RAM2+$c5

loc_9c7b:
	lda WORK_RAM2+$c4
	sta Y_L
	lda WORK_RAM2+$c5
	sta Y_H

	lda byte_0
	pha
	lda byte_1
	pha

	ldy #$00
	lda (X_L),y
	INC16(X_L, X_H)
	asl
	sta byte_0

	clc
	lda Y_L
	adc byte_0
	sta Y_L
	lda Y_H
	adc #$00
	sta Y_H

	ldy #$00
	lda (U_L),y
	sta byte_1
	iny
	lda (U_L),y
	sta byte_2

	ldy #$00
	lda (byte_1),y
	sta A_Register
	iny
	lda (byte_1),y
	sta B_Register

	lda B_Register
	eor #$40
	sta B_Register

	STD_PTR(Y_L)

	ldy #$00
	lda (U_L),y
	sta B_Register
	iny
	lda (U_L),y
	sta A_Register

	clc
	lda B_Register
	adc #$02
	sta B_Register
	lda A_Register
	adc #$00
	sta A_Register

	ldy #$00
	lda B_Register
	sta (U_L),y
	iny
	lda A_Register
	sta (U_L),y

	ldy #$1a
	lda (U_L),y
	sec
	sbc #$01
	sta (U_L),y
	lbne loc_9c7b

	ldy #$1c
	lda (U_L),y
	sec
	sbc #$01
	sta (U_L),y
	lbeq loc_9caf

	ldy #$0a
	lda (U_L),y
	ldy #$1a
	sta (U_L),y

	LDY(WORK_RAM2+$a0)

	ldy #$0a
	lda (U_L),y
	asl
	sta A_Register

	ldy #$0c
	lda (U_L),y
	sta B_Register
	ldy #$1c
	lda B_Register
	sec
	sbc (U_L),y
	sta B_Register

	MUL()

	clc
	lda Y_L
	adc B_Register
	sta Y_L
	lda Y_H
	adc A_Register
	sta Y_H

	pla
	sta byte_1
	pla
	sta byte_0

	lbra loc_9c6e


loc_9caf:
	pla
	sta byte_1
	pla
	sta byte_0

	LDX(WORK_RAM2+$a0)

loc_9cb2:
	ldy #$0d
	lda (U_L),y
	ldy #$0b
	clc
	adc (U_L),y
	sta (U_L),y
	lbcc loc_9ce4

	ldy #$0c
	lda (U_L),y
	lbeq loc_9cda

	sec
	sbc #$01
	sta (U_L),y
	sta A_Register

	ldy #$0a
	lda (U_L),y
	asl
	sta B_Register

	MUL()

	clc
	lda X_L
	adc B_Register
	sta X_L
	lda X_H
	adc A_Register
	sta X_H

	ldy #$0a
	lda (U_L),y
	sta byte_48

	lda U_L
	sta Y_L
	lda U_H
	sta Y_H

/*

Write player sprite frames to sprite ram

*/
loc_9ccc:
	ldy #$00
	lda (X_L),y
	ldy #$0e
	sta (Y_L),y
	INC16(X_L, X_H)

	ldy #$00
	lda (X_L),y
	ldy #$0f
	sta (Y_L),y
	INC16(X_L, X_H)

	ADDY($0010)

	dec byte_48
	bne loc_9ccc

loc_9cda:
	BR_IF_U_NE(WORK_RAM1+$20, locret_9ce3)
	sta WORK_RAM1+$1c
locret_9ce3:
    rts

loc_9ce4:
	BR_IF_U_NE(WORK_RAM1+$20, locret_9ce3)
	lda #$01
	sta WORK_RAM1+$1c
    rts

	
sub_9cf0: // to do
	jmp *
	
loc_9d13: // to do
	jmp *
	
	
sub_9d4d:
	ldy #$18
	lda A_Register
	sta (U_L),y

	lda B_Register
	cmp #$01
	bne loc_9d5c

	ldy #$11
	lda (U_L),y
	eor #$01
	sta (U_L),y

loc_9d5c:
	BR_IF_U_NE(WORK_RAM1+$20, loc_9d66)
	LDA_U_NEG($8)	// lda     -8,u
	lbne loc_9ddc
	

loc_9d66:
	ldy #$05
	lda (U_L),y          /* ldb 5,u */

	ldy #$08
	clc
	adc (U_L),y          /* addb 8,u */
	sta (U_L),y          /* stb 8,u */
	sta B_Register
	bcc loc_9d79         /* same as 6809: branch if no carry */

	ldy #$11
	lda (U_L),y
	bne loc_9d77

	INC_U($04)
	bra loc_9d79

loc_9d77:
	DEC_U($04)
	
loc_9d79:
	BR_IF_U_NE(WORK_RAM1+$20, loc_9d91)

	ldy #$04
	lda (U_L),y
	sta B_Register

	cmp #$d1
	bcc loc_9d89

	lda #$d0
	sta B_Register
	bra loc_9d8f

loc_9d89:
	cmp #$10
	bcs loc_9d91

	lda #$10
	sta B_Register

loc_9d8f:
	ldy #$04
	lda B_Register
	sta (U_L),y
	
loc_9d91:
	ldy #$11
	lda (U_L),y
	sta B_Register
	bne loc_9daf

loc_9d96:
	ldy #$02
	lda (U_L),y
	sta B_Register

	cmp #$d1
	bcc loc_9da1

	lda #$00
	sec
	sbc B_Register
	sta B_Register

	ldy #$02
	lda B_Register
	sta (U_L),y

	bra loc_9daf


loc_9da1:
	ldy #$04
	lda (U_L),y
	clc
	adc B_Register
	sta B_Register

	BR_IF_U_NE(WORK_RAM1+$20, loc_9dc8)

	lda B_Register
	cmp #$10
	bcc loc_9dd8
	bra loc_9dc8
	
loc_9daf:
	ldy #$02
	lda (U_L),y
	sta B_Register
	cmp #$d1
	bcc loc_9dba

	lda #$00
	sec
	sbc B_Register
	sta B_Register

	ldy #$02
	lda B_Register
	sta (U_L),y
	bra loc_9d96
	
loc_9dba:
	ldy #$04
	lda (U_L),y
	sta B_Register

	ldy #$02
	sec
	sbc (U_L),y
	sta B_Register

	BR_IF_U_NE(WORK_RAM1+$20, loc_9dc8)

	lda B_Register
	cmp #$d1
	bcs loc_9dd2
	
loc_9dc8:
	BR_IF_U_NE(WORK_RAM1+$20, loc_9dda)

	lda B_Register
	cmp #$11
	bcs loc_9dd4

loc_9dd2:
	lda #$10
	sta B_Register

loc_9dd4:
	lda B_Register
	cmp #$d0
	bcc loc_9dda
	
loc_9dd8:
	lda #$d0
	sta B_Register

loc_9dda:
	ldy #$04
	lda B_Register
	sta (U_L),y

	
loc_9ddc:
	ldy #$07
	lda (U_L),y
	sta B_Register

	ldy #$09
	clc
	adc (U_L),y
	sta B_Register
	sta (U_L),y
	bcc loc_9def

	ldy #$10
	lda (U_L),y
	bne loc_9ded

	INC_U($06)
	bra loc_9def
	
loc_9ded:
	DEC_U($06)
	
loc_9def:
	ldy #$10
	lda (U_L),y
	bne loc_9dfa

	ldy #$03
	lda (U_L),y
	sta B_Register

	ldy #$06
	clc
	adc (U_L),y
	sta B_Register
	bra loc_9dfe
	
loc_9dfa:
	ldy #$06
	lda (U_L),y
	sta B_Register

	ldy #$03
	sec
	sbc (U_L),y
	sta B_Register

loc_9dfe:
	ldy #$06
	lda B_Register
	sta (U_L),y

	ldy #$18
	lda (U_L),y
	sta A_Register
	rts

sub_9e03:
    lda A_Register
    cmp #$05
    bcs sub_9e1f

    lda WORK_RAM2+$94
    sta B_Register
    beq loc_9e18

    lda WORK_RAM2+$95
    sta B_Register
    beq loc_9e18

    lda WORK_RAM2+$97
    sta B_Register
    beq sub_9e1f

    bra loc_9e1d

loc_9e18:
    lda WORK_RAM2+$93
    sta B_Register
    beq sub_9e1f

loc_9e1d:
    lda A_Register
    clc
    adc #$01
    sta A_Register

sub_9e1f:
	TFR_A_B()	               // tfr a,b

	// count = E9C3[original_a]
	lda B_Register
	tax
	lda e9c0+3,x
	pha

	// y = word table E9CA[original_a]
	lda B_Register
	asl
	tax
	lda e9ca,x
	sta Y_L
	lda e9ca+1,x
	sta Y_H

	// loop count in B
	pla
	sta A_Register
	TFR_A_B()

	TFR_U_X()

	sec
	lda X_L
	sbc #$10
	sta X_L
	lda X_H
	sbc #$00
	sta X_H

loc_9e3a:
	ldy #$00
	lda (Y_L),y
	INC16(Y_L, Y_H)

	ldy #$04
	clc
	adc (U_L),y

	ldy #$14
	sta (X_L),y

	ldy #$00
	lda (Y_L),y
	INC16(Y_L, Y_H)

	ldy #$06
	clc
	adc (U_L),y

	ldy #$16
	sta (X_L),y

	ADDX($0010)

	dec B_Register
	bne loc_9e3a

	rts
	
sub_9e4f: // to do, part of sub_9315
	jmp *
	
/*******************
* Draw Energy Bars *
*******************/
	
sub_9ea5:
	lda WORK_RAM2+$98      // word_54c8
	bne loc_9eb9

	lda WORK_RAM2+$06      // word_5435+1
	bne loc_9eb9

	lda WORK_RAM2+$05      // word_5435
	bne loc_9eb9

	lda WORK_RAM2+$9d      // word_54cc+1
	beq loc_9ebd

loc_9eb9:
	jsr sub_a7cb			// draws energy bars.
	rts

loc_9ebd:
	jsr sub_d3b8			// partially implemented.

	lda WORK_RAM2+$95      // word_54c4+1
	beq loc_9ec8

	lda #$00
	sta WORK_RAM1+$1f2     // word_5221+1

loc_9ec8:
    jsr sub_a270

	lda #<WORK_RAM1+$20    // $5050
	sta U_L
	lda #>WORK_RAM1+$20
	sta U_H

	CLR_U_NEG($0e)			// -$0e,u

	lda WORK_RAM2+$94      // word_54c4
	bne loc_9ed7

	CLR_U_NEG($0b)			// -$0b,u


loc_9ed7:
	jsr sub_a668 			//  energy bars.
	lda WORK_RAM2+$95      // word_54c4+1
	bne loc_9ee2
	CLR_Y($29)				// $29,y
	
	
loc_9ee2:
	lda WORK_RAM2+$98      // word_54c8
	beq loc_9eff

	lda WORK_RAM2+$01      // word_5430+1
	sta B_Register
	cmp ea1c+1
	bne loc_9ef7

	lda WORK_RAM2+$98      // word_54c8
	cmp #$10
	BCS(loc_a1eb)
	bra loc_9f0b
	
loc_9ef7:
    cmp #$40
    BCS(loc_a1eb)
    bra loc_9f0b


loc_9eff:
    LDX(WORK_RAM1)
    jsr sub_a21a

    ADDX($0010)
    jsr sub_a21a

loc_9f0b:
	lda #$00
	sta WORK_RAM2+$98      // word_54c8

	ldy #$29
	lda (U_L),y
	lbne locret_a1c9

	lda WORK_RAM2+$01      // word_5430+1
	tay
	LDX(f2f5+2)
	lda (X_L),y

	ldy #$37
	sta (U_L),y

	lda #<WORK_RAM1+$20    // $5050
	sta U_L
	lda #>WORK_RAM1+$20
	sta U_H

	lda WORK_RAM2+$95      // word_54c4+1
	lbeq loc_9fdc

	lda WORK_RAM2+$98      // word_54c8
	lbne loc_9fe2

	ldy #$35
	lda (U_L),y
	cmp #$0c
	lbeq loc_9f45

	cmp #$14
	lbeq loc_9f45

	ldy #$32
	lda (U_L),y
	cmp #$05
	BCC(loc_9fdc)
	
loc_9f45:
	ldy #$0c
	lda (U_L),y
	lbne loc_9fdc

	lda WORK_RAM2+$94      /* word_54c4 */
	bne loc_9f56

	LDA_U_NEG($10)         /* -$10,u */
	lbeq loc_9fdc
	
loc_9f56:
	/* ldu word_54e4 */
	lda WORK_RAM2+$b4
	sta U_L
	lda WORK_RAM2+$b5
	sta U_H

	ldy #$2b
	lda (U_L),y
	sta B_Register

	/* ldu #$5050 */
	lda #<WORK_RAM1+$20
	sta U_L
	lda #>WORK_RAM1+$20
	sta U_H

	ldy #$25
	lda B_Register
	sta (U_L),y

	ldy #$2b
	lda (U_L),y
	sta B_Register

	ldy #$eb              /* $ffeb,u */
	lda B_Register
	sta (U_L),y

	ldy #$35
	lda (U_L),y
	sta B_Register

	lda B_Register
	sec
	sbc #$09
	sta B_Register
	BCS(loc_9fdc)

	jsr sub_a22b

	lda WORK_RAM2+$e5     /* word_5515 */
	sta B_Register

	LDY(ea9d)

	CLRA()
	ASLB()

	/* ldy d,y */
	clc
	lda Y_L
	adc B_Register
	sta tmp
	lda Y_H
	adc A_Register
	sta tmp+1

	ldy #$00
	lda (tmp),y
	sta Y_L
	iny
	lda (tmp),y
	sta Y_H

	lda #$0a
	sta A_Register

	/* pshs x */
	lda X_L
	pha
	lda X_H
	pha

	/* ldx word_54e4 */
	lda WORK_RAM2+$b4
	sta X_L
	lda WORK_RAM2+$b5
	sta X_H

	ldy #$0c
	lda (X_L),y
	sta B_Register
	beq !skip_puls_x+

	/* puls x */
	pla
	sta X_H
	pla
	sta X_L

!skip_puls_x:
	MUL()

	clc
	lda Y_L
	adc B_Register
	sta Y_L
	lda Y_H
	adc A_Register
	sta Y_H

	lda #$00
	STA_U_NEG($07)	/* -7,u */

	jsr sub_a2f2
	cmp #$01
	lbne loc_9fe2

	LDY(WORK_RAM1)	// $5030

	lda #<WORK_RAM1+$20
	sta U_L
	lda #>WORK_RAM1+$20
	sta U_H

	lda WORK_RAM2+$01     /* word_5430+1 */
	sta B_Register
	cmp ea1c+1
	bne loc_9fb2

	/* pshs u */
	lda U_L
	pha
	lda U_H
	pha

	lda #$01
	sta B_Register

	/* ldu word_54e4 */
	lda WORK_RAM2+$b4
	sta U_L
	lda WORK_RAM2+$b5
	sta U_H

	ldy #$30
	lda B_Register
	sta (U_L),y

	/* puls u */
	pla
	sta U_H
	pla
	sta U_L
	
loc_9fb2:
	lda #$01
	sta B_Register

	lda B_Register
	sta WORK_RAM1+$19      /* word_5049 */

	ldy #$2b
	lda (U_L),y
	sta B_Register

	jsr sub_a598

	lda #<WORK_RAM1+$20
	sta U_L
	lda #>WORK_RAM1+$20
	sta U_H

	INC_U($29)

	lda #$00
	sta WORK_RAM2+$e6      /* word_5515+1 */

	inc WORK_RAM2+$98      /* word_54c8 */

	ldy #$3a
	lda (U_L),y
	sta A_Register
	iny
	lda (U_L),y
	sta B_Register

	sec
	lda B_Register
	sbc #$00
	sta B_Register
	lda A_Register
	sbc #$01
	sta A_Register

	ldy #$3a
	lda A_Register
	sta (U_L),y
	iny
	lda B_Register
	sta (U_L),y
	BCC(loc_9fe2)

	lda #$00
	ldy #$3a
	sta (U_L),y
	iny
	sta (U_L),y

	bra loc_9fe2
	
loc_9fdc:
	LDX(WORK_RAM1)
	jsr sub_a21a
	
loc_9fe2:
	jsr sub_a238
	lda WORK_RAM2+$06      // word_5435+1
	lbne loc_a08b

	lda WORK_RAM2+$98      // word_54c8
	lbne loc_a08b

	// ldu word_5446
	lda WORK_RAM2+$16
	sta U_L
	lda WORK_RAM2+$17
	sta U_H

	ldy #$2b
	lda (U_L),y
	sta B_Register

	// ldu #$5050
	lda #<WORK_RAM1+$20
	sta U_L
	lda #>WORK_RAM1+$20
	sta U_H

	ldy #$2b
	lda (U_L),y
	ldy #$25
	sta (U_L),y

	lda B_Register
	ldy #$eb              // $ffeb,u
	sta (U_L),y

	jsr sub_a238

	cmp #$01
	lbne loc_a072

	lda WORK_RAM2+$e6      // word_5515+1
	lbne loc_a08b

	// pshs u
	lda U_L
	pha
	lda U_H
	pha

	// ldu word_5446
	lda WORK_RAM2+$16
	sta U_L
	lda WORK_RAM2+$17
	sta U_H

	ldy #$0c
	lda (U_L),y

	// puls u
	sta A_Register
	pla
	sta U_H
	pla
	sta U_L

	lda A_Register
	lbne loc_a072

	lda WORK_RAM2+$99      // word_54c8+1
	lbne loc_a08b

	LDX(ea38)
	lda B_Register
	tay
	lda (X_L),y

	asl
	sta A_Register

	LDX(ea93)
	clc
	lda X_L
	adc A_Register
	sta X_L
	lda X_H
	adc #$00
	sta X_H

	ldy #$35
	lda (U_L),y
	sta B_Register

	LDY(f167)

	lda #$00
	sta A_Register

	lda B_Register
	asl
	sta B_Register

	/* ldy d,y */
	clc
	lda Y_L
	adc B_Register
	sta tmp
	lda Y_H
	adc A_Register
	sta tmp+1

	ldy #$00
	lda (tmp),y
	sta Y_L
	iny
	lda (tmp),y
	sta Y_H

	ldy #$0c
	lda (U_L),y
	beq loc_a04d

	lda WORK_RAM2+$94
	beq loc_a045

	cmp #$02
	BCS(loc_a04d)


loc_a045: // to do
	jmp *
	
loc_a04d:
	lda #$0a
	sta B_Register
	MUL()

	clc
	lda Y_L
	adc B_Register
	sta Y_L
	lda Y_H
	adc A_Register
	sta Y_H

	lda #$03   
	STA_U_NEG($07) /* -7,u */
	
	jsr sub_a2ca
	cmp #$01
	bne loc_a08b

	LDY(WORK_RAM1+$10)	// $5040

	lda WORK_RAM2+$16     /* word_5446 */
	sta U_L
	lda WORK_RAM2+$17
	sta U_H

	lda #$00
	sta WORK_RAM1+$19     /* word_5049 */

	ldy #$2b
	lda (U_L),y
	sta B_Register

	jsr sub_a58e
	jsr sub_a1ca
	bra loc_a08b

loc_a072:
	lda WORK_RAM2+$98          /* word_54c8 */
	bne loc_a08b

	lda WORK_RAM2+$94          /* word_54c4 */
	bne loc_a08b

	lda #$00
	sta WORK_RAM2+$e6          /* word_5515+1 */
	sta WORK_RAM2+$99          /* word_54c8+1 */
	sta WORK_RAM2+$9c          /* word_54cc */

    LDX(WORK_RAM1+$10)						// $5040
    jsr sub_a21a
   
	
loc_a08b:
	CLR_U_NEG($07)                /* clr -7,u */

	DEC_U($37)
	BEQ(locret_a1c9)
	
	lda WORK_RAM2+$01             /* word_5430+1 */
	cmp ea1c+2						// ea1e
	bne loc_a0a3

	lda WORK_RAM1+$c3             /* word_50f3 */
	lbne locret_a1c9
	
loc_a0a3:
	lda WORK_RAM2+$95             /* word_54c4+1 */
	lbeq loc_a12a

	ldy #$0c
	lda (U_L),y
	lbne loc_a12a

	ldy #$35
	lda (U_L),y
	sta B_Register
	sec
	sbc #$09
	sta B_Register
	BCS(loc_a12a)

	jsr sub_a22b

	LDY(WORK_RAM1+$c0)		// $50f0

	ldy #$37
	lda (U_L),y
	sec
	sbc #$01

	lda #$10
	sta B_Register
	MUL()

	ADDY_D()

	ldy #$2b
	lda (U_L),y
	ldy #$eb                  /* $ffeb,u */
	sta (U_L),y

	ldy #$00
	lda (Y_L),y
	sta B_Register

	lda WORK_RAM2+$01         /* word_5430+1 */
	cmp ea1c+2					// ea1e - Star ??
	beq loc_a0d7

	lda B_Register
	eor #$01
	sta B_Register

loc_a0d7: // to do - Star ???
	jmp *

loc_a12a: // to do
	jmp *

loc_a1eb: // to do
    jmp *
	
locret_a1c9:
	rts
	
sub_a1ca:
	jmp *
	
sub_a21a:
	lda #$00
	sta WORK_RAM2+$98      // word_54c8

loc_a21d:
	ldy #$04
	sta (X_L),y

	ldy #$06
	sta (X_L),y
    rts
	
sub_a22b: // to do
	jmp *

sub_a238:

	lda WORK_RAM2+$b4      // word_54e4
	sta X_L
	lda WORK_RAM2+$b5
	sta X_H

	lda WORK_RAM2+$01      // word_5430+1
	cmp ea1c+1
	bne loc_a258

	LDX(WORK_RAM1+$a0)   // $50d0
	lda #$03
	sta B_Register
	
loc_a248:
	ldy #$32
	lda (X_L),y
	beq loc_a252

	ldy #$33
	lda (X_L),y
	bra loc_a25b

loc_a252:
	ADDX($0040)
	DEC_B()
	BNE(loc_a248)

loc_a258:
	lda WORK_RAM2+$e5      // word_5515

loc_a25b:
	lda X_L
	sta WORK_RAM2+$16      // word_5446
	lda X_H
	sta WORK_RAM2+$17

	lda #$28
	sta B_Register
	LDX(ea61)

loc_a263:
	lda B_Register
	tay
	dey                     /* convert 6809 1-based loop counter to 0-based index */
	lda (X_L),y
	cmp A_Register
	beq loc_a26c

	DEC_B()
	BNE(loc_a263)

	CLRA()
	rts

loc_a26c:
	DEC_B()
	lda #$01
	sta A_Register
	rts



sub_a270:
	// ldy #$5090
	lda #<WORK_RAM1+$60
	sta byte_5
	lda #>WORK_RAM1+$60
	sta byte_6

	// lda word_5430+1
	lda WORK_RAM2 + $01	// enemy name index, 0x2 for nucha

	// cmpa word_EA1C+1
	cmp ea1c+1				// is enemy feedle ?
	lbne loc_a2b4			// nope

	// ldy #$50D0
	lda #<WORK_RAM1+$a0
	sta byte_5
	lda #>WORK_RAM1+$a0
	sta byte_6

	// lda #$FF
	lda #$ff
	sta byte_ad

	// ldu #$5050
	lda #<WORK_RAM1+$20
	sta U_L
	lda #>WORK_RAM1+$20
	sta U_H

	// ldx #$50D0
	LDX(WORK_RAM1+$a0)

	// ldb #3
	lda #$03
	sta B_Register

loc_a28c:
	// lda 4,u
	ldy #$04
	lda (U_L),y
	sta A_Register

	// tst word_54C2+1
	lda WORK_RAM2 + $93
	beq loc_a295

	// adda #$10
	lda A_Register
	clc
	adc #$10
	sta A_Register

loc_a295:
	// suba 4,x
	lda A_Register
	pha
	ldy #$04
	lda (X_L),y
	sta tmp
	pla
	sec
	sbc tmp
	sta A_Register
	bcs loc_a2a1

	// tst word_54C2+1
	lda WORK_RAM2 + $93
	bne loc_a2ae

	// coma
	lda A_Register
	eor #$ff
	sta A_Register
	bra loc_a2a6

loc_a2a1:
	// tst word_54C2+1
	lda WORK_RAM2 + $93
	beq loc_a2ae

loc_a2a6:
	// cmpa $AD
	lda A_Register
	cmp byte_ad
	bcs loc_a2ae

	// sta $AD
	sta byte_ad

	// tfr x,y
	lda X_L
	sta byte_5
	lda X_H
	sta byte_6

loc_a2ae:
	// leax $40,x
	ADDX($40)

	// decb
	dec B_Register
	bne loc_a28c

loc_a2b4:
	// sty word_54E4
	lda byte_5
	sta WORK_RAM2 + $b4
	lda byte_6
	sta WORK_RAM2 + $b5

	// lda word_5430+1
	lda WORK_RAM2 + $01

	// cmpa word_EA1C+1
	cmp ea1c+1
	bne locret_a2c5

	// lda #1
	lda #$01

	// sta $31,y
	ldy #$31
	sta (byte_5),y

locret_a2c5:
	rts
	
sub_a2ca:
	ldy #$06
	lda (U_L),y
	sta A_Register

	ldy #$04
	lda (U_L),y
	sta B_Register

	ldy #$38
	lda A_Register
	sta (U_L),y
	iny
	lda B_Register
	sta (U_L),y

	/* pshs u */
	lda U_L
	pha
	lda U_H
	pha

	/* ldu word_5446 */
	lda WORK_RAM2+$16
	sta U_L
	lda WORK_RAM2+$17
	sta U_H

	ldy #$06
	lda (U_L),y
	sta A_Register

	ldy #$04
	lda (U_L),y
	sta B_Register

	/* puls u */
	pla
	sta U_H
	pla
	sta U_L

	ldy #$27
	lda A_Register
	sta (U_L),y
	iny
	lda B_Register
	sta (U_L),y

	lda #$05
	sta B_Register

	lda WORK_RAM2+$01      /* word_5430+1 */
	cmp ea1c
	bne loc_a2f0

	lda WORK_RAM1+$89      /* word_50b9 */
	cmp #$0a
	beq sub_a307

loc_a2f0:
	jmp loc_a309
	
sub_a2f2: // to do
	jmp *
	
sub_a307:
	lda	#5
	
loc_a309: // to do and test
	ldy #$2c
	lda B_Register
	sta (U_L),y

	lda #$01
	//sta -9,u
	STA_U_NEG($09)	/* -9,u */

loc_a310:
    lda #$02
	sta byte_ab

	ldy #$00
	lda (X_L),y
	INX16()
	clc
	ldy #$27
	adc (U_L),y
	ldy #$2d
	sta (U_L),y

	CLRA()

	ldy #$00
	lda (Y_L),y
	sta B_Register

	/* pshs y */
	lda Y_L
	pha
	lda Y_H
	pha

	LDY(f0b0+3) // $f0b3

	ASLB()

	clc
	lda Y_L
	adc B_Register
	sta Y_L
	lda Y_H
	adc A_Register
	sta Y_H

	ldy #$00
	lda (Y_L),y
	INY16()
	clc
	ldy #$38
	adc (U_L),y
	ldy #$2d
	sec
	sbc (U_L),y
	bcc loc_a333
	eor #$ff

loc_a333:
	CMPA_U_NEG($09) /* -9,u */
	BCC(loc_a57d)

loc_a339:
	ldy #$00
	lda (X_L),y

	ldy #$eb              /* $ffeb,u */
	lda (U_L),y
	sta B_Register
	cmp #$01
	bne loc_a35b

	lda #$20
	LDB_U_NEG($07)			/* -7,u */
	beq loc_a351

	lda WORK_RAM2+$e5     /* word_5515 */
	sta B_Register
	cmp #$29
	BCS(loc_a351)

	lda #$20
	clc
	adc #$10

loc_a351:           
	LDB_U_NEG($0e)			/* -$0e,u */
	cmp #$01
	bne loc_a359

	lda #$10

loc_a359:
	ldy #$00
	sec
	sbc (X_L),y

loc_a35b:
	LDB_U_NEG($07)			/* -7,u */
	bne loc_a36f

	ldy #$35
	lda (U_L),y
	sta B_Register
	cmp #$0f
	bne loc_a36f

	ldy #$eb              /* $ffeb,u */
	lda (U_L),y
	sta B_Register
	cmp #$01
	beq loc_a36f

	clc
	adc #$10

loc_a36f:
	ldy #$28
	clc
	adc (U_L),y
	ldy #$2d
	sta (U_L),y

	/* restore original Y for the second half */
	pla
	sta Y_H
	pla
	sta Y_L

	ldy #$00
	lda (Y_L),y
	sta A_Register

	ldy #$25
	lda (U_L),y
	sta B_Register
	cmp #$01
	bne loc_a3a2

	lda #$20
	LDB_U_NEG($07)         /* -7,u */
	bne loc_a38f

	lda WORK_RAM2+$e5     /* word_5515 */
	sta B_Register
	cmp #$29
	BCS(loc_a398)

	lda #$20
	clc
	adc #$10
	bra loc_a398
	
loc_a38f: // to do
	jmp *
	
loc_a398: // to do
	jmp *
	
loc_a3a2: // to do
	jmp *
	
loc_a57d:
	/* puls y */
	pla
	sta Y_H
	pla
	sta Y_L


	/* leay 2,y */
	ADDY($0002)

	/* leax -1,x */
	DEX16()

	/* dec $2c,u */
	DEC_U($2c)
	BNE(loc_a310)

loc_a58a:
	lda #$00
	sta byte_a9

	CLRA()
	rts


sub_a58e: // to do
	jmp *

sub_a598:	// to do
	jmp *

sub_a663: // to do, part of loc_8fd7
	jmp *
	
	
/**********************
* Draw player 1 health*
***********************/
	

sub_a668:
	ldy #$3c
	lda (U_L),y
	sta B_Register
	beq loc_a688

	lda B_Register
	cmp #$04
	BCC(loc_a684)

	lda B_Register
	cmp byte_a8
	bne loc_a688

	dec byte_a8

	lda B_Register
	cmp #$03
	BCS(loc_a688)

	DEC_B()
	ASLB()

	LDX(ea0e)

	// jsr [b,x]
	clc
	lda X_L
	adc B_Register
	sta tmp
	lda X_H
	adc #$00
	sta tmp+1

	ldy #$00
	lda (tmp),y
	sta tmp+2
	iny
	lda (tmp),y
	sta tmp+3
	jmp (tmp+2)

loc_a684:
	lda #$03
	sta byte_a8

loc_a688:
	lda #<WORK_RAM1+$20
	sta U_L
	lda #>WORK_RAM1+$20
	sta U_H

	LDX(ArcadeToMegaTextByte($599f))

	lda #$0f
	sta A_Register

	ldy #$3c
	lda (U_L),y
	sta B_Register

loc_a693:
    lda B_Register
	beq loc_a69c

	DEX16()
	DEX16()
	ldy #$00
	lda A_Register
	sta (X_L),y

	DEC_B()
	BNE(loc_a693)
	bra loc_a6a3

loc_a69c:
	ldy #$3d
	lda (U_L),y
	sta B_Register
	lbeq loc_a733

loc_a6a3:
	// set colour ptrs
	lda #$F8
	sta COLPTR2
	lda #$0F
	sta COLPTR3
	
	lda #$06
	sta A_Register

	ldy #$3d
	lda (U_L),y
	sta B_Register

	jsr sub_a6c0
	
	//lda #$80			   // Flip X is 0x80 on arcade.
	//lda #$40			   // Flip X is 0x40 on the Meg65.
	//ldy #$fd              // -3,x
	//sta (X_L),y
	
	// SCREEN_BASE+1 is required because the arcade code positions X on the
	// attribute byte lane, while MEGA65 colour RAM corresponds to the tile
	// cell byte. The +1 realigns the colour write with the correct cell.
	
	// MEGA65 colour RAM for the left energy-bar cap is aligned at
	// X - (SCREEN_BASE + 2), not a literal arcade-style -3,X.
	// This compensates for the different screen/colour byte layouts.

	sec
	lda X_L
	sbc #<(SCREEN_BASE+1)
	sbc #$01	
	sta COLPTR0
	lda X_H
	sbc #>(SCREEN_BASE+1)
	sbc #00
	sta COLPTR1

	ldz #$00
	lda #$40                // MEGA65 Flip X
	sta ((COLPTR0)),z

	
	CMPX(ArcadeToMegaTextByte($5991)) //$5991
	BCS(loc_a6c9)

	DEX16()
	lda B_Register
	ldy #$00
	sta (X_L),y

	lda #$0b
	sta A_Register

loc_a6b7:
	CMPX(ArcadeToMegaTextByte($5991)) //$5991
	BCS(loc_a6c9)

	DEX16()
	lda A_Register
	ldy #$00
	sta (X_L),y
	bra loc_a6b7
	
/**********************
* Draw player 2 health*
***********************/

sub_a6c0:
	
	lda B_Register
	and #$c0
	sta B_Register

loc_a6c2:
	lda B_Register
	lsr
	sta B_Register

	DEC_A()
	BNE(loc_a6c2)

	lda B_Register
	clc
	adc #$0b
	sta B_Register
	rts


loc_a6c9:
	LDX(ArcadeToMegaTextByte($59a3))

	lda #$0f
	sta A_Register

	ldy #$3a
	
	lda (U_L),y
	sta B_Register
	

loc_a6d1:
	lda B_Register
	beq loc_a6da

	ldy #$00
	lda A_Register
	sta (X_L),y

	INX16()
	INX16()

	DEC_B()
	BNE(loc_a6d1)

	jmp loc_a6df


loc_a6da:
	ldy #$3b
	lda (U_L),y
	sta B_Register
	lbeq loc_a6f9


loc_a6df:
	lda #$06
	sta A_Register

	ldy #$3b
	lda (U_L),y
	sta B_Register

	jsr sub_a6c0

	CMPX(ArcadeToMegaTextByte($59b3))
	BCC(locret_a6f8)

	ldy #$00
	lda B_Register
	sta (X_L),y

	INX16()
	INX16()

	lda #$0b
	sta A_Register

loc_a6ef:
	CMPX(ArcadeToMegaTextByte($59b3))
	BCC(locret_a6f8)

	ldy #$00
	lda A_Register
	sta (X_L),y

	INX16()
	INX16()

	jmp loc_a6ef
	
locret_a6f8:
    rts

loc_a6f9: // to do
    jmp *
	
loc_a700:
	lda #$80
	sta WORK_RAM2+$06      // word_5435+1

	jsr loc_c6ae

	lda #$00
	sta WORK_RAM2+$92      // word_54c2
	sta WORK_RAM1+$37      // byte_5067
	sta WORK_RAM1+$39      // word_5069
	sta WORK_RAM2+$95      // word_54c4+1
	sta WORK_RAM2+$e6      // word_5515+1
	sta WORK_RAM1+$00      // word_5030
	sta WORK_RAM1+$01      // word_5030+1

	lda #$0b
	ldy #$00
	sta (X_L),y
	INX16()
	INX16()


loc_a721:
	lda WORK_RAM2+$06      // word_5435+1
	cmp #$01
	beq loc_a72f

	dec WORK_RAM2+$06      // word_5435+1
	jsr sub_a7b0
	rts


loc_a72f:
	lda #$00
	sta WORK_RAM2+$90      // word_54c0
	rts

/*

Player got hit ?

*/

loc_a733:  // to do
	jmp *
	
sub_a737: // to do
	jmp *

sub_a7b0: // to do
    jmp *

	
/*******************
* Draw Energy Bars *
*******************/
	
sub_a7cb:
	lda #$00
	sta WORK_RAM2+$98      // word_54c8

	LDX(WORK_RAM1)			// $5030
	jsr sub_a21a

	ldy #$14
	lda #$00
	sta (X_L),y

	ldy #$16
	sta (X_L),y
	rts


	
loc_a7db:
    lda #$10
    sta B_Register

    LDX(WORK_RAM2+$D0)	  // $5500

loc_a7e0:
    ldy #0
    lda #0
    sta (X_L),y          	// clr ,x+
    INC16(X_L, X_H)

    dec B_Register
    bne loc_a7e0

    inc WORK_RAM2+$D1    // word_5500+1  ($5501)
	
    LDX(WORK_RAM1+$60)	  // $5090

    lda #$20
    sta A_Register
    lda #$c0
    sta B_Register

    // sta 6,x
    clc
    lda X_L
    adc #6
    sta byte_5
    lda X_H
    adc #0
    sta byte_6
    ldy #0
    lda A_Register
    sta (byte_5),y

    // stb 4,x
    clc
    lda X_L
    adc #4
    sta byte_5
    lda X_H
    adc #0
    sta byte_6
    ldy #0
    lda B_Register
    sta (byte_5),y

    lda #$09
    sta A_Register
    lda #$06
    sta B_Register
	
loc_a7f5:
    // sta $e,x
    clc
    lda X_L
    adc #$0e
    sta byte_5
    lda X_H
    adc #$00
    sta byte_6
    ldy #0
    lda A_Register
    sta (byte_5),y

    // leax $10,x
    ADDX($10)

    dec B_Register
    bne loc_a7f5

    inc WORK_RAM2+$D4      // word_5504
    inc WORK_RAM2+$D0      // word_5500

    lda WORK_RAM2+$01      // word_5430+1
    cmp #4
    bne loc_a81d

    LDY(WORK_RAM1+$A0)	// $50d0
    jsr sub_b566

    ADDY($40)
    jsr sub_b566

    ADDY($40)
    jsr sub_b566

loc_a81d:
	lda #6
	sta WORK_RAM2+$DC      // word_550C

	jsr sub_c3e6
	cmp #4
	lbne loc_a857

	LDX(WORK_RAM1+$60)	// $5090

	lda #$20
	STA_X_OFFS($06)
	lda #$30
	STA_X_OFFS($26)
	lda #$20
	STA_X_OFFS($16)
	lda #$30
	STA_X_OFFS($36)

	lda #$f0
	STA_X_OFFS($24)
	STA_X_OFFS($04)

	lda #$b0
	STA_X_OFFS($0e)
	STA_X_OFFS($1e)

	lda #$af
	STA_X_OFFS($2e)
	STA_X_OFFS($3e)

	lda #$40
	STA_X_OFFS($0f)
	STA_X_OFFS($2f)
    rts
	
loc_a857:
	jsr sub_c3e6	
	beq locret_a86c

	cmp #3
	beq locret_a86c

	cmp #5
	beq locret_a86c

	cmp #8
	beq locret_a86c

	jsr sub_b682

locret_a86c:
    rts

sub_a86d:		
	jsr sub_c3e6
	CLRB()  				// clrb

	lda A_Register        // tsta
	beq loc_a889
	sec
	sbc #$03              // suba #3
	beq loc_a888

	sec
	sbc #$01              // deca
	beq loc_a885

	sec
	sbc #$01              // deca
	beq loc_a886

	cmp #$03
	beq loc_a887
	jmp loc_b6ed


loc_a885:
	inc B_Register

loc_a886:
	inc B_Register

loc_a887:
	inc B_Register

loc_a888:
	inc B_Register

	jmp loc_a889
	
loc_a889:
	lda B_Register
	sta WORK_RAM2+$d7      // word_5506+1

	lda byte_e2     		// byte_51e2
	beq loc_a8c1

	lda WORK_RAM2+$02      // word_5432
	sec
	sbc #$01
	bne loc_a8c1

	lda byte_ef    		// word_51ef ( lives )
	lsr
	lsr
	lsr
	lsr
	and #$03
	beq loc_a8a3
	sec
	sbc #$01

loc_a8a3:
	lda WORK_RAM1+$5a      // word_508a
	cmp #$04
	bcs loc_a8ab
	clc
	adc #$01
	
loc_a8ab:
	lda WORK_RAM2+$09      // word_5439
	cmp #$04
	bcc loc_a8bd
	cmp #$08
	bcc loc_a8bc
	cmp #$10
	bcc loc_a8bb
	clc
	adc #$01
	
loc_a8bb:
	clc
	adc #$01
	
loc_a8bc:
	clc
	adc #$01

loc_a8bd:
	cmp #$04
	bcc loc_a8c3

	
loc_a8c1:
	lda #$03

loc_a8c3:
	sta WORK_RAM2+$df      // word_550f

	LDY(WORK_RAM1+$60)

	lda WORK_RAM2+$d7      // word_5506+1
	cmp #$04
	lbne loc_a8d4
	ADDY($0040)
	
loc_a8d4:
	lda WORK_RAM2+$05      // word_5435+1
	lbeq loc_a942

	lda WORK_RAM2+$98      // word_54c8
	lbne loc_a942

	// yes, ROM tests word_54c8 twice
	lda WORK_RAM2+$98      // word_54c8
	lbne loc_a942

	lda WORK_RAM2+$e6      // word_5515+1
	lbne loc_a942

	lda #$20
	ldy #$06
	sta (Y_L),y

	lda WORK_RAM2+$d7      // word_5506+1
	cmp #$04
	bne loc_a905

	lda WORK_RAM2+$05      // word_5435+1
	cmp #$01
	beq locret_a941
	jmp loc_a942

loc_a905:
	ldy #$12
	lda #$00
	sta (Y_L),y

	lda WORK_RAM2+$d7
	cmp #$03
	bne loc_a915
	jsr sub_b359
	ldy #$66
	lda #$00
	sta (Y_L),y
	
loc_a915:
	jmp *					// implement later
	lda WORK_RAM2+$d7      /* word_5506+1 */
	sta tmp
	LDU(f368)              /* table base */
	//LDX(f492)          /* required by later code */
	lda tmp
	asl
	tay

	lda (U_L),y
	sta tmp
	iny
	lda (U_L),y
	sta U_H
	lda tmp
	sta U_L

	lda #$00
	ldy #$15
	sta (Y_L),y

	lda WORK_RAM2+$d7
	cmp #$04
	beq loc_a934

	LDD($0940)

	ldy #$4e
	lda A_Register
	sta (Y_L),y
	iny
	lda B_Register
	sta (Y_L),y

	ldy #$5e
	lda A_Register
	sta (Y_L),y
	iny
	lda B_Register
	sta (Y_L),y
	
loc_a934:
	jsr sub_abe9

	lda WORK_RAM2+$05      // word_5435+1
	cmp #$70
	bne locret_a941

	jsr loc_c696

locret_a941:
	rts

loc_a942:
	lda WORK_RAM2+$d7          // word_5506+1
	cmp #$04
	lbeq loc_aa47

	lda WORK_RAM2+$98          // word_54c8
	lbne loc_ab66

	lda #$00
	sta WORK_RAM2+$d9          // word_5508

	lda WORK_RAM2+$05          // word_5435+1
	lbne loc_aa47

	cmp #$01
	bne loc_a9d3

	lda WORK_RAM2+$02          // word_5432
	cmp #$12
	bcc loc_a96f

	ldy #$0c
	lda (Y_L),y
	bne loc_a983

	bra loc_a976


loc_a96f:
	ldy #$3c
	lda (Y_L),y
	bne loc_a9d3        // lbne loc_a9d3

loc_a976:
	ldy #$29
	lda (Y_L),y
	cmp #$04
	bcc loc_a983        // bcs loc_a983
	cmp #$07
	lbcc loc_aa47        // lbcs loc_aa47

loc_a983:
	lda WORK_RAM1+$161      // word_5190+1
	bne loc_a9a2

	lda WORK_RAM2+$d6       // word_5506
	cmp #$02
	bcs loc_aa47

	lda WORK_RAM1+$39       // word_5069
	cmp WORK_RAM1+$160      // word_5190
	beq loc_a9ef

	sta WORK_RAM1+$160      // word_5190

	cmp #$09
	bcc loc_a9d3

loc_a9a2:
	inc WORK_RAM1+$161      // word_5190+1

	jsr sub_b665

	ldy #$13
	lda (Y_L),y
	sta WORK_RAM1+$168      // word_5197+1

	lda WORK_RAM1+$161      // word_5190+1
	sta B_Register
	cmp #$10
	bne loc_a9cc

	lda #$00
	sta WORK_RAM1+$161      // word_5190+1

	lda #$05
	ldy #$29
	sta (Y_L),y

	lda #$00
	ldy #$12
	sta (Y_L),y

	jsr sub_b665
	jsr sub_ae4f

	lda #$ff
	ldy #$0b
	sta (Y_L),y

	bra loc_aa3f
	
loc_a9cc:
	lda #$09
	ldy #$29
	sta (Y_L),y

	bra loc_aa39


loc_a9d3:
	lda WORK_RAM2+$de      // word_550d
	beq loc_a9ef

	lda WORK_RAM2+$02      // word_5432
	cmp #$12
	bcs loc_aa47

	lda WORK_RAM2+$d7      // word_5506+1
	sec
	sbc #$01
	sec
	sbc #$01
	bne loc_a9eb

	lda WORK_RAM1+$163     // word_5192+1
	bne loc_aa47

loc_a9eb:
	ldy #$0c
	lda (Y_L),y
	beq loc_aa47

loc_a9ef:  // to do
	jmp *
	
loc_aa39:  // to do
	jmp *
	
loc_aa3f: // to do
	jmp *

loc_aa47:  // to do
    jmp *

loc_ab66:  // to do
    jmp *

sub_abe9:  // to do
	jmp *
	
sub_ae3f:  // to do
	jmp *
	
sub_ae4f:  // to do
	jmp *

loc_8f5b: // to do
	jmp *
	
sub_b359:  // to do
	jmp * 

sub_b566: // to do 
	jmp *
	
sub_b665: // to do
	jmp *
	 
		
sub_b682:
	lda #$10
	sta B_Register

	LDX(WORK_RAM2+$e0) // $5510

loc_b687:
	ldy #$00
	lda #$00
	sta (X_L),y

	INX16()

	DEC_B()
	BNE(loc_b687)

	LDX(WORK_RAM1+$60) //$5090
	LDY(WORK_RAM1+$70) //$50a0
	
loc_b693:
	
	ldy #$00
	lda #$00
	sta (X_L),y

	INX16()

	CMPX(WORK_RAM1+$f0) //$5120
	BNE(loc_b693)

	lda byte_ef     		/* word_51ef */ 
	and #$30
	lsr
	lsr
	lsr
	sta WORK_RAM2+$e0      /* word_550f+1 */

	lda WORK_RAM2+$02      /* word_5432 */	  // 01
	cmp #$12
	bcc loc_b6b1			// use native compare flags instead of BCS ( emulated ) . bcs -> bcc

	lda #$ff
	sta WORK_RAM2+$e0      /* word_550f+1 */

loc_b6b1:
	LDD($a020)
	STA_Y_NEG($0c)			// sta     -$C,y
	STB_Y_NEG($0a)			// stb     -$A,y

	jsr sub_c3e2

	lda #<WORK_RAM1+$d0   /* $5100 */
	sta U_L
	lda #>WORK_RAM1+$d0
	sta U_H

	lda #$e6
	sta B_Register
	
	lda A_Register
	cmp #$04
	beq loc_b6c6

	lda #$c4
	sta B_Register

loc_b6c6:
	INC_U_NEG($05)			/* -5,u */
	INC_U($0b)
	INC_U($1b)

	TFR_B_A()

	lda #$01
	sta B_Register

	STD_U_NEG($02)         /* -2,u */
	
	ldy #$0e
	lda A_Register
	sta (U_L),y
	iny
	lda B_Register
	sta (U_L),y

	ldy #$1e
	lda A_Register
	sta (U_L),y
	iny
	lda B_Register
	sta (U_L),y

	jsr sub_c173

	inc WORK_RAM2+$e4     /* byte_5514 */

	LDD($0330)

	ldy #$05
	lda A_Register
	sta (Y_L),y

	lda B_Register
	sta WORK_RAM2+$ea     /* word_551a */

	INC_A()
	lda A_Register
	sta WORK_RAM2+$ed     /* word_551c+1 */

	jmp loc_b85c
	

loc_b6ed:
	lda #$00
	sta WORK_RAM2+$e9      // byte_5519
	sta WORK_RAM2+$ea      // word_551a+1

	lda WORK_RAM1+$1c2     // word_51f2 . written from 0x8c8b..etc
	//lda $02f2
	
	cmp WORK_RAM2+$ec      // word_551c
	beq loc_b6fe

	inc WORK_RAM2+$ea      // word_551a+1

loc_b6fe:
	lda WORK_RAM2+$e0      // word_550f+1
	cmp #$ff
	beq loc_b71e

	lda WORK_RAM2+$0a      // word_5439+1
	bne loc_b71e

	inc WORK_RAM2+$e0      // word_550f+1

	lda WORK_RAM2+$07      // word_5437
	cmp #$4b
	bne loc_b71e

	lda WORK_RAM2+$e0      // word_550f+1
	clc
	adc #$08
	bcc loc_b71e

	sta WORK_RAM2+$e0      // word_550f+1

loc_b71e:
	
	lda WORK_RAM1+$24        // word_5054
	sta A_Register
	TFR_A_B()	               // tfr a,b

	sec
	sbc WORK_RAM2+$ea        // word_551a

	cmp #$04
	bcc loc_b733

	cmp #$fd
	bcs loc_b733

	lda WORK_RAM2+$95        // word_54c4+1
	bne loc_b736
	
loc_b733:
	lda B_Register
	sta WORK_RAM2+$ea      // word_551a

loc_b736:
	LDY(WORK_RAM1+$70)

	lda WORK_RAM2+$05      // word_5435
	beq loc_b741

	ldy #$02
	lda #$00
	sta (Y_L),y
	

loc_b741:
	ldy #$05
	lda (Y_L),y
	cmp #$07
	beq loc_b75f

	lda WORK_RAM2+$98      // word_54c8
	bne loc_b762

	ldy #$38
	lda #$00
	sta (Y_L),y

	TST_Y_NEG($04)			// -4,y
	lbeq loc_b7c6

loc_b755:
	ldy #$02
	lda (Y_L),y
	beq loc_b75c
	jmp loc_b884
	

loc_b75c: 
    jsr sub_c188 			
loc_b75f:
	
	jmp	loc_b974
	
loc_b762:
	lda WORK_RAM2+$e2      // word_5511
	cmp #$01
	bne loc_b774

	lda #$00
	sta WORK_RAM2+$e2      // word_5511

	lda #$fe
	sta WORK_RAM1+$0e      // word_503d+1

	inc WORK_RAM1+$5a      // word_508a

loc_b774:
	jsr sub_c3e2
	cmp #$01
	bne loc_b781

	ldy #$05
	lda (Y_L),y
	cmp #$08
	beq loc_b788
	
loc_b781:
	CLR_Y_NEG($04)			// -4,y

	lda #$ff
	ldy #$1c
	sta (Y_L),y
	
loc_b788: // to do
	lda WORK_RAM2+$e6      // word_5515+1
	lbne loc_b7b7

	ldy #$40
	lda (Y_L),y
	bne loc_b79b

	INC_Y($40)

	lda WORK_RAM1+$1c2     // word_51f2
	ldy #$3d
	sta (Y_L),y
	
loc_b79b:
	ldy #$35
	lda #$00
	sta (Y_L),y

	jsr sub_c159

	ldy #$2b
	lda (Y_L),y
	beq loc_b7ad

	lda #$00
	sta (Y_L),y

	INC_Y_NEG($0C) // -$0c,y
	
	bra loc_b7b2
	
loc_b7ad:
	INC_Y($2b)
	DEC_Y_NEG($0c)	// -$0c,y

loc_b7b2:
	jsr sub_c112
	lbra loc_b75f

loc_b7b7:
	ldy #$38
	lda (Y_L),y
	bne locret_b7c5

	INC_Y($38)

	jsr sub_c159

	ldy #$35
	lda #$00
	sta (Y_L),y

locret_b7c5:
	rts
	
	
loc_b7c6:
	lda WORK_RAM2+$e4      // byte_5514
	bne loc_b7de

	ldy #$1d
	lda (Y_L),y
	ldy #$1c
	clc
	adc (Y_L),y
	sta (Y_L),y
	lbcc loc_b755

	inc WORK_RAM2+$e9      // byte_5519

	ldy #$1c
	lda #$00
	sta (Y_L),y
	
loc_b7de:
	lda #$00
	sta WORK_RAM2+$e4      // byte_5514

	lda #$ff
	STA_Y_NEG($05)			// sta -5,y

	lda WORK_RAM2+$06      // word_5435+1
	beq loc_b7f8

	jsr loc_c696

	LDY(WORK_RAM1+$70)
	lda #$07
	ldy #$05
	sta (Y_L),y

	jmp loc_b96b
	
loc_b7f8:
	ldy #$30
	lda (Y_L),y
	beq loc_b815

	lda #$00
	sta (Y_L),y

	jsr sub_c3e2
	cmp #$02
	bne loc_b80d

	ldy #$05
	lda (Y_L),y
	cmp #$09
	beq loc_b815

loc_b80d:
	ldy #$31
	lda (Y_L),y
	STA_Y_NEG($0c)			// sta     -$C,y

	jsr sub_c112
	
loc_b815:
	ldy #$02
	lda (Y_L),y
	lbne loc_b881

	LDX(f8dd)

	lda WORK_RAM2+$05      // word_5435
	bne loc_b82a

	jsr sub_c3e2
	cmp #$03
	bne loc_b87b
	bra loc_b834
	
loc_b82a: // to do
	jmp *
	
loc_b834: // to do
	jmp *
	
loc_b85a:
	INC_Y($03) // inc     3,y
	
loc_b85c:
	//rts
	jsr sub_c3a9
	jsr sub_c3d1
	jsr sub_c280
	jmp loc_b873


loc_b867:
	jsr loc_c68e
	LDY(WORK_RAM1+$70)	//$50a0
	jmp loc_b85a
	
loc_b873:
	jmp loc_b974


loc_b876:
	lda WORK_RAM2+$05      /* word_5435 */
	bne loc_b873


loc_b87b:
	INC_Y($02)
	CLR_Y($03)
	jmp loc_b873


loc_b881:
	jsr sub_c173

loc_b884:
	jsr sub_c3e2
	cmp #$01
	bne loc_b88e
	jmp loc_bc13


loc_b88e:
	LDX(WORK_RAM2+$e0)			//$5510

	lda #<f908
	sta U_L
	lda #>f908
	sta U_H

	asl

	/* jmp [a,u] */
	clc
	lda U_L
	adc A_Register
	sta byte_5
	lda U_H
	adc #$00
	sta byte_6

	ldy #$00
	lda (byte_5),y
	sta byte_7
	iny
	lda (byte_5),y
	sta byte_8

	jmp (byte_7)
	


loc_b96b: // to do
	jmp *
	
loc_b974:
	jsr sub_c3e2
	
	cmp #$05
	lbeq loc_ba2f

	cmp #$04
	beq loc_b982

	rts
	
loc_b982:
	lda #<WORK_RAM1+$c0      // $50f0
	sta U_L
	lda #>WORK_RAM1+$c0
	sta U_H
	

loc_b985:

	ldy #$05
	lda (Y_L),y
	cmp #$08
	lbcc loc_b9cc

	cmp #$0b
	lbcs loc_b9cc

	ldy #$0b
	lda (U_L),y
	lbne loc_b9cc

	LDA_Y_NEG($04)			 // -4,y
	lbne loc_b9cc

	ldy #$07
	lda (U_L),y
	lbeq loc_b9cc

	lda #$00
	sta WORK_RAM1+$a7
	sta WORK_RAM1+$b7
	sta WORK_RAM1+$c7

	LDB_Y_NEG($0a)			// -$0a,y

	INC_U($0b)

	pha
	lda B_Register
	pha
	lda Y_L
	pha
	lda Y_H
	pha
	lda U_L
	pha
	lda U_H
	pha

	jsr loc_c69a

	pla
	sta U_H
	pla
	sta U_L
	pla
	sta Y_H
	pla
	sta Y_L
	pla
	sta B_Register
	pla

	dec A_Register
	beq loc_b9bb

	dec A_Register
	beq loc_b9b7

	lda B_Register
	sec
	sbc #$0e
	sta B_Register

loc_b9b7:
	lda B_Register
	clc
	adc #$08
	sta B_Register
	bra loc_b9bd

loc_b9bb:
	lda B_Register
	clc
	adc #$16
	sta B_Register

loc_b9bd:
	ldy #$06
	lda B_Register
	sta (U_L),y

	ldy #$f4
	lda (Y_L),y
	sec
	sbc #$08

	ldy #$18
	lda (Y_L),y
	sta B_Register
	beq loc_b9ca

	lda A_Register
	clc
	adc #$20

loc_b9ca:
	ldy #$04
	sta (U_L),y
	
loc_b9cc:

	ldy #$03
	lda (U_L),y
	beq loc_b9d6

	lda #$00
	sta (U_L),y

	ldy #$06
	sta (U_L),y

	ldy #$07
	sta (U_L),y
	
loc_b9d6:

	INC_U($01)

	ldy #$01
	lda (U_L),y
	cmp #$02
	lbne loc_b9f8

	lda #$00
	sta (U_L),y

	ldy #$0d
	lda (U_L),y
	INC_U($0d)
	INC_U($0d)

	LDX(f914)

	lda (X_L),y
	sta A_Register
	iny
	lda (X_L),y
	sta B_Register

	LDX(WORK_RAM2 + $e0)

	ldy #$0e
	lda A_Register
	sta (U_L),y
	iny
	lda B_Register
	sta (U_L),y

	cmp #$e7
	bne loc_b9f8

	lda B_Register
	cmp #$81
	bne loc_b9f8

	lda #$00
	ldy #$0d
	sta (U_L),y
	
loc_b9f8:

	lda #$01

	ldy #$00
	lda (U_L),y
	beq loc_ba00

	lda #$ff

loc_ba00:

	ldy #$04
	clc
	adc (U_L),y
	sta (U_L),y

	lda #$40
	ldy #$02
	clc
	adc (U_L),y
	sta (U_L),y
	bcc loc_ba16

	INC_U($04)

	ldy #$00
	lda (U_L),y
	beq loc_ba16

	DEC_U($04)
	DEC_U($04)
	
loc_ba16:

	cmp #$f0
	bcc loc_ba1c

	lda #$00
	ldy #$06
	sta (U_L),y

loc_ba1c:

	cmp #$08
	bcs loc_ba22

	lda #$00
	ldy #$06
	sta (U_L),y
	
loc_ba22:

	lda U_L
	cmp #<WORK_RAM1 + $e0 // $5110
	bne !+
	lda U_H
	cmp #>WORK_RAM1 + $e0 // $5110
	beq locret_ba2e
!:

	ADDU($0010)
	jmp loc_b985


locret_ba2e:
    rts

loc_ba2f: // to do
	jmp *
	
loc_bc13: // to do
	jmp *
	
sub_c112:
	jmp * // to do
	
sub_c159: // to do
    jmp *
	
sub_c173:
	LDD($0900)
	STD_Y_NEG($02)			/* -2,y */

	CMPY(WORK_RAM1+$c0)	//$50f0
	BNE(loc_c183)

	LDY(WORK_RAM1+$70)	//$50a0
	rts
	
loc_c183:
	ADDY($0010)
	bra sub_c173
	
sub_c188:
	ldy #$12
	lda (Y_L),y			// reads 0x1 from 0x50b2
	sta A_Register
	ldy #$01
	sta (Y_L),y			// writes 0x01 to 0x50a1

	LDD_Y_OFF($10)

	STD_Y_NEG($10)			/* std -$10,y */

	ldy #$17
	lda (Y_L),y
	sta A_Register
	iny
	lda (Y_L),y
	sta B_Register

	TFR_Y_U()
	LEAU_SUB($0010)

	jsr sub_9d4d
	
	LDY(WORK_RAM1+$70)
	TFR_Y_U()
	LEAU_SUB($0010)

	ldy #$12
	lda (Y_L),y
	ldy #$01
	sta (Y_L),y

	ldy #$10
	lda (Y_L),y
	sta A_Register
	iny
	lda (Y_L),y
	sta B_Register

	STD_Y_NEG($10)			/* std -$10,y */

	ldy #$17
	lda (Y_L),y
	sta A_Register
	iny
	lda (Y_L),y
	sta B_Register

	jsr sub_9c47

	LDY(WORK_RAM1+$70)

	ldy #$32
	lda (Y_L),y
	beq locret_c1fa

	LDA_Y_NEG($0c)			/* lda -$0c,y */
	lda A_Register
	clc
	adc #$01
	
	pha
	ldy #$18
	lda (Y_L),y
	beq !minus2+
	pla
	bra loc_c1c8

!minus2:
	pla
	sec
	sbc #$02

loc_c1c8:
	jmp *

locret_c1fa:
    rts
	
sub_c280:
	CLR_Y($40)

	jsr sub_c3e2
	cmp #$03
	bne loc_c294

	ldy #$05
	lda (Y_L),y
	cmp #$08
	beq loc_c298
	cmp #$09
	beq loc_c298

loc_c294:
	lda #$ff
	STA_Y_NEG($05)            /* sta -5,y */

loc_c298:
	jsr sub_c3e2
	asl
	sta tmp                 /* preserve table offset */

	LDX(f9ab)

	lda tmp
	tay

	lda (X_L),y
	sta U_L
	iny
	lda (X_L),y
	sta U_H

	lda #$0a
	sta B_Register

	ldy #$05
	lda (Y_L),y
	MUL()

	clc
	lda U_L
	adc B_Register
	sta U_L
	lda U_H
	adc A_Register
	sta U_H

	/* ldd ,u++ */
	ldy #$00
	lda (U_L),y
	sta A_Register
	iny
	lda (U_L),y
	sta B_Register
	ADDU($0002)

	ldy #$10
	lda A_Register
	sta (Y_L),y
	iny
	lda B_Register
	sta (Y_L),y

	ldy #$02
	lda (Y_L),y
	bne loc_c2b9

	CLR_Y_NEG($0e)            /* clr -$0e,y */
	CLR_Y_NEG($0b)            /* clr -$0b,y */
	ADDU($0002)
	jmp loc_c2bf

loc_c2b9:
	/* ldd ,u++ */
	ldy #$00
	lda (U_L),y
	sta A_Register
	iny
	lda (U_L),y
	sta B_Register
	ADDU($0002)

	STA_Y_NEG($0e)            /* sta -$0e,y */
	STB_Y_NEG($0b)            /* stb -$0b,y */

loc_c2bf:
	/* ldd ,u++ */
	ldy #$00
	lda (U_L),y
	sta A_Register
	iny
	lda (U_L),y
	sta B_Register
	ADDU($0002)

	STA_Y_NEG($06)            /* sta -6,y */
	ldy #$17
	lda B_Register
	sta (Y_L),y

	/* ldd ,u++ */
	ldy #$00
	lda (U_L),y
	sta A_Register
	iny
	lda (U_L),y
	sta B_Register
	ADDU($0002)

	STD_Y_NEG($04)            /* std -4,y */

	ldy #$1d
	lda B_Register
	sta (Y_L),y

	ldy #$25
	lda (Y_L),y
	beq loc_c2d4

	DEC_Y_NEG($04)            /* dec -4,y */

loc_c2d4:
	CLR_Y($25)
	lda #$00
	sta WORK_RAM2+$ef         /* word_551f */

	jsr sub_c3e2
	cmp #$02
	bcs loc_c307              /* 6809 bcc => A >= 2 */

	ldy #$05
	lda (Y_L),y
	cmp #$04
	bcc loc_c307              /* 6809 bcs => A < 4 */

	jsr sub_c3e2
	cmp #$01
	bne loc_c2f8

	ldy #$05
	lda (Y_L),y
	cmp #$09
	beq loc_c2fe
	cmp #$0a
	beq loc_c2fe

loc_c2f8:
	ldy #$05
	lda (Y_L),y
	cmp #$07
	bcs loc_c307              /* 6809 bcc => A >= 7 */

loc_c2fe:
	inc WORK_RAM2+$ef         /* word_551f */

	LDB_Y_NEG($03)            /* ldb -3,y */
	lda B_Register
	clc
	adc #$0f
	sta B_Register
	STB_Y_NEG($03)            /* stb -3,y */

loc_c307:
	/* ldd ,u */
	ldy #$00
	lda (U_L),y
	sta A_Register
	iny
	lda (U_L),y
	sta B_Register

	lda A_Register
	sta WORK_RAM2+$e5         /* word_5515 */

	lda B_Register
	pha
	jsr sub_c3e2
	pla
	sta B_Register

	cmp #$02
	bne loc_c32a

	ldy #$05
	lda (Y_L),y
	cmp #$09
	beq loc_c321
	cmp #$08
	bne loc_c32a

loc_c321:
	lda WORK_RAM1+$55         /* word_5085 */
	cmp #$0f
	beq loc_c32a

	lda B_Register
	sec
	sbc #$10
	sta B_Register

loc_c32a:
	ldy #$33
	lda B_Register
	sta (Y_L),y

	jsr sub_c3e2
	cmp #$02
	beq loc_c33c
	cmp #$03
	beq loc_c33c
	cmp #$05
	bne loc_c354

loc_c33c:
	ldy #$05
	lda (Y_L),y
	cmp #$04
	bcc loc_c354              /* 6809 bcs => A < 4 */
	cmp #$07
	bcs loc_c354              /* 6809 bcc => A >= 7 */

	lda WORK_RAM2+$02         /* word_5432 */
	cmp #$12
	bcc loc_c354              /* 6809 bcs => A < $12 */

	lda #$20
	LDA_Y_NEG($03)            /* adda -3,y */
	clc
	adc A_Register
	STA_Y_NEG($03)
	rts

loc_c354:
	lda WORK_RAM2+$ef         /* word_551f */
	lbeq locret_c3a8

	jsr sub_c3e2
	cmp #$01
	lbne loc_c39b

	lda WORK_RAM2+$02         /* word_5432 */
	cmp #$12
	bcs loc_c36e              /* 6809 bcc => A >= $12 */

	lda WORK_RAM1+$5a         /* word_508a */
	sta B_Register
	cmp #$05
	bcs loc_c380              /* 6809 bcc => B >= 5 */

loc_c36e:
	lda #$28
	LDA_Y_NEG($03)
	clc
	adc A_Register
	STA_Y_NEG($03)

	lda B_Register
	cmp #$04
	bcs loc_c380              /* 6809 bcc => B >= 4 */

	ldy #$1d
	lda (Y_L),y
	clc
	adc #$01
	sta (Y_L),y

loc_c380:
	lda WORK_RAM2+$02         /* word_5432 */
	cmp #$12
	bcs loc_c39b              /* 6809 bcc => A >= $12 */

	lda WORK_RAM1+$5c         /* word_508c */
	cmp #$04
	bcs loc_c39b              /* 6809 bcc => A >= 4 */

	sec
	sbc WORK_RAM1+$5a         /* suba word_508a */
	bcs loc_c39b              /* 6809 bcc => result >= 0 */

	cmp #$fe
	bcs loc_c39b              /* 6809 bcc => A >= $fe */

	lda #$10
	STA_Y_NEG($03)

loc_c39b:
	lda WORK_RAM2+$e0         /* word_550f+1 */
	cmp #$03
	bcc locret_c3a8           /* 6809 bcs => A < 3 */

	lda #$09
	LDA_Y_NEG($03)
	clc
	adc A_Register
	STA_Y_NEG($03)

locret_c3a8:
    rts
	
sub_c3a9:
	CLR_Y($18)

	lda WORK_RAM2+$ea      /* word_551a */

	LDA_Y_NEG($0c)         /* lda -$0c,y */
	lda A_Register
	sta tmp

	lda WORK_RAM2+$ea
	sec
	sbc tmp
	lbcc loc_c3de

	INC_Y($18)

loc_c3b6:
	ldy #$19
	sta (Y_L),y

	jsr sub_c3e2

	cmp #$01
	beq locret_c3d0

	cmp #$04
	bcs locret_c3d0

	ldy #$18
	lda (Y_L),y
	beq locret_c3d0

	ldy #$19
	lda (Y_L),y
	sec
	sbc #$10
	sta (Y_L),y

locret_c3d0:
	rts

sub_c3d1:
	CLR_Y($12)

	ldy #$05
	lda (Y_L),y
	cmp #$01
	beq locret_c3dd

	INC_Y($12)

locret_c3dd:
	rts
	

loc_c3de:
    jmp *

sub_c3e2: 
	lda #$01
	sta B_Register
	bra loc_c3e7

sub_c3e6:
	CLRB()
loc_c3e7:
	lda WORK_RAM2+$01      // word_5430+1 - value: 0x02
	sta A_Register         // save default return value

	lda B_Register
	beq locret_c3f6

	// pushes 5120 on arcade. Mega b120 ( correct ).
	lda X_L
	pha
	lda X_H
	pha

	LDX(ff39)
	lda A_Register		// contains 0x2.
	tay					
	lda (X_L),y		// 0x3 correct.
	sta A_Register

	// restore 0x5120 / 0xB120
	pla
	sta X_H
	pla
	sta X_L

locret_c3f6:
	lda A_Register
	rts
	
loc_c67a:	// to do
	lda #$1
	jmp	loc_c6c3

loc_c68e:	// to do
	jmp *
	
loc_c692: // to do	
	jmp *

loc_c696:	// to do	
	jmp *
	
loc_c69a: // to do
	jmp *
	

loc_c6a2: // to do
	jmp *
	
loc_c6b2: // to do
	jmp *
	
loc_c6b6:	// to do
	jmp *
	
// to do	
loc_c6a6:
	lda #$41
	jmp loc_c6c3
	

loc_c6aa: // to do
	jmp *

loc_c6ae: // to do
    jmp *


// to do
loc_c6be:
	jmp *
	
loc_c6c3:
	pha                        // preserve original A to be buffered later

	lda byte_c3
	cmp #3
	beq loc_c6de_pop_a

	lda byte_e2
	bne loc_c6de_pop_a

	lda byte_ef
	asl
	bcc locret_c6f0_drop_a

	pla
	pha                        // temporarily inspect original A without losing it
	cmp #$87
	beq locret_c6f0_drop_a

	cmp #$80
	bcs loc_c6de_pop_a

	cmp #$40
	bcs locret_c6f0_drop_a

loc_c6de_pop_a:
	pla                        // recover original byte to write

	lda X_L
	pha
	lda X_H
	pha

	lda byte_dc
	sta X_L
	lda byte_dd
	sta X_H

	ldy #0
	sta (X_L),y
	INC16(X_L, X_H)

	CMPX(CMD_QUEUE+$60)	// $5320
	BCS(loc_c6ec)

	LDX(CMD_QUEUE+$40)		// $5300

loc_c6ec:
	lda X_L
	sta byte_dc
	lda X_H
	sta byte_dd

	pla
	sta X_H
	pla
	sta X_L
	rts

locret_c6f0_drop_a:
	pla
locret_c6f0:
	rts
	
	
sub_c6f3: // to do
	jmp *	
	
sub_c70b: // to do
	jmp *


/*************************** 
*Initalise sound chip state* 
* Code is commented as we  *
* Don't have these sound   *
* the same hardware        *
* sub_c72b,sub_c82c        *
* loc_c836,sub_c879        *
* loc_c882,sub_c896        *
****************************/


/*
sub_c72b:
	nop
	nop
	nop
	nop
	nop  
	//sta     $4800 - W  sound latch write
	//sta     $4900 - W  copy sound latch to SN76489A
	rts
*/
	
// nmi routine
loc_c78e:
	rts

/********************************************
* sub_c81b - Early startup init / 3-pass probe
*
* Called during reset.
*
* What it appears to do:
* - Sets word_5606 to 1, 2, then 3
* - For each value, calls sub_c82c
* - sub_c82c clears B, calls sub_c879
* - If sub_c879 returns A == $DF, it clears B
*   again and calls sub_c896
* - Returns with A = 0
*
* This looks like a small startup hardware/config
* probe or device init sequence.
********************************************/

sub_c81b:
	rts // use a simple rts and ignore initialising the sound hardware

/*
sub_c81b:
	rts
	
    lda #1
    sta WORK_RAM2+$1d6      // word_5606, adjust base if needed

    jsr sub_c82c

    inc WORK_RAM2+$1d6      // word_5606 = 2
    jsr sub_c82c

    inc WORK_RAM2+$1d6      // word_5606 = 3

    // 6809: bra *+2
    // effectively just falls through / returns
    rts
	*/


/********************************************
* sub_c82c - One pass of startup probe      *
*                                           *
* - B = 0                                   *
* - call sub_c879                           *
* - if A == $DF, call sub_c896 with B = 0   *
* - return A = 0                            *
*********************************************/

/*
sub_c82c:
	lda #0
	sta B_Register
	jsr sub_c879
	cmp #$df
	bne loc_c836
	lda #0
	sta B_Register
	jsr sub_c896
loc_c836:
    lda #0
    rts
	
sub_c879:
	lda WORK_RAM2+$1d6
	dec
	asl
	asl
	asl
	asl
	asl                    // A = (word_5606 - 1) * 32

loc_c882:
    lda B_Register
	and #$0f
	sta WORK_RAM2+$1d6

	lda #$9f
	sec
	sbc WORK_RAM2+$1d6
	sta WORK_RAM2+$1d6

	ora WORK_RAM2+$1d6
	jsr sub_c72b
    rts
	
sub_c896:
	lda	#$60
	bra	loc_c882

*/

/*
	Draws energy bars
*/

locret_d3b7:
	rts

sub_d3b8:
	lda WORK_RAM2+$01      // word_5430+1
	bne locret_d3b7

	// pshs a,b,x,y
	lda A_Register
	pha
	lda B_Register
	pha
	lda X_L
	pha
	lda X_H
	pha
	lda Y_L
	pha
	lda Y_H
	pha

	lda WORK_RAM2+$98      // word_54c8
	beq loc_d406

	lda WORK_RAM1+$155     // word_5185
	beq loc_d404

	cmp #$17
	bcs loc_d3cd
	jmp loc_d3f3

loc_d3cd:
    cmp #$03
	bne loc_d3da

	jsr sub_c70b

	LDD($020d)
	jsr loc_80a2

loc_d3da:
	jmp *

loc_d3f3:
	jmp *

loc_d404:
	jmp *

loc_d406:
	// puls y,x,b,a
	pla
	sta Y_H
	pla
	sta Y_L
	pla
	sta X_H
	pla
	sta X_L
	pla
	sta B_Register
	pla
	sta A_Register
	
	jmp * // continue here.
