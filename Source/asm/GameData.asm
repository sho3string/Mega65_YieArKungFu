*=* "Game Data - GameData.asm"

/**********************************
*0x4000 W  control port           *
*bit 0 - flip screen		0x1   *
*bit 1 - NMI enable			0x2   *
*bit 2 - IRQ enable			0x4   *
*bit 3 - coin counter A		0x8   *
*bit 4 - coin counter B		0x10  *
***********************************/
byte_4000_shadow: .byte 0


/*********************************************
* High score table originally at D477 in ROM *
*********************************************/
data_5520:
	.byte $00,$38,$40,$03,$23,$2B,$24,$23,$25,$14,$11,$10,$10,$10	// 38400 3 S.TSUDA
	.byte $00,$31,$50,$02,$29,$2B,$23,$25,$17,$19,$1D,$1F,$24,$1F	// 31500 2 Y.SUGIMOTO
	.byte $00,$21,$30,$02,$11,$2B,$19,$1E,$1F,$25,$15,$10,$10,$10	// 21300 1 A.INOUE
	.byte $00,$13,$60,$01,$18,$2B,$18,$1F,$22,$19,$10,$10,$10,$10	// 13600 1 H.HORI
	.byte $00,$09,$40,$01,$1D,$2B,$24,$11,$1B,$15,$1D,$1F,$24,$1F	// 9500  1 M.TAKEMOTO
	.byte $00,$08,$20,$01,$1E,$19,$23,$18,$19,$1D,$25,$22,$11,$10	// 8200  1 NISHIMURA
	.byte $00,$07,$70,$01,$23,$2B,$19,$27,$11,$1D,$1F,$24,$1F,$10	// 7700  1 S.IWAMOTO
	.byte $00,$06,$30,$01,$23,$18,$19,$1B,$11,$1D,$11,$10,$10,$10	// 6300  1 SHIKAMA
	.byte $00,$05,$10,$01,$18,$11,$23,$15,$17,$11,$27,$11,$10,$10	// 5100  1 HASEGAWA
	.byte $00,$04,$80,$01,$18,$11,$24,$11,$1E,$1F,$10,$10,$10,$10	// 4800  1 HATANO
	
	
/***********************************
* Used during init for reading DIPs*
***********************************/

d412:
	.byte $01,$01,$01,$02,$01,$03,$01,$04 
	.byte $01,$05,$01,$06,$01,$07,$02,$01 
	.byte $02,$03,$02,$05,$03,$01,$03,$02 
	.byte $03,$04,$04,$01,$04,$03,$00,$00
d432:
	.byte $01,$02,$03,$05
	

/***************************
* Address to name pointers *
****************************/

d503:
    .word buchu
    .word star
    .word nuncha
    .word pole
    .word feedle
    .word chain
    .word club
    .word fan
    .word sword
    .word tonfun
    .word blues

/***********************************************************
* Enemy names                                              *
*                                                          *
* Routine reads from end of string backwards until $30     *
* terminator is hit.                                       *
* Therefore each label points one byte past the last char. *
***********************************************************/

//				   B   U   C   H   U
	.byte $30,$40,$42,$55,$43,$48,$55 	// @BUCHU
buchu: 

	.byte $30,$40,$53,$54,$41,$52		// @STAR
star:

	.byte $30,$4E,$55,$4E,$43,$48,$41	// NUNCHA
nuncha:

	.byte $30,$40,$40,$50,$4F,$4C,$45	// @@POLE
pole:

	.byte $30,$46,$45,$45,$44,$4C,$45	// FEEDLE
feedle:

	.byte $30,$40,$43,$48,$41,$49,$4E	// @CHAIN
chain:
	
	.byte $30,$40,$43,$4C,$55,$42		// @CLUB
club:

	.byte $30,$40,$46,$41,$4E			// @FAN
fan:

	.byte $30,$40,$53,$57,$4F,$52,$44	// @SWORD
sword:
	
	.byte $30,$54,$4F,$4E,$46,$55,$4E	// TONFUN
tonfun:

	.byte $30,$40,$42,$4C,$55,$45,$53	// @BLUES
blues:
	
	
/****************
* Address Tables*
*****************/

d562:
	.word sub_87cf // (c) KONAMI 1985 
	.word loc_8808 // to do - ??? gets called when you press start
	.word loc_8824 // to do - ??? gets called in game or demo
	.word loc_892d // to do - Player 1 and Player 2 lives
	
/*************************************
* Address pointers to text structures*
*************************************/

d56a:					
	.word pressStartButton	//D5B2
	.word onePlayerOnly		//D5C7
	.word oneOrTwoPlayers		//D5D9
	.word hotFightingHistory	//D5EE
	.word masterhandHistory	//D605
	.word doYourBest			//D61A
	.word playerOne			//D667
	.word playerOne			//D667
	.word playerTwo			//D674
	.word gameOver				//D681
	.word TwoUp					//D68E
	.word OneUp					//D694
	.word hiScore				//D69A
	.word stage					//D6B3
	.word perfect				//D6BB
	.word credit				//D6C5
	.word konami1985			//D6CE
	.word nextOpponent			//D6DE
	.word ram1ok				//D6EE
	.word rambad				//D71C
	.word colorTest			//D728
	.word ioTest				//D74F
	.word CoinCounter1			//D807
	.word DipSWSelect			//D818
	.word Coin1					//D877
	.word FreePlay				//D8A3
	.word Table					//D8B0
	.word UpRight				//D8BB
	.word SoundTest			//D8C6
	.word Invalidity			//D8E0
	.word Time					//D8ED
	.word scoreRanking			//D8F4
	.word OneUpb				//D95E
	.word TwoUpb				//D964
	.word fifth					//D939
	.word timeOver				//D96A
	
pressStartButton:
	.word $5B11									// video ram address
	.byte $50,$52,$45,$53,$53,$40	 			// PRESS@
	.byte $53,$54,$41,$52,$54,$40 	 		// START@
	.byte $42,$55,$54,$54,$4F,$4E 			// BUTTON
	.byte $3f
	

onePlayerOnly:
	.word $59CD
	.byte $4F,$4E,$45							// ONE@					
	.byte $50,$4C,$41,$59,$45,$52 			// PLAYER@
	.byte $4F,$4E,$4C,$59 						// ONLY
	.byte $3f

oneOrTwoPlayers:
	.word $59CD 
	.byte $4F,$4E,$45,$40						// ONE@
	.byte $4F,$52,$40 							// OR@
	.byte $54,$57,$4F,$40 						// TWO@
	.byte $50,$4C,$41,$59,$45,$52,$53			// PLAYERS
	.byte $3f

hotFightingHistory:
	.word $588D
	.byte $48,$4F,$54,$40							// HOT@
	.byte $46,$49,$47,$48,$54,$49,$4E,$47,$40 	// FIGHTING@
	.byte $48,$49,$53,$54,$4F,$52,$59  			// HISTORY
	.byte $3f


masterhandHistory:	
	.word $588D
	.byte $4D,$41,$53,$54,$45,$52,$48,$41,$4E,$44,$40 // MASTERHAND@
	.byte $48,$49,$53,$54,$4F,$52,$59 		 		 // HISTORY
	.byte $3f

doYourBest:
	.word $5E4D 
	.byte $44,$4F,$40							 // DO@
	.byte $59,$4F,$55,$52,$40 				 // YOUR@
	.byte $42,$45,$53,$54,$5D,$5D			// BEST!!
	.byte $2f

goodLuck:
	.word $5ED3 
	.byte $47,$4F,$4F,$44,$40					 // GOOD@
	.byte $4C,$55,$43,$4B,$5D,$5D 			 // LUCK!!
	.byte $2f

firstBonus:
	.word $5C8D
	.byte $31,$53,$54,$40 						 // 1ST@
	.byte $42,$4F,$4E,$55,$53,$40,$40,$40 	 // BONUS@@@
	.byte $33,$30,$30,$30,$30,$50,$54,$53 	 // 30000PTS
	.byte $2f

everyBonus:
	.word $5D0D 
	.byte $45,$56,$45,$52,$59,$40 			 // EVERY@
	.byte $42,$4F,$4E,$55,$53,$40				 // BONUS@ 
	.byte $38,$30,$30,$30,$30,$50,$54,$53	 // 80000PTS
	.byte $3f
	
playerOne:
	.word $5BD5 
	.byte $50,$4C,$41,$59,$45,$52,$40 		 // PLAYER@
	.byte $4F,$4E,$45 							 // ONE
	.byte $3f

playerTwo:
	.word $5BD5 
	.byte $50,$4C,$41,$59,$45,$52,$40		// PLAYER@
	.byte $54,$57,$4F							// TWO
	.byte $3f
	
gameOver:
	.word $5C55 
	.byte $47,$41,$4D,$45,$40,$40			 // GAME@@ 
	.byte $4F,$56,$45,$52						 // OVER
	.byte $3f

TwoUp:
	.word $58B1 
	.byte $32,$55,$50							 // 2UP
	.byte $3f

OneUp:
	.word ArcadeToMegaTextByte($5883)
	.byte $31,$55,$50
	.byte $3f

hiScore:										// High Score
	.word ArcadeToMegaTextByte($5897)
	.byte $48,$49,$40,$53,$43,$4F,$52,$45
	.byte $2f

oolong:										// Oolong
	.word ArcadeToMegaTextByte($5943)
	.byte $4F,$4F,$4C,$4F,$4E,$47
	.byte $2f

ko:												// Ko
	.word ArcadeToMegaTextByte($599F)
	.byte $4B,$4F
	.byte $3f
	

/*	
ko:
	//- This is wrong for rows that have the 8-byte pixie header before visible cells.
	//.word SCREEN_BASE+(RRB_Tail_words*2*($19f>>arcadeRowSize))+$19f-1 // was $599F 
	.byte $4B,$4F								 // KO
	.byte $3f									// end.
*/
stage:
	.word $5C97					
	.byte $53,$54,$41,$47,$45					// STAGE
	.byte $3f

perfect:	
	.word $5981
	.byte $50,$45,$52,$46,$45,$43,$54		// PERFECT
	.byte $3f

credit:
	.word $5F6F
	.byte $43,$52,$45,$44,$49,$54				 // CREDIT
	.byte $3f

konami1985:
	.word ArcadeToMegaTextByte($5F13)
	.byte $3A,$40,$4B,$4F,$4E,$41,$4D,$49,$40,$31,$39,$38,$35	// (C)@KONAMI@1985
	.byte $3F

nextOpponent:
	.word $5953
	.byte $4E,$45,$58,$54,$40					 // NEXT@
	.byte $4F,$50,$50,$4F,$4E,$45,$4E,$54	 // OPPONENT
	.byte $3f

// diagnostic text
ram1ok:
	.word $5999
	.byte $52,$41,$4D,$31,$40,$40				 // RAM1@@
	.byte $4F,$4B								 // OK
	.byte $2f

ram2ok:
	.word $5A19
	.byte $52,$41,$4D,$32,$40,$40				// RAM2@@
	.byte $4F,$4B								// OK
	.byte $2f
	
rom1ok:
	.word $5A99
	.byte $52,$4F,$4D,$31,$40,$40				// ROM1@@
	.byte $4F,$4B,$40							// OK@
	.byte $2F

rom2ok:
	.word $5B19
	.byte $52,$4F,$4D,$32,$40,$40				// ROM2@@
	.byte $4F,$4B,$40							// OK@
	.byte $3F

rambad:
	.word $5999
	.byte $52,$41,$4D,$40,$40,$40,$42,$41,$44	// RAM@@@BAD
	.byte $3f

colorTest:
	.word $58D7
	.byte $43,$4F,$4C,$4F,$52,$40,$54,$45,$53,$54 // COLOR@TEST
	.byte $2f
	
vramColor:
	.word $5907
	.byte $56,$52,$41,$4D,$40,$43,$4F,$4C,$4F,$52 // VRAM@COLOR
	.byte $2f
	
objColor:
	.word $5C87
	.byte $4F,$42,$4A,$40,$40,$43,$4F,$4C,$4F,$52 // OBJ@@COLOR
	.word $3F
	
ioTest:
	.word $58D9
	.byte $49,$4F,$40,$54,$45,$53,$54			 // IO@TEST
	.word $2F
	
OnepLeft:
	.word $5947
	.byte $31,$50,$40,$4C,$45,$46,$54			 // 1P@LEFT
	.word $2F
	
TwopLeft:
	.word $5965
	.byte $32,$50,$40,$4C,$45,$46,$54			 // 2P@LEFT
	.byte $2F
	
OnepRight:
	.word $59C7
	.byte $31,$50,$40,$52,$49,$47,$48,$54	 // 1P@RIGHT
	.byte $2f
	
TwopRight:
	.word $59E5
	.byte $32,$50,$40,$52,$49,$47,$48,$54	 // 2P@RIGHT
	.byte $2f
	
OnePUP:
	.word $5A47
	.byte $31,$50,$40,$55,$50					 // 1P@UP
	.byte $2f

TwoPUP:
	.word $5A65
	.byte $32,$50,$40,$55,$50					 // 2P@UP
	.byte $2f

OnePDown:
	.word $5AC7
	.byte $31,$50,$40,$44,$4F,$57,$4E			// 1P@DOWN
	.byte $2F

TwoPDown:
	.word $5AE5
	.byte $32,$50,$40,$44,$4F,$57,$4E			// 2P@DOWN
	.byte $2F

OnePShoot:
	.word $5B47
	.byte $31,$50,$40,$53,$48,$4F,$4F,$54,$31	// 1P@SHOOT1
	.byte $2f

TwoPShoot2:
	.word $5BC7
	.byte $31,$50,$40,$53,$48,$4F,$4F,$54,$32	// 1P@SHOOT2
	.byte $2F
	
TwoPShoot1:
	.word $5B65
	.byte $32,$50,$40,$53,$48,$4F,$4F,$54,$31	// 2P@SHOOT1
	.byte $2F
OnePShoot2:
	.word $5BE5
	.byte $32,$50,$40,$53,$48,$4F,$4F,$54,$32	// 1P@SHOOT2
	.byte $2F
	
Coin1:
	.word $5C57
	.byte $43,$4F,$49,$4E,$31					// COIN1
	.byte $2F
	
Coin2:	
	.word $5CD7
	.byte $43,$4F,$49,$4E,$32					// COIN2
	.byte $2F
	
Service:	
	.word $5D57
	.byte $53,$45,$52,$56,$49,$43,$45			// SERVICE
	.byte $2F
	
OnePStart:	
	.word $5DD7
	.byte $31,$50,$40,$53,$54,$41,$52,$54		// 1P@START
	.byte $2F

TwoPSTart:	
	.word $5E57
	.byte $32,$50,$40,$53,$54,$41,$52,$54		// 2P@START
	.byte $3F
	
CoinCounter1:	
	.word $5A55
	.byte $43,$4F,$49,$4E,$40,$43,$4F,$55,$4E,$54,$45,$52,$40,$31 //COIN@COUNTER@1
	.byte $3F
	
DipSWSelect:
	.word $58D7
	.byte $44,$49,$50,$53,$57,$40,$53,$45,$4C,$45,$43,$54		 //DIPSW@SELECT
	.byte $2F
	
BonusPoint:
	.word $5A89
	.byte $42,$4F,$4E,$55,$53,$40,$50,$4F,$49,$4E,$54			 //BONUS@POINT
	.byte $2F
	
FirstEveryPts:
	.word $5B4D
	.byte $46,$49,$52,$53,$54,$40,$40,$40,$30,$30,$30,$30,$40,$50,$54,$53			 //FIRST@@@0000@PTS
	.byte $2F,$5B,$CD,$45,$56,$45,$52,$59,$40,$40,$40,$30,$30,$30,$30,$40,$50,$54,$53 //EVERY@@@0000@PTS
	.byte $2F
	
DemoSound:
	.word $5D4D
	.byte $44,$45,$4D,$4F,$40,$53,$4F,$55,$4E,$44,$40,$40,$40,$4F,$40,$40			 //DEMO@SOUND@@@O@@
	.byte $2F

Player:
	.word $5DCD
	.byte $50,$4C,$41,$59,$45,$52													 //PLAYER
	.byte $3F
	
	
Coin1b:
	.word $5949
	.byte $43,$4F,$49,$4E,$31														 //COIN1
	.byte $2F

Coin:
	.word $595D
	.byte $43,$4F,$49,$4E															 //COIN
	.byte $2F
	
Play:
	.word $596F
	.byte $50,$4C,$41,$59															 //PLAY
	.byte $2F
	
Coin2b:
	.word $59C9
	.byte $43,$4F,$49,$4E,$32														 //COIN2
	.byte $2F

Coinb:	
	.word $59DD
	.byte $43,$4F,$49,$4E															 //COIN
	.byte $2F
	
Playb:
	.word $59EF
	.byte $50,$4C,$41,$59															 //PLAY
	.byte $3F
	
FreePlay:
	.word $5989
	.byte $46,$52,$45,$45,$40,$50,$4C,$41,$59,$40								//FREE@PLAY@
	.byte $3F
	
Table:
	.word $5E4D
	.byte $54,$41,$42,$4C,$45,$40,$40,$40										//TABLE@@@
	.byte $3F
	
UpRight:
	.word $5E4D
	.byte $55,$50,$40,$52,$49,$47,$48,$54										//UP@RIGHT
	.byte $3F
	

SoundTest:
	.word $5AD5
	.byte $53,$4F,$55,$4E,$44,$40,$54,$45,$53,$54								//SOUND@TEST
	.byte $2F
	

SoundCode:
	.word $5B53
	.byte $53,$4F,$55,$4E,$44,$40,$43,$4F,$44,$45								//SOUND@CODE
	.byte $3F
	

Invalidity:
	.word $5989
	.byte $49,$4E,$56,$41,$4C,$49,$44,$49,$54,$59								//INVALIDITY
	.byte $3F
	
Time:	
	.word $5EF1
	.byte $54,$49,$4D,$45															 //TIME
	.byte $3F	// token
	

/************
*High Scores*
************/
	
scoreRanking:
	.word ArcadeToMegaTextByte($58D5)
	.byte $53,$43,$4F,$52,$45,$40,$52,$41,$4E,$4B,$49,$4E,$47			   //SCORE@RANKING
	.byte $2F
	
rankPointStageName:
	.word ArcadeToMegaTextByte($5945)
	.byte $52,$41,$4E,$4B,$40,$40,$50,$4F,$49,$4E,$54,$40,$40,$40,$53,$54,$41,$47,$45,$40,$40,$40,$4E,$41,$4D,$45
	.byte $2F
	
first:	
	.word ArcadeToMegaTextByte($59C5)
	.byte $31,$53,$54	//1ST
	.byte $2F
second:
	.word ArcadeToMegaTextByte($5A45)
	.byte $32,$4E,$44	//2ND
	.byte $2F
	
third:
	.word ArcadeToMegaTextByte($5AC5)
	.byte $33,$52,$44	//3RD
	.byte $2F
	
fourth:	
	.word ArcadeToMegaTextByte($5B45)
	.byte $34,$54,$48	//4TH
	.byte $2F
	
fifth:
	.word ArcadeToMegaTextByte($5BC5)
	.byte $35,$54,$48	//5TH
	.byte $2F
	
sixth:
	.word ArcadeToMegaTextByte($5C45)
	.byte $36,$54,$48	//6TH
	.byte $2F
	
seventh:
	.word ArcadeToMegaTextByte($5CC5)
	.byte $37,$54,$48	//7TH
	.byte $2F
	
eighth:
	.word ArcadeToMegaTextByte($5D45)
	.byte $38,$54,$48	//8TH
	.byte $2F
	
ninth:
	.word ArcadeToMegaTextByte($5DC5)
	.byte $39,$54,$48	//9TH
	.byte $2F
	
tenth:
	.word ArcadeToMegaTextByte($5E45)
	.byte $31,$30,$54,$48 //10TH
	.byte $3F
	
OneUpb:
	.word ArcadeToMegaTextByte($58C5)
	.byte $31,$55,$50	//1UP
	
TwoUpb:
	.word ArcadeToMegaTextByte($58C5)
	.byte $32,$55,$50	//2UP
	.byte $3F
	
timeOver:
	.word ArcadeToMegaTextByte($5B55)
	.byte $54,$49,$4D,$45,$40,$4F,$56,$45,$52 //TIME@OVER
	.byte $3F
	


/***********************************
* Function pointers to game states *
* Called from function dispatcher  *
***********************************/

d9f0:
	.word loc_8bdd	//R=>L State 1
	.word loc_8cf6 // ???
	.word loc_8de2
	.word loc_8242
	
d9f8:        		
	.word loc_8be5	//R=>L State 2
	.word loc_8bf8	//Splash State
	.word loc_8be5	//R=>L State
	.word loc_8c44	//Playfield/HighScore state 
	
da00:
	.word loc_8be5	//R=>L State
	.word loc_8c5b
	.word loc_8be5	//R=>L State

da06:
	.word da0a,da26

da0a:	
	.byte $f0,$00,$a0,$08,$30,$21,$08,$08 
	.byte $38,$22,$38,$28,$28,$12,$38,$21 
	.byte $12,$21,$20,$18,$10,$28,$20,$26 
	.byte $34,$08,$20,$25
	
da26:
	.byte $f0,$02,$a8,$02,$08,$12,$50,$14
	.byte $30,$08,$20,$1a,$20,$28,$20,$29
	.byte $20,$08,$20,$18,$68,$08,$20,$28
	.byte $84,$08,$20,$25,$10,$08,$20,$25
	.byte $e0,$e1,$e2,$e3,$e4,$e5,$f0,$f1
	.byte $f2,$f3,$e8,$e9,$ea,$eb,$ec,$ed
	.byte $f8,$f9,$fa,$fb,$28,$61,$02,$41
	.byte $28,$71,$03,$41,$28,$81,$0c,$41
	

/*****************************
* Yie Ar Kung Fu Sprite Logo *
*****************************/

da46:
	.byte $e0,$e1,$e2,$e3,$e4,$e5,$f0,$f1,$f2
	.byte $f3,$e8,$e9,$ea,$eb,$ec,$ed,$f8,$f9
	.byte $fa,$fb

da5a:
/**************
*Sprite 1 - KO*
***************/

	.byte	$28,$61	 // Y coord,X coord
	.byte	$02,$41 	 // Tile#, [FlipX ( bit 6 ) + Page ( 2nd page )] <== these will change according to our sprite sheet.
	
	
/**************
*Sprite 2 - ON*
***************/
	.byte	$28,$71
	.byte	$03,$41
	
/**************
*Sprite 3 - NA*
***************/
	.byte	$28,$81
	.byte	$0C,$41
	

/*******************
* DA70 - Jump Table*
*******************/

// 8DEA - pause/timer routine between transitions
// 8DF3 - set up player,lives,enemy name ..etx ( copies data from 506x to 503x )
// 8E1E - determines which method to call from table below at DA82
// 8E7D - counters but for what ? 5437, 5439
// 8EF5 - ?
// 8DF0 - determines which method to call from table below at DA8E
// 8F14 - ???

da70:
	.word loc_8dea, loc_8df3, loc_8e1e, loc_8e7d
	.word loc_8ef5, loc_8df0, loc_8f14, loc_8f86
	.word loc_8f8f
	
da82:
	.word loc_90b4, loc_919e, loc_8e26
	.word loc_8e4f, loc_8e58, loc_8e66

da8e:
	.word loc_8fc6, loc_8ff4

da92:
	.word loc_902b, loc_9052, loc_9076
	
daba:
	.word loc_9252,loc_926d,loc_9285
	
dbb2:
	.byte $c9,$bc,$bc,$bc,$bc,$bc,$bc,$bc 
	.byte $bc,$bc,$bc,$bc,$af,$bc,$bc,$bc
	.byte $bc,$bc,$f8,$b4,$bc,$bc,$bc,$bc
	.byte $bc,$bc,$bc,$bc
	

e172:
	.byte $10,$83,$33,$32,$33,$83,$83,$83 
	.byte $83,$83,$83,$83,$83,$83,$83,$83 
	.byte $83,$83,$83,$83,$83,$83,$83,$83 
	.byte $83,$83,$83,$83,$83,$83,$83,$83 
	.byte $83,$83,$41,$42,$43,$83,$45,$83 
	.byte $83,$83,$83,$83,$83,$8D,$8E,$8F 
	.byte $8E,$81,$82,$83,$87,$86,$86,$87 
	.byte $83,$83,$83,$83,$83,$83
	

ff39:
	.byte $ff,$04,$03,$ff,$ff,$ff,$02,$05 
	.byte $ff,$00,$01,$00,$00,$ff,$4c,$ff
	.byte $65,$ff,$7e,$05,$0a,$05,$05,$05
	.byte $05,$05,$0a,$05,$05,$0a,$05,$0a
	.byte $05,$0a,$05,$05,$0a,$05,$05,$0a
	.byte $05,$05,$05,$05,$04,$06,$05,$05
	.byte $04,$06,$05,$05,$05,$04,$05,$04
	.byte $04,$06,$05,$05,$05,$05,$05,$04
	.byte $05,$06,$06,$06,$04,$04,$05

/************************************************************
* Pixie Data (RRB soft sprite entry)                        *
* Default Pixie struct created during init for each row     *
*                                                           *
* byte 0 – Raster X position (low 8 bits)                   *
* byte 1 – Raster X position (upper 2 bits)                 *
* (bits 0–1 used, bits 2–7 ignored)                         *
*                                                           *
* byte 2 – Tile Index (low byte)                            *
*           Lower 8 bits of the 16‑bit tile number.         *
*                                                           *
* byte 3 – Tile Bank / Tile Page (high byte)                *
*           Upper 8 bits of the 16 bit tile number.         *
*           Selects which 256 tile page the pixie uses.     *
*                                                           *
* byte 4 - GOTOX command - low bytes                        *
* byte 5 - GOTOX command - high byte                        *
*(Final GOTOX to 320, ensure raster ends of screen          *
*************************************************************/
// each page = 255 characters, this corresponds to 0x100 offset when looking at 8x8 tiles
// when looking at sprites, these are 16x16. Therefore a single page = 0x40 for offset when looking at the sheet.


/* Sprite calculation for Mega65 

On Arcade Blank TILE is page 1 of Spritesheet, 16x16 TILE # 0x13 [ 19 ]
Or $113

Since Spritesheet on the Mega65 is added to the tilesheet

1. Calculate start of Spritesheet.
Spritesheet starts at page 2 [ 512 characters / 256 per page ]

2. Calculate page from arcade and convert to Mega65
1 Page of Sprite is [ 256 16x16 objects ] = [512 8x8 Mega65 tiles]
Multiply page# by 2 to get corresponding Page# on Mega65 for the object
Calculation: Start at page 2 + page# of sprite * 2.
Find tile offset: 13 
*/

RRB_PixieProtoType: // set this to a blank tile and move off screen, say 0xff. for now we want to see them all as we troubleshoot
	.byte 255, 1	// raster (move offscreen-ish) , 255,0
	.byte 69, $06	// tile (will be offset by TILE_OFFSET)
	.byte 64, 1		// gotox (64,1 == 320 EOL)
		
RRB_ColorProtoType:
	// control,mask, flip/attr(2), gotox ctrl word(2)
	.byte $98,$ff
	.byte $00,$00
	.byte $10,$00   
		
