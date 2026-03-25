

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


.const zp_cmd_param	= byte_40   // command parameter from queue (what was B on 6809)

loc_807c:
	
    // Load X from $DA (pointer) into temp pointer byte_dc/dd
    lda byte_da        // low
    sta byte_7		
    lda byte_db        // high
    sta byte_8	

	ldy #0
    lda (byte_7),y    // actually read the flag byte
    asl
    bcs loc_807c
    and #$7F
    tax
	
	// get low byte
	iny
	lda (byte_7),y    //  derived index into d56a
	sta zp_cmd_param

	
    // A now is the (2 * index) for the jump table later
    // -----------------------------
    // Store $FFFF at [byte_da] and advance pointer by 2
    // -----------------------------
    lda #$FF
    ldy #0
    sta (byte_da),y    // low byte = $FF
    iny
    sta (byte_da),y    // high byte = $FF

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
    cmp #>CMD_QUEUE		// 0x52c0
    bcc pointer_ok        // < $52xx → OK
    bne do_wrap           // > $52xx → wrap

    // high byte == $52, check low
    lda byte_da
    cmp #<CMD_QUEUE+$3f	// c0+$3f = 0xff.
    bcc pointer_ok        // < $52FF → OK
    beq pointer_ok        // == $52FF → OK

do_wrap:
    lda #<CMD_QUEUE
    sta byte_da
    lda #>CMD_QUEUE
    sta byte_db
    jmp store_da
pointer_ok:
store_da:
    // pointer already stored in byte_da/db
	// X already = 0,2,4,6 from and #$7F / tax
	
	// fake return address for RTS -> loc_807c
    lda #>(loc_807c-1)
    pha
    lda #<(loc_807c-1)
    pha

	lda d562,x              // low byte of handler address
	sta byte_5
	lda d562+1,x            // high byte
	sta byte_6
	jmp (byte_5)
	

/******************
* Producer section*
******************/

sub_80a1: 
	lda #$0
	sta byte_f3      // this is the high byte of D (A)
loc_80a2:
	// gets called via interrupt - from loc_8ce0
    // push X (pshs x)
    txa
    pha

    // load pointer from byte_d8/byte_d9 into temp ptr
    lda byte_d8
    sta byte_f0
    lda byte_d9
    sta byte_f1

    // write 16-bit D from byte_f2/byte_f3 to [byte_f0]
    ldy #0
    lda byte_f3
    sta (byte_f0),y
    iny
    lda byte_f2
    sta (byte_f0),y

    // advance pointer by 2
    lda byte_f0
    clc
    adc #2
    sta byte_f0
    lda byte_f1
    adc #0
    sta byte_f1

    // compare pointer to $5300
    lda byte_f1
    cmp #>WORK_RAM1 + $2d0
    bcc store_ptr        // hi < 53 → keep
    bne wrap_ptr         // hi > 53 → wrap
    lda byte_f0
    cmp #<WORK_RAM1 + $2d0
    bcc store_ptr        // < 5300 → keep

wrap_ptr:
    lda #<(CMD_QUEUE)
    sta byte_f0
    lda #>(CMD_QUEUE)
    sta byte_f1

store_ptr:
    // save updated pointer back to byte_d8/byte_d9
    lda byte_f0
    sta byte_d8
    lda byte_f1
    sta byte_d9

    // restore X (puls x)
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
	lda #$00				// attribute page
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
* Clears Sprite Data     *
* 5030-51AF              *
*************************/
sub_814c:
    LDX(WORK_RAM1)          // emulated 6809 X = $5030

loc_8152:
    lda #0

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

/*
sub_821a:
    lda #<SCREEN_BASE
    sta byte_0            // pointer = $5800
    lda #>SCREEN_BASE
    sta byte_1

    ldy #$00              // y must be 0 for (zp),y
	
loc_821e:
    // ---- compute low byte of tile index ----
    lda byte_2
    clc
    adc #<(TILE_OFFSET)
    sta (byte_0),y        // store low byte

    // ---- compute high byte of tile index ----
    lda #$00              // attribute page
    clc
    adc #>(TILE_OFFSET)
    iny
    sta (byte_0),y        // store high byte
    dey                   // restore y = 0

    // ---- increment pointer by 2 ----
    clc
    lda byte_0
    adc #2
    sta byte_0
    lda byte_1
    adc #0
    sta byte_1
	
    // ---- compare pointer to top of SCREEN_BASE ----
    lda byte_0
	cmp #<(SCREEN_BASE+(TOTAL_CHARS<<1)*CHARS_HIGH)
	bne loc_821e
	lda byte_1
	cmp #>(SCREEN_BASE+(TOTAL_CHARS<<1)*CHARS_HIGH)
	bne loc_821e
	rts
*/


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
    LDX(SCREEN_BASE+(RRB_Tail_words*2*($1d1>>arcadeRowSize))+$1d1-1) // $59d1

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
    
	LDU(e172)
	
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
	lda #<$59bf
    sta byte_fd_arc
    lda #>$59bf
    sta byte_fe_arc
	
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

	// ldx #$597F
	LDX(SCREEN_BASE+(RRB_Tail_words*2*($17f>>arcadeRowSize))+$17f-1)	// $597f - Enemy Name

	// ldu #$D503   ; table of word pointers
	LDU(d503)

	// ldb word_5430+1
	lda WORK_RAM2+$01
	sta B_Register

	cmp #$0a
	bcc loc_873f_prep
	lda #$0a
	sta B_Register

loc_873f_prep:
	// aslb  ; word table => *2
	lda B_Register
	asl
	sta B_Register

	// ldu b,u  ; load word pointer from table at U + B
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
	// lda ,-u   ; predecrement U, then read
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

	pha                     // save glyph
	// move left one visible cell
	sec
	lda X_L
	sbc #2
	sta X_L
	lda X_H
	sbc #0
	sta X_H
	pla                     // restore glyph
	ldy #0
	sta (X_L),y
	bra loc_8742

/**************************
*Generate player one score*
**************************/
loc_874c:
	LDU(WORK_RAM1+$1e0)													 // original $5210
	LDX(SCREEN_BASE+(RRB_Tail_words*2*($0c3>>arcadeRowSize))+$0c3-1)   // original $58C3
	jsr sub_88c5
	jsr sub_8922
	
/*******************************
*Generate player one high score*
*******************************/
loc_8758:
	LDU(WORK_RAM1+$1EC)													 // original $521C
	LDX(SCREEN_BASE+(RRB_Tail_words*2*($0db>>arcadeRowSize))+$0db-1)   // original $58DB
	jsr sub_88c5
	jsr sub_8922

/*************************************************
* Initialise energy bar                          * 
*                                                *
* Arcade writes attribute bytes only to flip the *
* energy bar - Player one only                   *
**************************************************/

loc_8764:
	LDX(SCREEN_BASE+(RRB_Tail_words*2*($180>>arcadeRowSize))+$180-1)
	lda #$0f
	sta B_Register          // 15 cells
	ADDX(2)					 // start at 0x2b38
loc_876a:
	ldy #0                   // attribute byte on MEGA65
	//lda #$80				 // attribute flip X
	//clc
	//adc #$08				 // preserve row mask 0x8
	lda #$88				 // refer to above for explanation.
	sta (X_L),y

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

/******************************
* Draws the playfield         *
* From right to left          *
*******************************/

loc_8782:
	dec byte_ca
	lbne locret_87ce

	lda #1
	sta byte_ca

	dec byte_ff
	lbeq loc_87b2

	lda #$17
	sta B_Register
	
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
	
	// ldu word_5200
	lda WORK_RAM1+$1D0 // 65
	sta U_L
	lda WORK_RAM1+$1D1 // 78
	sta U_H

	// leau 1,u
	ADDU(1)				// 7866

	// stu word_5200
	lda U_L
	sta WORK_RAM1+$1D0
	lda U_H
	sta WORK_RAM1+$1D1

loc_879e:
    // lda ,u  -> tile
    ldy #0
    lda (U_L),y

    // sta ,x  -> tile byte
    ldy #0
    sta (X_L),y
	
    // lda $2E0,u -> arcade attribute table
    clc
    lda U_L
    adc #<$02e0
    sta byte_5
    lda U_H
    adc #>$02e0
    sta byte_6
    ldy #0
    lda (byte_5),y

	lda #$08    // MEGA65 row mask

    // store attribute in second byte of current cell - TODO!
    pha
    clc
    lda X_L
    adc #1
    sta byte_5
    lda X_H
    adc #0
    sta byte_6
    pla
    ldy #0
    sta (byte_5),y

    // next destination row
    ADDX(ROW_STRIDE)

    // next source row
    ADDU($20)

    dec B_Register
    bne loc_879e
    rts
	
loc_87b2:
	lda #$20
	sta byte_fd

	inc byte_c6

	lda #0
	sta byte_c7

	LDX(WORK_RAM2+$0D)	// original #$543D

	// std ,x
	LDD($328a)
	STD_PTR(X_L)

	// std 2,x
	clc
	lda X_L
	adc #2
	sta byte_5
	lda X_H
	adc #0
	sta byte_6
	LDD($3b8a)
	STD_PTR(byte_5)

	// std 4,x
	clc
	lda X_L
	adc #4
	sta byte_5
	lda X_H
	adc #0
	sta byte_6
	LDD($3898)
	STD_PTR(byte_5)

	// clr -1,x
	sec
	lda X_L
	sbc #1
	sta byte_5
	lda X_H
	sbc #0
	sta byte_6
	ldy #0
	lda #0
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
   
     
/*	 
	// Debug blast: write a block of tile $0f at some obvious spot
    ldx #0
@fill:

	lda #$0f				
	clc
	adc #<(TILE_OFFSET)
	sta $5880,x
    inx
	lda #$00
	clc
	adc #>(TILE_OFFSET)
	sta $5880,x
	inx
	
    cpx #40          // one row, 40 chars
    bne @fill

    jmp loc_807c     // IMPORTANT: return to the state machine
*/
	
loc_8808: // seems to get called when you press start
	jmp *

loc_8824:	// to do - gets called during demo.
	jmp *
	
/*********************
*Player 2 score setup*
**********************/
sub_88bf:
	LDX(SCREEN_BASE+(RRB_Tail_words*2*($0f1>>arcadeRowSize))+$0f1-1)	// original $58F1
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
	
/*sub_891f:
	ldy #0
	sta (X_L),y
	INC16(X_L, X_H)
	rts
*/

	
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
	lda #$10              // blank tile
	sta A_Register
	lda #$09              // count
	sta B_Register
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
	jsr loc_8965

loc_8942:
	lda WORK_RAM1+$1B0    // word_51E0
	beq locret_892c

	// ldd #$1009
	lda #$10              // blank tile
	sta A_Register
	lda #$09              // count
	sta B_Register
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
	jmp loc_8970


sub_895c:
	lda WORK_RAM2+$00     // word_5430
	sta B_Register
	dec B_Register

	lda WORK_RAM1+$1B1    // word_51E0+1
	bne loc_8970

loc_8965:
	lda #$10              // blank tile, not ASCII '0'

loc_8967:
	LDX(SCREEN_BASE+(RRB_Tail_words*2*($103>>arcadeRowSize))+$103-1)   // original $5903

loc_896a:
	lda A_Register
	ldy #0
	sta (X_L),y           // write tile byte
	ADDX(2)               // next visible cell
	dec B_Register
	bne loc_896a
	rts


loc_8970:
	lda #$10              // blank tile

loc_8972:
	LDX(SCREEN_BASE+(RRB_Tail_words*2*($13d>>arcadeRowSize))+$13d-1)   // original $593D

loc_8975:
	ldy #0
	sta (X_L),y           // write tile byte
	sec
	lda X_L
	sbc #2                // previous visible cell
	sta X_L
	lda X_H
	sbc #0
	sta X_H

	dec B_Register
	bne loc_8975
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

    jsr BuildSpriteQueueFromArcadeRAM
	jsr BuildPixieListFromSpriteQueue
	jsr RRB_BuildAllRows     // builds tails for every row from pixie list
	
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
    jmp loc_8a20
	
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
    jmp loc_8a45
	

loc_8a37:
    lda byte_e9
    beq loc_8a4a        // if E9 == 0, skip

    dec byte_e9          // E9--

    lda #8
    sta byte_eb          // EB = 8

    lda byte_c1
    eor #$10            // toggle bit 4
    sta byte_c1

loc_8a45:
	sta byte_c1
    sta byte_4000_shadow
	

loc_8a4a:
    lda byte_f1
    ora byte_f6
    eor #$ff          // comb = one’s complement
    and byte_fb
    and byte_fc
    and #7
    lbeq loc_8b0e

    // pshs a,b  → push A then B
    pha
    lda byte_b         // however we store B-equivalent
    pha

    lda byte_c3
    cmp #2
    beq loc_8a66

    lda #$0f
    sta byte_b        // B = $0F
    jsr sub_80a1


loc_8a66:   
    pla                 // pull A
    sta byte_a         // store temporarily if needed
    pla                 // pull B
    sta byte_b

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

    // bra loc_8b0e
    jmp loc_8b0e

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

    // save Y (DO NOT use tmp; ASRA uses tmp)
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
    jmp loc_8b60
	
	/* workaround for last sprite offset adjust in the title
loc_8b5f_:
	clc
	adc #1
	jmp loc_8b60 */
	
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

    // bra loc_8B3C
    jmp loc_8b3c

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
    jmp loc_8bb3

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

    // bra loc_8B8A
    jmp loc_8b8a

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
    jsr sub_814c		// Clear sprite ram
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

    jsr sub_814c        // clear sprite RAM (5030–51BC)
    jmp sub_8ca5        // clear tile bits for Konami logo + copyright
	


// ZP layout
.const sprPtrLo	= byte_30   // X pointer low
.const sprPtrHi	= byte_31   // X pointer high
.const logoPtrLo	= byte_46   // U pointer low
.const logoPtrHi	= byte_47   // U pointer high
.const logoX		= byte_21   // B equivalent
.const logoCount	= byte_20   // Y equivalent
.const tmpPtrLo 	= byte_f4
.const tmpPtrHi 	= byte_f5


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
    lda #$A0
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
    lda #$90
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
    ldy #1                  // second byte in DA5A entry
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
    sta WORK_RAM2+$33       // word_5463 high
    sta WORK_RAM2+$63       // word_5493 high

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
    LDX(WORK_RAM2) 		// $5430
loc_8dcd:
    STD_ZERO_POSTINC_X()
    CMPX(WORK_RAM2+$8d)	// $54bd
    BCS(loc_8dcd)
loc_8dd4:
    LDX(WORK_RAM2+$90)		// $54c0
loc_8dda:
    STD_ZERO_POSTINC_X()
    CMPX(WORK_RAM2+$ed)	// $551d
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
	LDX(SCREEN_BASE+(RRB_Tail_words*2*($4a3>>arcadeRowSize))+$4a3-1)		// $5ca3
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

    lda #0
    sta WORK_RAM1+$1D6      // word_5206 low
    jmp loc_a7db

loc_8e60:
    lda #0
    sta WORK_RAM1+$1D6      // word_5206
    jmp loc_a7db

loc_8e66:
    jsr sub_86f6
    lda #0
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

	// bne locret_8e7c   ; test 16-bit result
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
	
loc_8ea2:  // to do - part of game play loop
			//bsr.w	DO_WATERFALL				; check status for waterfall - 0x923F
			//bsr.w	sub_9084					; 1UP flasher 0x8b=blank, B=1UP
			//bsr.w	sub_9315					; game vars and set up, inits sprite positions in the game/attract. ( 9315 -> 9415 )
			//bsr.w	sub_A86D					; sprite enable for enemy ?
			//bsr.w	sub_9EA5					; draws energy bars.
			// lots to do here.
loc_8ef3:
	jmp *

loc_8ef5:
	lda WORK_RAM1+$1D6      // word_5206 low
	asl
	tax
	lda da8e,x
	sta byte_5
	lda da8e+1,x
	sta byte_6
	jmp (byte_5)
	
loc_8f14: // to do

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
    LDU($5050)
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

    bcs loc_8fe7            // 6809 BCC after SUBD => no borrow; 6502 C=1 means no borrow

    lda #0
    sta A_Register
    sta B_Register
	
loc_8fe7:
    // std word_508C
    lda A_Register
    sta WORK_RAM1+$5C
    lda B_Register
    sta WORK_RAM1+$5D
    // beq loc_8ff0
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
	LDX(SCREEN_BASE+(RRB_Tail_words*2*($18e>>arcadeRowSize))+$18e-1) // $598e

loc_8fff: // to do
loc_901b: // to do
loc_902b: // to do
loc_9052: // to do
loc_9076: // to do

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

loc_90ce:
	jmp *

loc_919e:
	jmp *

/* Waterfall code*/

loc_9252:
loc_926d:
loc_9285:
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
	
sub_a663:
	jmp *
	
loc_a7db:
    lda #$10
    sta B_Register

    LDX(WORK_RAM2+$D0)	  // $5500

loc_a7e0:
    ldy #0
    lda #0
    sta (X_L),y          // clr ,x+
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

    LDY(WORK_RAM1+$A0)		// $50d0
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

	LDX(WORK_RAM1+$60)		// $5090

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
	
sub_b566: // to do 
	jmp *
	
sub_b682: // to do
	jmp *
	
sub_c3e6:
	CLRB()

loc_c3e7:
	lda WORK_RAM2+$01      // word_5430+1

	lda B_Register
	beq locret_c3f6

	// original:
	//   pshs x
	//   ldx #$FF39
	//   lda a,x
	//   puls x

	pha                    // preserve A offset
	LDX(ff39)
	pla
	clc
	adc X_L
	sta byte_5
	lda X_H
	adc #0
	sta byte_6
	ldy #0
	lda (byte_5),y

locret_c3f6:
	rts
	
	
loc_c67a:	// to do
	lda #$1
	bra	loc_c6c3
	
	
// to do	
loc_c692:
	jmp *
	
// to do
loc_c6a2:
	jmp *
	
// to do	
loc_c6a6:
	lda #$41
	bra	loc_c6c3
	

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
	
// to do.
sub_c6f3:
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
