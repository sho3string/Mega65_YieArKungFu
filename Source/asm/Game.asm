

*=$6000 "Game Code - Game.asm"

loc_8000:
	// byte_0 = pointer low
	// byte_1 = pointer high
	// byte_2 = low byte of D (B)
	// byte_3 = high byte of D (A)

	// X starts at $5000
	lda #$00
	sta byte_0
	lda #$50
	sta byte_1
	
	lda #$00
	sta byte_2
	lda #$00
	sta byte_3
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
    cmp #$57
    bcc loc_8005
    bne loc_800f
    lda byte_0
    cmp #$00
    bcc loc_8005
	
loc_800f:
	lda #$30
	sta byte_0
	lda #$50
	sta byte_1
	
	lda #$00
	sta byte_2
	lda #$00
	sta byte_3
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
    cmp #$57
    bcc loc_8012
    bne loc_801c
    lda byte_0
    cmp #$30
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
	lda #$c0        // low byte
    sta byte_d8
    sta byte_da
	sta byte_f0	 // use a separate temp pointer to walk 52C0..52FE

    lda #$52        // high byte
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

    // compare pointer to $5300
    lda byte_f1
    cmp #$53
    bcc loc_803b    // if < 5300, continue
    bne loc_8042    // if > 5300, stop
    lda byte_f0
    cmp #$00
    bcc loc_803b    // if < 5300, continue
loc_8042:
	
	// store high byte first (53), then low byte (00)
    lda #$53
    sta byte_dc      // $DC
    sta byte_de      // $DE
    lda #$00
    sta byte_dd      // $DD
    sta byte_df      // $DF

	// clear word_5606+1  (i.e., $5607)
    lda #$00
    sta $5607
	// clear word_5608 (low byte)
    sta $5608
	// Read DIPs
	jsr sub_80c5
	// Sets options to flip Screen
	jsr sub_80b5  
	
    lda byte_c3
    beq loc_8062          // if zero, skip
    // D8 = $52C0
    lda #<$52C0
    sta byte_d8
    lda #>$52C0
    sta byte_d9
    // store $FFFF at $52C0
    lda #$FF
    sta $52C0
    sta $52C1
    // store $FFFF at $52C2
    sta $52C2
    sta $52C3
	
	
/**************************
* Set up IRQs on Arcade   *
* RST = 0x8163  - 0xfff0  *
* NMI = 0xC78E  - 0xfffc  *
* SRQ = 0x8163  - 0xfffa  *
* IRQ = 0x897D VBL 0xfff8 *
**************************/

loc_8062:
    // A = word_5600 low byte (6809 loads 16-bit, but only A is used)
    lda $5600
    //jsr sub_86D7 (ROM→RAM high score copy, not needed. See)
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
    sta byte_dc		
    lda byte_db        // high
    sta byte_dd	
	ldy #0
    lda (byte_dc),y    // actually read the flag byte
    asl
    bcs loc_807c
    and #$7F
    tax
	
	// get low byte
	iny
	lda (byte_dc),y    //  derived index into d56a
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
    cmp #$53
    bcc store_ptr        // hi < 53 → keep
    bne wrap_ptr         // hi > 53 → wrap
    lda byte_f0
    cmp #$00
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
    inc WORK_RAM1+$1DF // word_520E+1

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
    inc WORK_RAM1+$1DF  // word_520E+1

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
    lda #< (SCREEN_BASE + $40) // was $41
    sta byte_fd
    lda #> (SCREEN_BASE + $40) // was $41
    sta byte_fe
	
	
    //lda #$21		// number of columns, 32
	lda #CHARS_WIDE+1
    sta byte_ff

    lda #1
    sta byte_ca

    inc byte_c5
	
    lda #1          // not finished
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
	//adc #$40
	adc #LINESTEP_BYTES
	sta byte_f0
	lda byte_f1
	adc #0
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
* 5030-51BC              *
*************************/
sub_814c:
    ldx #WORK_RAM1          	// start = $5030
loc_8152:
    lda #0
    sta 0,x                 	// clear byte
    inx
    cpx #(WORK_RAM1 + $180) 	// end = $5030 + $180 = $51B0
    bcc loc_8152               // branch while X < end
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


// Assumes:
//   SCREEN_BASE   = $2800
//   CHARS_WIDE    = 32          // visible
//   CHARS_HIGH    = 32
//   LINESTEP      = TOTAL_CHARS * 2   // 160 bytes (80 chars × 2)

// byte_0/byte_1 = screen pointer
// byte_2        = tile number (crosshatch)
// y             = inner index (0..CHARS_WIDE-1)
// x             = outer row counter

sub_821a:
    lda #<SCREEN_BASE
    sta byte_0
    lda #>SCREEN_BASE
    sta byte_1

    ldx #CHARS_HIGH         // 32 rows

row_loop:
    ldy #0

col_loop:
    // low byte at (byte_0),Y
    lda byte_2
    clc
    adc #<TILE_OFFSET
    sta (byte_0),y

    // high byte at Y+1
    lda #$00
    clc
    adc #>TILE_OFFSET
    iny
    sta (byte_0),y

    // advance Y by 1 more so we've moved 2 bytes total
    iny                        // Y += 1 (so net +2 per cell)

    cpy #(CHARS_WIDE*2)        // 32 chars * 2 = 64 bytes
    bne col_loop

    // at end of row, Y = 64, so pointer to visible-end-of-row:
    //  byte_0 + 64 = start_of_rrb_tail
    // now advance to next row start by adding (160 - 64 = 96)
	
	// Y = 64 (end of visible region)
	// byte_0/byte_1 = start of row

	/************************RRB INIT**********************************/
	

	phx // preserve the number of rows we need to draw the entire screen
    ldx #RRB_PixiesPerRow
PixieLoop:
    // raster
    lda RRB_PixieProtoType
    sta (byte_0),y
    iny
    lda RRB_PixieProtoType+1
    sta (byte_0),y
    iny

    // tile
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

    // GOTOX
    lda #0
    sta (byte_0),y
    iny
    lda RRB_PixieProtoType+5
    sta (byte_0),y
    iny
    dex
    bne PixieLoop
    plx

    // dummy tile
    lda #0
    sta (byte_0),y
    iny
    lda #0
    sta (byte_0),y
    iny
	
	/******************************************************************/
	
    clc
    lda byte_0
    adc #<LINESTEP_BYTES 
    sta byte_0
    lda byte_1
    adc #>LINESTEP_BYTES 
    sta byte_1

    dex
    lbne row_loop
    rts

	
loc_8242: // from function table at D9F0

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
	
.const zp_script_lo		= byte_0    // pointer into current text script
.const zp_script_hi		= byte_1
.const zp_tile_lo			= byte_2    // pointer into tilemap
.const zp_tile_hi			= byte_3
.const zp_script_idx		= byte_4    // index into script (offset from script base)
.const zp_glyph_index		= byte_6


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

sub_87cf:

    //-------------------------------------------
    // 1. Use command parameter to select script
    //-------------------------------------------
    lda zp_cmd_param       // B in the original 6809
    asl                    // *2 (each entry in d56a is 2 bytes)
    tax

    lda d56a,x             // low byte of script pointer
    sta zp_script_lo
    lda d56a+1,x           // high byte
    sta zp_script_hi


    //-------------------------------------------------
    // 2. Read first word from script = tilemap address
    //   script[0..1] = tilemap address
    //-------------------------------------------------
    ldy #0
    lda (zp_script_lo),y   // low byte of tilemap address
    sta zp_tile_lo
    iny
    lda (zp_script_lo),y   // high byte
    sta zp_tile_hi
    iny
    sty zp_script_idx      // script index now points to first encoded char

// ------------------------------------------------------------
// Main decode loop - like loc_87DE / loc_87F5
// ------------------------------------------------------------

TextLoop:
    ldy zp_script_idx
    lda (zp_script_lo),y   // A = next encoded byte
    iny
    sty zp_script_idx
	

    cmp #$3F               // '?' = end of script
    beq TextDone

    cmp #$2F               // '/' = new line (load new tilemap address)
    beq NewLine

    //------------------------------
    // Normal character:
    //   tile_index = A - $30
    //   write TILE then ATTR
    //   advance tile pointer by 2
    //------------------------------
    // A = encoded byte here

    // 1. Convert to glyph index
    sec
    sbc #$30               // A = glyph index
    sta zp_glyph_index

    // 2. Write low byte: low(TILE_OFFSET) + glyph_index
    ldy #0
    lda #<(TILE_OFFSET)
    clc
    adc zp_glyph_index
    sta (zp_tile_lo),y

    // 3. Write high byte: high(TILE_OFFSET) + carry from low-byte add
    iny
    lda #>(TILE_OFFSET)
    adc #0                 // add incoming carry only
    sta (zp_tile_lo),y

 
    // advance tile pointer by 2 bytes (next tile entry)
    clc
    lda zp_tile_lo
    adc #2
    sta zp_tile_lo
    bcc NoTileHiCarry
    inc zp_tile_hi

NoTileHiCarry:

    jmp TextLoop

// ------------------------------------------------------------
// New line: '/' encountered
// We read a NEW tilemap address from the script and continue
// ------------------------------------------------------------

NewLine:
    // script[script_idx..] = new tilemap address (2 bytes)
    ldy zp_script_idx
    lda (zp_script_lo),y   // low byte of new tilemap address
    sta zp_tile_lo
    iny
    lda (zp_script_lo),y   // high byte
    sta zp_tile_hi
    iny
    sty zp_script_idx      // advance script index past address

    jmp TextLoop

// ------------------------------------------------------------
// End of script: '?' encountered
// Return to the command consumer loop (loc_807c)
// ------------------------------------------------------------

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
	
loc_8808: // not sure what this is for
loc_8824: // to do

/*****************************
// Player 1 and Player 2 lives*
*****************************/

loc_892d: 
	

	
/******************************
*loc_897D — VBLANK IRQ handler*
******************************/

loc_897d:
    // clear bit 2 of ByteC1
    lda byte_c1
    and #$FB
    sta byte_c1

    // increment frame counter
    inc byte_d4

    // call main VBLANK routine (Sprites) 
    jsr sub_8b30
	
    jsr BuildSpriteQueueFromArcadeRAM
    jsr BuildPixieBucketsFromSpriteQueue


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

    lda WORK_RAM1+$1DF // $520f
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
    and #$F7            // clear bit 3
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
    lda #(WORK_RAM2+$1d8)
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
    sta WORK_RAM2+$1D7  // store command byte - 0X5607
    lda #1
    sta WORK_RAM2+$1D8  // mark command ready - 0X5608

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
    lda #$0A
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
	lda #$0A
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
	
// clear tile bits for Konami logo + copyright
sub_8ca5:
	jmp *
	
/************************************************************
* loc_8CB3 — Write Sprite Data and characters (i, ® cluster)*
************************************************************/

loc_8cb3:
	
    lda #<WORK_RAM1+$140  //$5170
    sta sprPtrLo
    lda #>WORK_RAM1+$140
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

.const arcadeRowSize = 6 // offset/0x40

    lda #$AE
	//sta $5E65-1
    sta SCREEN_BASE+(RRB_Tail_words	*2*($665>>arcadeRowSize))+$665-1 // dot above the i
	lda #$9F
	//sta $5EA5-1
    sta SCREEN_BASE+(RRB_Tail_words	*2*($6a5>>arcadeRowSize))+$6a5-1 // the i
	lda #$BD
	sta SCREEN_BASE+(RRB_Tail_words	*2*($6a7>>arcadeRowSize))+$6a7-1 // (r)
	//sta $5EA7-1
	
loc_8cde: // goes here when finished clearing crosshatch
	lda #$10
    sta byte_f2      // B = $10
loc_8ce0:
	jmp	sub_80a1
	
loc_8c44://Playfield/HighScore state 
	jmp *
loc_8c5b:
	jmp *
loc_8cf6:
	jmp *
loc_8de2:
	jmp *
	
	
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
    ldx X_L
    cpx #$26
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
    cmp #>WORK_RAM1+$180
    lbcc loc_8b3c
    bne !u_not_lt+
    lda U_L
    cmp #<WORK_RAM1+$180
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
    cmp #>WORK_RAM1+$180
    lbcc loc_8b8a
    bne !u_not_lt_51b0+
    lda U_L
    cmp #<WORK_RAM1+$180
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

/* Waterfall code*/

loc_9252:
loc_926D:
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
    lda #<$5F6D
    sta byte_30
    lda #>$5F6D
    sta byte_31

    // if C4 == 1, override X = $5DAD
    lda byte_c4
    cmp #1
    bne loc_92ca    // just skip override, but DO NOT RETURN

    lda #<$5DAD
    sta byte_30
    lda #>$5DAD
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
    lda #<$5EF1
    sta byte_30
    lda #>$5EF1
    sta byte_31

    // if C4 == 1, X = $5D31
    lda byte_c4
    cmp #1
    bne sub_92df
    lda #<$5D31
    sta byte_30
    lda #>$5D31
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
	
// to do.
sub_c6f3:
	rts
	
// nmi routine
loc_c78e:
	rts

sub_c81b:
	rts