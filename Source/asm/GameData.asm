*=* "Game Data - GameData.asm"


GDEnumNames:
.const BUCHU	= 0
.const STAR	= 1
.const NUNCHA	= 2
.const POLE	= 3
.const FEEDLE	= 4
.const CHAIN	= 5
.const CLUB	= 6
.const FAN		= 7
.const SWORD	= 8
.const TONFUN	= 9
.const BLUES	= 10

/***********************************
*0x4000 W  control port            *
*bit 0 - flip screen			0x1   *
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

	.byte $30,$40,$46,$41,$4E				// @FAN
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
	
/*	
ko:
	// Per-row hidden prefix bytes before visible text starts.
	// Most rows = 0.
	// Row 6 has a 16-byte hidden prefix due to pixie/RRB header layout.
	.byte $4B,$4F								 // KO
	.byte $3f									// end.
*/

ko:												// Ko
	.word ArcadeToMegaTextByte($599F)
	.byte $4B,$4F
	.byte $3f
	


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
	
	
/* Jump table for waterfall animation */	
daba:
	.word loc_9252,loc_926d,loc_9285
	
dbb2:
	.byte $c9,$bc,$bc,$bc,$bc,$bc,$bc,$bc 
	.byte $bc,$bc,$bc,$bc,$af,$bc,$bc,$bc
	.byte $bc,$bc,$f8,$b4,$bc,$bc,$bc,$bc
	.byte $bc,$bc,$bc,$bc
	
	
// Playfield.

e172:
	.byte $10,$83,$33,$32,$33,$83,$83,$83
	.byte $83,$83,$83,$83,$83,$83,$83,$83
	.byte $83,$83,$83,$83,$83,$83,$83,$83
	.byte $83,$83,$83,$83,$83,$83,$83,$83
	.byte $83,$83,$41,$42,$43,$83,$45,$83
	.byte $83,$83,$83,$83,$83,$8D,$8E,$8F
	.byte $8E,$81,$82,$83,$87,$86,$86,$87
	.byte $83,$83,$83,$83,$83,$83,$83,$33
	.byte $32,$50,$51,$52,$53,$54,$55,$50
	.byte $83,$83,$83,$9B,$8E,$9D,$9E,$9E
	.byte $91,$91,$92,$93,$97,$95,$96,$97
	.byte $98,$83,$83,$83,$83,$45,$83,$43
	.byte $42,$60,$61,$62,$63,$64,$65,$66
	.byte $44,$44,$44,$AB,$AC,$AD,$9E,$CE
	.byte $91,$A1,$A2,$D5,$B5,$A5,$A6,$A7
	.byte $A8,$A9,$83,$83,$50,$55,$54,$53
	.byte $52,$70,$61,$72,$39,$74,$75,$76
	.byte $3D,$40,$34,$CB,$CC,$9E,$BE,$BF
	.byte $C0,$C1,$B2,$A6,$A5,$B5,$B6,$B7
	.byte $B8,$B9,$44,$44,$66,$65,$64,$63
	.byte $62,$78,$37,$38,$39,$3A,$3B,$3C
	.byte $35,$3E,$3F,$CB,$CC,$CD,$CE,$CF
	.byte $C0,$C1,$C2,$C3,$A5,$C5,$D3,$C7
	.byte $C8,$FA,$CA,$3D,$76,$75,$74,$39
	.byte $72,$78,$47,$48,$49,$4A,$4B,$4C
	.byte $4D,$4E,$4F,$D2,$DC,$DD,$DE,$D3
	.byte $D0,$D1,$D2,$D3,$C5,$D5,$D6,$D3
	.byte $D8,$D9,$DA,$35,$3C,$3B,$3A,$39
	.byte $38,$78,$47,$58,$59,$5A,$5B,$5C
	.byte $5D,$5E,$5F,$EB,$EC,$ED,$EE,$EF
	.byte $E0,$E1,$E2,$E3,$E3,$E5,$E6,$E7
	.byte $D3,$E9,$B9,$35,$4C,$4B,$4A,$49
	.byte $48,$78,$78,$58,$69,$6A,$6B,$6C
	.byte $6D,$6E,$6F,$FB,$EC,$FD,$FE,$FF
	.byte $F0,$F1,$E2,$F3,$B7,$F5,$F6,$DC
	.byte $C7,$F9,$FA,$CA,$5C,$5B,$5A,$59
	.byte $58,$78,$78,$78,$69,$7A,$7B,$6C
	.byte $7D,$7E,$7F,$6C,$01,$02,$03,$04
	.byte $25,$06,$E2,$0E,$DC,$0A,$2A,$29
	.byte $28,$0E,$D9,$DA,$47,$6B,$6A,$69
	.byte $58,$47,$78,$78,$59,$83,$84,$6C
	.byte $86,$87,$88,$10,$11,$12,$13,$14
	.byte $15,$16,$17,$18,$19,$1A,$1B,$1C
	.byte $1D,$1E,$E9,$B9,$3D,$7B,$7A,$69
	.byte $78,$47,$A0,$91,$91,$93,$94,$91
	.byte $96,$97,$98,$20,$21,$22,$23,$24
	.byte $25,$26,$27,$28,$29,$2A,$2A,$2C
	.byte $3B,$2E,$2F,$2E,$CA,$84,$83,$59
	.byte $78,$47,$A0,$A1,$A2,$A3,$A4,$A5
	.byte $A6,$A7,$A8,$30,$31,$32,$33,$34
	.byte $35,$35,$27,$35,$39,$39,$3B,$3C
	.byte $3D,$3D,$3F,$00,$77,$3E,$83,$47
	.byte $47,$47,$B0,$B1,$B2,$B3,$B4,$B5
	.byte $B6,$B7,$B8,$40,$41,$43,$43,$44
	.byte $45,$46,$47,$48,$48,$4B,$4B,$4C
	.byte $4D,$4E,$4F,$71,$69,$6A,$70,$0F
	.byte $78,$51,$51,$C1,$C2,$C3,$C4,$C5
	.byte $51,$C4,$51,$50,$51,$50,$53,$54
	.byte $55,$56,$57,$58,$58,$57,$57,$5C
	.byte $5D,$5E,$5F,$72,$79,$7A,$7B,$1F
	.byte $4A,$D0,$D0,$63,$D2,$D3,$D4,$D5
	.byte $D6,$D5,$D3,$63,$61,$62,$63,$64
	.byte $65,$66,$67,$E3,$E3,$67,$67,$E3
	.byte $E3,$6E,$6F,$08,$07,$08,$09,$59
	.byte $5A,$E3,$E3,$E3,$E2,$E3,$E3,$E3
	.byte $E3,$E3,$E3,$E3,$E3,$E3,$73,$74
	.byte $75,$73,$E3,$92,$92,$92,$92,$7C
	.byte $7D,$7D,$92,$92,$92,$92,$92,$5A
	.byte $E3,$92,$92,$92,$92,$92,$92,$92
	.byte $7D,$7D,$7C,$92,$92,$92,$92,$92
	.byte $92,$92,$7D,$7C,$7C,$92,$92,$92
	.byte $92,$92,$92,$92,$92,$92,$0C,$92
	.byte $5A,$92,$92,$7D,$7C,$0D,$92,$92
	.byte $92,$92,$92,$92,$92,$92,$0D,$7C
	.byte $7D,$92,$92,$92,$92,$92,$92,$92
	.byte $92,$92,$7C,$7C,$7D,$92,$92,$0C
	.byte $92,$92,$92,$92,$92,$92,$92,$92
	.byte $92,$92,$92,$92,$92,$7C,$7D,$7D
	.byte $92,$92,$92,$92,$92,$92,$92,$92
	.byte $92,$92,$92,$92,$92,$92,$92,$92
	.byte $92,$92,$92,$92,$92,$92,$0D,$7C
	.byte $7D,$92,$92,$92,$92,$92,$92,$92
	.byte $92,$92,$92,$92,$92,$92,$92,$92
	.byte $92,$92,$92,$92,$92,$92,$92,$92
	.byte $92,$92,$92,$92,$92,$92,$92,$92
	.byte $92,$92,$92,$92,$92,$92,$92,$92
	.byte $92,$92,$92,$92,$92,$92,$92,$92
	.byte $92,$92,$92,$92,$92,$92,$92,$92
	.byte $92,$92,$92,$92,$92,$92,$92,$92
	.byte $92,$92,$92,$92,$92,$92,$92,$92
	.byte $92,$92,$92,$92,$92,$92,$92,$92
	.byte $92,$92,$92,$92,$92,$92,$92,$92
	.byte $92
	
	//.byte $92,$92,$92,$92,$92,$92,$92
	//.byte $92,$92,$92,$92,$92,$92,$92,$92
	//.byte $92,$92,$92,$92,$92,$92,$92,$92
	//.byte $92,$92,$92,$92,$92,$92,$92,$92
	//.byte $92
	
playfieldAttrData:
	.byte $00,$80,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$80
	.byte $00,$00,$00,$80,$80,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$80,$80
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$80,$00,$00,$40,$00
	.byte $00,$00,$00,$80,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$80,$00,$80,$80
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$40,$80,$00,$00,$00,$00
	.byte $00,$00,$80,$80,$80,$80,$80,$80
	.byte $00,$40,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$40,$40,$00,$00,$00,$40
	.byte $40,$00,$80,$80,$00,$00,$00,$00
	.byte $00,$00,$80,$80,$80,$80,$80,$80
	.byte $00,$00,$00,$40,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$80,$00,$40,$00,$00
	.byte $80,$00,$40,$80,$80,$80,$80,$80
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$40,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$80,$00,$00,$00,$00
	.byte $00,$00,$80,$80,$80,$80,$C0,$80
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$40
	.byte $00,$00,$80,$80,$80,$80,$80,$80
	.byte $00,$00,$40,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$40,$00,$00,$00,$00
	.byte $00,$40,$00,$80,$00,$00,$80,$00
	.byte $00,$00,$00,$80,$80,$80,$80,$80
	.byte $00,$00,$00,$50,$00,$00,$00,$00
	.byte $00,$00,$10,$10,$10,$10,$10,$10
	.byte $10,$40,$90,$00,$10,$90,$90,$10
	.byte $10,$00,$00,$C0,$80,$80,$80,$C0
	.byte $00,$00,$00,$50,$10,$10,$00,$10
	.byte $10,$10,$10,$10,$10,$10,$10,$10
	.byte $10,$10,$10,$10,$10,$10,$10,$10
	.byte $10,$00,$00,$00,$80,$80,$C0,$80
	.byte $00,$10,$10,$10,$10,$10,$10,$10
	.byte $10,$10,$10,$10,$10,$10,$10,$10
	.byte $10,$10,$10,$10,$10,$10,$10,$10
	.byte $10,$10,$10,$00,$90,$10,$C0,$00
	.byte $00,$10,$10,$10,$10,$10,$10,$10
	.byte $10,$10,$10,$10,$10,$10,$10,$10
	.byte $10,$10,$90,$10,$10,$10,$10,$10
	.byte $10,$10,$10,$10,$10,$10,$C0,$80
	.byte $00,$10,$10,$10,$10,$10,$10,$10
	.byte $10,$10,$10,$10,$90,$10,$10,$10
	.byte $10,$10,$10,$10,$10,$10,$10,$10
	.byte $10,$10,$10,$10,$10,$10,$10,$10
	.byte $10,$10,$10,$10,$10,$10,$10,$10
	.byte $90,$10,$10,$10,$10,$10,$10,$10
	.byte $10,$10,$10,$90,$90,$10,$10,$10
	.byte $10,$10,$10,$10,$10,$10,$10,$10
	.byte $90,$10,$10,$10,$10,$10,$10,$10
	.byte $90,$10,$10,$10,$10,$10,$10,$10
	.byte $10,$10,$10,$10,$90,$10,$10,$10
	.byte $10,$10,$90,$10,$10,$10,$10,$10
	.byte $10,$10,$10,$10,$10,$10,$10,$90
	.byte $90,$90,$10,$90,$10,$10,$10,$10
	.byte $90,$10,$10,$10,$10,$10,$10,$10
	.byte $90,$10,$10,$10,$10,$10,$10,$10
	.byte $10,$10,$10,$10,$10,$10,$10,$10
	.byte $90,$90,$10,$10,$10,$10,$10,$10
	.byte $10,$90,$10,$90,$10,$10,$10,$10
	.byte $10,$10,$10,$10,$10,$10,$10,$10
	.byte $10,$10,$10,$90,$10,$10,$10,$10
	.byte $10,$10,$10,$10,$10,$90,$10,$10
	.byte $10,$10,$10,$10,$10,$10,$10,$10
	.byte $10,$10,$90,$10,$10,$10,$10,$10
	.byte $10,$10,$10,$10,$10,$10,$10,$10
	.byte $10,$10,$10,$10,$10,$10,$90,$10
	.byte $10,$10,$10,$10,$10,$10,$10,$10
	.byte $10,$10,$10,$10,$10,$10,$10,$10
	.byte $10,$10,$10,$10,$10,$90,$10,$10
	.byte $10,$10,$10,$10,$10,$10,$10,$10
	.byte $10,$10,$10,$10,$10,$10,$10,$10
	.byte $10,$10,$10,$10,$10,$10,$10,$10
	.byte $10,$10,$10,$10,$10,$10,$10,$10
	.byte $10,$10,$10,$10,$10,$10,$10,$10
	.byte $10,$10,$10,$10,$10,$10,$10,$10
	.byte $10,$10,$10,$10,$10,$10,$10,$10
	.byte $10,$10,$10,$10,$10,$10,$10,$10
	.byte $10,$10,$10,$10,$10,$10,$10,$10
	.byte $10,$10,$10,$10,$10,$10,$10,$10
	.byte $10,$10,$10,$10,$10,$10,$10,$10
	
/* 
	Lookup Table for sub_9315
*/
	
e758:
	.word e760,e77a,e78b,e760
	
e760:
	.byte $00,$20,$28,$10,$20,$1a,$00,$03 
	.byte $04,$11,$24,$01,$20,$10,$00,$0d 
	.byte $08,$0a,$00,$06,$00,$17,$ff,$ff 
	.byte $ff,$ff
e77a:	
	.byte $00,$20,$21,$10,$00,$10 
	.byte $12,$10,$00,$10,$21,$10,$00,$08 
	.byte $00,$ff,$ff
e78b:	
	.byte $00,$20,$12,$20,$00 
	.byte $20,$18,$20,$00,$20,$14,$20,$02 
	.byte $20,$00,$20,$ff,$ff
	
e79d:
	.word e7a9,e7ad,e7ae,e7b0
	.word e7b6,e7bc
	
e7a9:
	.byte $02,$03,$00,$01
e7ad:
	.byte $00,$01,$00,$04
e7ae:
	.byte $05,$02,$03,$00
e7b0:
	.byte $01,$03,$04,$05
e7b6:
	.byte $00,$01,$02,$02
e7bc:
	.byte $01,$00,$03
	

e7c0:
	.byte $01,$00,$02,$20,$02,$20,$01,$00
	.byte $02,$20,$02,$20,$01,$20,$01,$20
	.byte $01,$20,$01,$20,$01,$20,$01,$20
	.byte $02,$81,$01,$20,$01,$20,$01,$20
	.byte $01,$20,$01,$20,$01,$20,$01,$20
	.byte $02,$20,$01,$20,$01,$20,$01,$20
	.byte $01,$20,$02,$10,$01,$20,$01,$20
	.byte $01,$20,$01,$20

/**********************************
* Player 1 frames                 *
* Refer to sprite sheet for ref   *
**********************************/

e7fc:
	// pointers to sprite frame data

	.word e840,e838,e848,e858		// walk, walk, walk, jump
	.word e860,e870,e880,e888		// block,block,jump,duck
	.word e898,e8a8,e8b8,e8c0
	.word e8c8,e8d8,e8e0,e8e8
	.word e8f0,e8f8,e908,e910
	.word e918,e928,e930,e938
	.word e940,e948,e900,e8b0
	.word e958,e858
	
// data for pointers above

/*************************************
* Player 1 walking frames			  *
*************************************/

e838:
	.byte $0b,$00,$02,$40,$0b,$40,$03,$40	// player 1 walk frame 1
e840:
	.byte $08,$40,$00,$40,$08,$00,$01,$40	
e848:	
	.byte $0b,$00,$02,$40,$0b,$40,$03,$40	
e850:	
	.byte $08,$40,$00,$40,$08,$00,$01,$40	
	
/************************************
* Player 1 Jump Frame				 *
*************************************/
	
e858:
	.byte $1a,$40,$12,$40,$1a,$00,$13,$40	// Player 2 jump frame 1
	
	
/************************************
* Player 1 upper block frame		 *
*************************************/

e860:
	.byte $0b,$00,$14,$40,$0a,$00,$15,$40	// Frame 1
	
/*************************************
* Player 1 lower block frame		  *
**************************************/

e868:	
	.byte $08,$40,$16,$40,$08,$00,$17,$40	// Frame 1
	
e870:	
	.byte $08,$40,$16,$40,$08,$00,$17,$40	// Frame 2
	
/************************************
* Player 1 upper block frame v2		 *
*************************************/

e878:	
	.byte $0a,$40,$14,$40,$0b,$40,$15,$40

/*************************************
* Player 1 jumping upper block frame *
**************************************/
		
e880:
	.byte $0c,$40,$04,$40,$0d,$40,$05,$40
	
/************************************
* Player 1 ducking frame			*
*************************************/
	
e888:	
	.byte $0e,$40,$06,$40,$0f,$40,$07,$40

/***************************************
* Player 1 jumping upper block frame   *
****************************************/
	
e890:
	.byte $0c,$40,$04,$40,$0d,$40,$05,$40

/*************************************
* Player 1 ducking frame			 *
**************************************/	
	
e898:	
	.byte $0e,$40,$06,$40,$0f,$40,$07,$40
	
/****************************************
* Player 1 jumping upper block frame    *
*****************************************/

e8a0:	
	.byte $0c,$40,$04,$40,$0d,$40,$05,$40
	
/*************************************
* Player 1 jumping upper block frame *
**************************************/

e8a8:	
	.byte $0c,$40,$04,$40,$0d,$40,$05,$40
	
/***********************************
* Player 1 Upforward Punch attack  *
************************************/
	
e8b0:	
	.byte $3c,$40,$34,$40,$3d,$40,$35,$40
	
/********************************
* Player 1 Forward Punch attack *
*********************************/
	
e8b8:	
	.byte $2a,$40,$22,$40,$2b,$40,$23,$40
	

/*****************************
* Player 1 Up Punch attack   *
******************************/
	
e8c0:	
	.byte $28,$40,$20,$40,$29,$40,$21,$40
	
/*******************************
* Player 1 Upback Punch attack *
********************************/
	
e8c8:
	.byte $3a,$40,$32,$40,$3b,$40,$33,$40
	
/**********************
* Player 1 crouching  *
***********************/	
	
e8d0:
	.byte $38,$40,$30,$40,$39,$40,$31,$40
	
/*****************************
* Player 1 Back Punch attack *
******************************/		
	
e8d8:
	.byte $53,$40,$1c,$40,$54,$40,$1d,$40
e8e0:
	.byte $2e,$40,$26,$40,$2f,$40,$27,$40
e8e8:
	.byte $36,$40,$3e,$40,$3f,$40,$37,$40
e8f0:
	.byte $2c,$40,$24,$40,$2d,$40,$25,$40
e8f8:
	.byte $f6,$41,$ee,$41,$f7,$41,$ef,$41
e900:	
	.byte $18,$40,$10,$40,$19,$40,$11,$40
e908:	
	.byte $4c,$40,$44,$40,$4d,$40,$45,$40
e910:	
	.byte $5a,$40,$52,$40,$5b,$40,$09,$40
e918:	
	.byte $58,$40,$50,$40,$59,$40,$51,$40
e920:
	.byte $48,$40,$40,$40,$49,$40,$41,$40
e928:	
	.byte $4a,$40,$42,$40,$4b,$40,$43,$40
e930:	
	.byte $5c,$40,$56,$40,$5d,$40,$09,$00
e938:	
	.byte $5e,$40,$09,$40,$5f,$40,$57,$40
e940:	
	.byte $4e,$40,$46,$40,$4f,$40,$47,$40
e948:	
	.byte $1e,$40,$09,$40,$1e,$00,$09,$40
e950:	
	.byte $1f,$00,$09,$40,$1f,$40,$09,$40
e958:	
	.byte $f6,$41,$ee,$41,$f7,$41,$ef,$41
e960:	
	.byte $00,$80,$00,$e0,$00,$e0,$02,$00
e968:	
	.byte $08,$00,$08,$00,$00,$80,$08,$00
e970:	
	.byte $08,$00,$02,$00,$10,$00,$08,$00
e978:	
	.byte $08,$00,$10,$00,$10,$00,$f8,$00
e980:	
	.byte $10,$00,$01,$00,$10,$00,$08,$00
e988:	
	.byte $08,$00,$10,$00,$10,$00,$f8,$00
e990:	
	.byte $10,$00,$02,$80,$02,$80,$02,$80
e998:	
	.byte $02,$80,$02,$80,$02,$80,$02,$80
e9a0:	
	.byte $02,$80,$18,$16,$15,$18,$16,$15
e9a8:
	.byte $18,$14,$20,$18,$14,$20,$18,$14
e9b0:
	.byte $20,$18,$14,$40,$18,$14,$40,$18
e9b8:
	.byte $14,$40,$18,$14,$30,$18,$16,$2b
e9c0:
	.byte $18,$16,$2b,$04,$01,$02,$06,$06
e9c8:
	.byte $04,$04
	
e9ca:
	.word e9d8 
e9cc:
	.word e9e0
e9ce: 
	.word e9e2
e9d0: 
	.word e9e6
e9d2: 
	.word e9f2
e9d4:
	.word e9fe
e9d6:
	.word ea06
	
	
e9d8:
	.byte $00,$00,$00,$10,$10,$00,$10,$10
e9e0:
	.byte $00,$00
e9e2:	
	.byte $00,$00,$00,$10
e9e6:
	.byte $00,$00,$00,$10,$10,$00,$10,$10,$20,$00,$20,$10
e9f2:	
	.byte $00,$00,$00,$10,$00,$20,$10,$00,$10,$10,$10,$20
e9fe:	
	.byte $00,$00,$10,$00,$20,$00,$20,$10
ea06:	
	.byte $00,$00,$10,$00,$20,$00,$00,$10
	
// function pointers to routine to play low energy music 	
ea0e:
	.word loc_c6aa,loc_c6aa,loc_c6aa	
	
ea1c:
	.byte $00,FEEDLE,$05,$08,$52,$53,$54,$55
	.byte $08,$08,$08,$00,$00,$01,$01,$02
	.byte $02,$00,$01,$01,$01,$01,$01,$02
	.byte $02,$00,$03,$00,$02,$01,$00,$02
	.byte $01,$00,$01,$00,$02,$03,$02,$02
	.byte $02,$01,$00,$02,$01,$00,$02,$01
	.byte $00,$02,$01,$00,$02,$01,$02,$01
	.byte $00,$02,$01,$00,$02,$01,$00,$00
	.byte $02,$01,$00,$04,$00,$00,$01,$02
	.byte $03,$07,$08,$09
	
f368:
	.byte $f4,$98,$f4,$a0,$f4,$a8,$f4,$b0
	.byte $f5,$11,$f5,$16,$f5,$1f,$f5,$21
	.byte $f5,$28
	
	// feedle stage ??
	
f820:
	.byte $41,$63,$41,$09,$40,$09,$40,$68
	.byte $41,$60,$41,$69,$41,$61,$41,$09
	.byte $40,$77,$41,$6A,$41,$62,$41,$6B
	.byte $41,$63,$41,$09,$40,$09,$40,$6C
	.byte $41,$64,$41,$6D,$41,$65,$41,$09
	.byte $40,$09,$40,$6E,$41,$66,$41,$6F
	.byte $41,$67,$41,$09,$40,$09
	
f8dd:
	.byte $09,$08,$09,$08,$09,$0a,$ff
f8e4:	
	.byte $05,$04,$04,$06,$06,$ff,$09,$0a
	.byte $09,$0a,$05,$ff,$05,$04,$04,$04
	.byte $05,$ff,$09,$08,$09,$08,$0a,$ff
	.byte $06,$05,$05,$04,$04,$ff,$03,$03
	.byte $03,$03,$03,$ff

f914:
	.byte $e6,$01,$e7,$01,$e6,$81,$e7,$81
f91c:
	.byte $00,$01,$00,$01,$ff,$01,$ff,$01
	.byte $ff,$01,$ff,$01,$ff,$00,$ff,$00
	.byte $ff,$00,$ff,$00,$ff,$ff,$ff,$ff
	.byte $ff,$ff,$ff,$ff,$00,$ff,$00,$ff	
	
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

ff80:
	.byte $05,$04,$04,$05,$05,$05,$05,$04 
	.byte $04,$04,$05,$05,$06,$06,$06,$05 
	.byte $05,$04,$05,$05,$06,$04,$06,$04 
	.byte $03,$06,$05,$03,$04,$05,$03,$05 
	.byte $06,$05,$05,$06,$ff,$05,$00,$02 
	.byte $c0,$02,$30,$02,$c0,$00,$00 

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
		
