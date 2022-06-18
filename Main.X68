*-----------------------------------------------------------
*
* Include file for Battleship.X68
* 
*-----------------------------------------------------------

* Game loop

gameLoop    cmp.b   #0,gameMode       
            beq     setupMode
            cmp.b   #1,gameMode       
            beq     beginMessage
            cmp.b   #2,gameMode
            beq     cmpSetup
            cmp.b   #3,gameMode
            beq     playMode 
            cmp.b   #4,gameMode
            beq     gameOver  
gameContd   
            jsr     gridRfrsh
            bra     gameLoop

setupMode   
            jsr     setup
            bra     gameContd
            
beginMessage
            jsr     begin
            bra     gameContd 

cmpSetup    
            jsr     computerSetup
            addq.b  #1,gameMode  
            bra     gameContd
            
playMode    
            tst.b   playerTurn
            beq     cmpTurn
            jsr     playRound
            bra     gameContd
cmpTurn     
            jsr     computerTurn
            bra     gameContd

gameOver
            cmp.b   #1,winner
            beq     .playerWon
            lea     cmpWinMsg,a1
            bra     .showMessage
.playerWon
            lea     plyrWinMsg,a1 
.showMessage      
            move.w  #300,d1                
            move.w  #250,d2             
            move.l  #95,d0 
            trap    #15                 ;print  message on screen
            bra     gameContd

*-----------------------------------------------------------------------------

* Setup phase - placing ships

setup       
            link    a0,#0
            lea     plyrShips,a3        ; select ship data from array
            move.l  selected,d1
            mulu    #4,d1
            adda.l  d1,a3               ; increment array to get selected ship data
            and.l   #$FFF0FFFF,(a3)     ; clear colour attribute
            add.l   #$00050000,(a3)     ; set colour 
            
            move.l  (a3),d2             ; move ship data into d2
            or.l    #$80000000,d2       ; set the show bit 
            move.l  d2,(a3)
            and.l   #$0000000F,d2       ; get length attribute
            subq.l  #1,d2       
            move.l  d2,(a0)             ; store length attribute in variable              

            move.l  (a3),d3             ; move ship data into d3
            and.l   #$00001000,d3       ; get v/h bit 
            move.l  d3,-(SP)            ; push v/h bit onto stack      
            move.l  (a0),-(SP)          ; pass ship array index as argument            
            jsr     userInput           ; get user input
            move.l  (SP)+,d2            ; put return value into d2
            move.l  (SP)+,d3            ; pop v/h bit into d3
            lea     cursorPos,a4        ; get the cursor position
            cmp     #'r',d2             ; if return value equals r then rotate ship
            bne     noRotate            
            
            move.l  (a0),d4             ; move index into d4
            add.b   (a4),d4             ; add x pos to index
            sub.l   #9,d4               ; subtract boundary value from result
            ble     noCrsrLft           ; 
            sub.b   d4,(a4)             ; take difference from cursor x pos   
noCrsrLft   
            move.l  (a0),d4             
            add.b   1(a4),d4                
            sub.l   #9,d4
            ble     noCrsrUp   
            sub.b   d4,1(a4) 
noCrsrUp    
            add.l   #$FFFFEFFF,d3       
            not.l   d3                  ; flip v/h bit
noRotate    
            cmp     #'e',d2             ; if e not pressed then skip ship increment
            bne     noShipInc
            tst.b   d5                  ; collision flag
            bne     noShipInc
            subq.l  #1,selected         ; decrement ship index
            bpl     noRsetIndex  
            move.l  #4,selected         ; if ship index is minus then set back to 4
            lea     gameMode,a2         ; load game mode
            addq.b  #1,(a2)             ; increment game mode to play mode
noRsetIndex     
            and.l   #$FFF0FFFF,(a3)     ; clear colour attribute of prev ship
            add.l   #$00020000,(a3)     ; set colour 
            lea     plyrShips,a3        ; load ships
            move.l  selected,d1         
            mulu    #4,d1           
            adda.l  d1,a3               ; select the next ship
            and.l   #$FFF0FFFF,(a3)     ; clear colour attribute of next ship
            add.l   #$00050000,(a3)     ; set colour 
            move.l  (a3),d1             ; ship data into d1
            and.l   #$00000F00,d1       ; get x pos of ship
            lsr.l   #8,d1
            move.b  d1,(a4)             ; set cursor x pos to ship x pos
            move.l  (a3),d1             ; ship data into d1
            and.l   #$000000F0,d1       ; get y pos of ship
            lsr.l   #4,d1
            move.b  d1,1(a4)            ; set cursor y pos to ship y pos          
            bra     setupContinued   
noShipInc
            clr     d1  
            move.b  (a4),d1             ; move  x value into d1
            lsl.l   #4,d1               ; shift left to make room for y
            add.b   1(a4),d1            ; add y value to d1
            lsl.l   #4,d1               ; shift left
            add.l   d3,d1
            and.l   #$FFFF000F,(a3)     ; clear x,y old data
            add.l   d1,(a3)             ; add new x,y data
setupContinued
            move.l  selected,-(SP)      ; selected ship
            move.l  #0,-(SP)            ; computer player flag
            pea     plyrShips   
            pea     plyrGrid     
            jsr     clearGrd           
            jsr     shipsOnGrd
            adda    #$10,a7              
            unlk    a0
            rts
 
*------------------------------------------------------------------------   
     
begin   
            lea     beginMsg,a1        
            move.w  #300,d1                
            move.w  #250,d2             
            move.l  #95,d0
            trap    #15                 ; print begin message on screen
            move.l  #0,-(SP)            ; make room on stack for return value
            jsr     userInput
            move.l  (SP)+,d1
            cmp     #'y',d1             
            beq     beginGame
            cmp     #'n',d1
            beq     backToSetup
            rts
backToSetup 
            move.b  #0,gameMode         ; set game mode back to 0
            move.w  #$FF00,d1           ; clear screen
            move.l  #11,d0
            trap    #15
            rts
beginGame   
            addq.b  #1,gameMode         ; increment game mode
            move.w  #$FF00,d1           ; clear screen
            move.l  #11,d0
            trap    #15
            lea     startMsg,a1
            move.w  #300,d1
            move.w  #250,d2
            move.l  #95,d0
            trap    #15
            rts              


*------------------------------------------------------------------------


computerSetup
            
    * load selected ship
loadNextShip
            link    a0,#0
            lea     cmpShips,a3         ; select ship data from array
            move.l  selected,d1
            mulu    #4,d1
            adda.l  d1,a3               ; increment array to get selected ship data
            or.l    #$C0000000,(a3)
            
    * get random x y pos
            move.l  (a3),d4             ; move ship data into d2
            and.l   #$0000000F,d4       ; get length attribute
            subq.l  #1,d4  
            clr     d2
            clr     d3        
            move.w  #10,d2              ; load grid size
            sub.w   d4,d2               ; subtract ship length from grid size
            move.w  #0,d3
            jsr     getRandom
            clr     d4
            move.w  d1,d4               ; move result into d4
            swap    d4
            move.w  #10,d2              ; d4 contains y value in high word and x in low word
            move.w  #0,d3
            jsr     getRandom
            move.w  d1,d4
            and.l   #$FFFF0FFF,(a3)     ; clear horizontal bit
            
    * randomly set vertical/horizontal        
   
            move.w  #$FFFF,d2           ; any number from 0 - 65535
            move.w  #0,d3
            jsr     getRandom
            move.l  (a3),d2             ; move ship data into d2
            cmp.l   #$7FFF,d1           ; compare result with 32767
            bgt     notHorizontal                
            or.l    #$00001000,d2       ; set horizontal bit
            swap    d4                  ; swap x y values in d4                      
notHorizontal            
            clr     d1
            add.w   d4,d1               ; load x value
            lsl.w   #4,d1               ; shift x value 
            swap    d4
            add.w   d4,d1
            lsl.w   #4,d1
            and.l   #$FFFFF00F,d2       ; clear old x y value
            add.l   d1,d2
            move.l  d2,(a3)             ; store ship data
            
            move.l  selected,-(SP)      ; selected ship
            move.l  #1,-(SP)            ; computer player flag
            pea     cmpShips   
            pea     cmpGrid     
            jsr     clearGrd
            jsr     shipsOnGrd
            adda    #$10,a7
            tst.b   d5                  ; collision flag
            bne     placeShipAgain
            subq.l  #1,selected
placeShipAgain
            unlk    a0
            tst.l   selected
            
            bpl     loadNextShip
            
            move.l  #0,-(SP)            
            move.l  #0,-(SP)            
            pea     cmpShips   
            pea     cmpGrid     
            jsr     clearGrd
            jsr     shipsOnGrd
            adda    #$10,a7

            rts



*------------------------------------------------------------------------

playRound   
            move.l  #0,-(SP)            ; make room on stack for return value
            jsr     userInput           ; get user input
            move.l  (SP)+,d1            ; put return value into d1

            cmp.b   #'f',d1             ; if key f is pressed then fire shot
            bne     continueRound       
            lea     cursorPos,a3        ; load cursor position
            clr     d2                  ; clear registers
            clr     d3
            move.b  (a1),d2             ; move x into d2
            move.b  (1,a1),d3           ; move y into d3
            move.l  #0,-(SP)            ; push computer player flag onto stack
            move.w  d3,-(SP)            ; push y value 
            move.w  d2,-(SP)            ; push x value
            jsr     shootTile           ; call shoot tile subroutine
            move.l  (SP)+,d1            ; get return value 
            adda    #$4,a7              ; increment stack pointer

            cmp.w   #$FFFE,d1           ; if return value is -2 then shot was on invalid tile
            beq     invalidTile
            cmp.w   #$FFFF,d1           ; if return value is -1 then shot was a miss
            beq     missedShot

            lea     cmpShips,a2         ; else return value is a ship id
            mulu    #4,d1
            adda.l  d1,a2
            move.l  a2,-(SP)            ; push ship address onto stack
            clr     d2
            move.b  (a3),d2
            swap    d2
            move.b  (1,a3),d2
            move.l  d2,-(SP)
            jsr     shipIsHit
            adda    #$8,a7

missedShot

            * next player
            not.b  playerTurn
invalidTile

            * repeat for same player
continueRound
            rts


*------------------------------------------------------------------------


shipIsHit
            link    a0,#0
            move.l  12(a0),a2           ; ship address
            move.l  8(a0),d3            ; x y coord
            move.l  (a2),d1             ; load ship data into d1
            move.l  d1,d2

            and.l   #$00000F00,d1
            lsr.l   #8,d1               ; shift x value into lsb
            and.l   #$000000F0,d2
            lsr.l   #4,d2               ; shift y value into lsb
            add     d2,d1               ; ship x + y value
            clr     d2  
            move.w  d3,d2               ; cursor x value
            swap    d3
            add.b   d3,d2               ; cursor x + y value
            sub     d1,d2               ; subtract ship x y from cursor x y to leave position ship is hit

            move.l  #1,d1               ; load bit into d1
            lsl.l   d2,d1               ; shift by value of the hit position
            lsl.l   #4,d1               ; shift further 4 bits
            swap    d1
            or.l    d1,(a2)             ; add the hit position to the ship data

            move.l  (a2),d1             ; move ship data into d1

            swap    d1
            lsr.l   #$4,d1

            clr.l     d3
            clr.l     d4
            for d2 = #1 to #5 do
                asr.l   #1,d1
                addx    d4,d3
            endf

            move.l  (a2),d1             ; move ship data into d1
            and.l   #$F,d1              ; get ship lives
            sub.l   d3,d1

            and.l   #$0000000F,d1
            move.l  d1,8(a0)            ; return value
            unlk    a0
            rts



*------------------------------------------------------------------------

userInput    
            link    a0,#0
            move.l  #9,d4               ; cursor limit d4
            sub.l   8(a0),d4            ; subtract ship size 
            lea     cursorPos,a1
            clr     d1
            clr     d2
            clr     d3
            move.b  (a1),d2             ; cursor x pos in d2
            move.b  (1,a1),d3           ; cursor y pos in d3
            move.b  #5,d0               ; listen for key press
            trap    #15
* convert to lower case if upper case
            cmp.b   #'A',d1             
            blt     notUpperCase
            cmp.b   #'Z',d1
            bgt     notUpperCase
            addi.b  #$20,d1
notUpperCase              
            cmp.b   #'w',d1
            beq     cursorUp  
            cmp.b   #'s',d1
            beq     cursorDown 
            cmp.b   #'a',d1
            beq     cursorLeft 
            cmp.b   #'d',d1
            beq     cursorRight           
* store cursor values *            
inptEnd     move.b  d2,(a1)
            move.b  d3,(1,a1)
            move.l  d1,8(a0)
            unlk    a0
            rts         


* change cursor value within limits *
cursorUp    cmp.b   #0,d3  
            ble     inptEnd
            addi    #-1,d3
            bra     inptEnd
cursorDown  tst.l   12(a0)              ; test v/h/ bit
            beq     dwnBndryChk     
            move.l  #9,d4               ; if ship is horizontal set downwards boundary to 9
dwnBndryChk cmp.b   d4,d3  
            bge     inptEnd
            addi    #1,d3
            bra     inptEnd
cursorLeft  cmp.b   #0,d2  
            ble     inptEnd
            addi    #-1,d2
            bra     inptEnd
cursorRight tst.l   12(a0)              ; test v/h/ bit
            bne     rhtBndryChk     
            move.l  #9,d4               ; if ship is vertical set right boundary to 9
rhtBndryChk cmp.b   d4,d2  
            bge     inptEnd
            addi    #1,d2
            bra     inptEnd
            
           
*-------------------------------------------------------------------------------------


** refresh the grid *

gridRfrsh   
            move.l  d5,-(SP)            ; push collision flag data onto stack
            lea     plyrGrid,a2         ; load player grid
            move.l  #250,-(SP)          ; push y pos of grid on stack
            jsr     drwGrid         
            adda    #$4,a7              ; increment stack pointer
            
            lea     cmpGrid,a2          ; load computer player grid
            move.l  #20,-(a7)           ; push y pos of grid onto stack
            jsr     drwGrid
            adda    #$4,a7              ; increment stack pointer
            move.l  (SP)+,d5            ; pop collison flag back in d5
 
*cursor crosshair if in play mode
            cmp.b   #3,gameMode
            bne     noCursorTarget
            lea     cursorPos,a3
            move.l  #20,-(SP)
            move.b  (a3),-(SP)
            move.b  (1,a3),-(SP)
            jsr     drawCursorTarget
            adda    #$8,a7            
noCursorTarget
            rts
 
*----------------------------------------------------------------------------------

* computer turn


computerTurn
            link    a0,#-8
repeatTurn
            move.l  #11,-(SP)           ; hit array length
            pea     hitArray            ; hit array address
            jsr     arrayLength         ; get number indexes used in array
            move.l  (SP)+,d1            ; return value
            adda    #$4,a7              ; increment stack pointer

            cmp.l   #1,d1               ; test array length against 1
            bmi     hitArrayEmpty       ; if negative then there are no hits in array
            beq     onePrevHit          ; if equal then one hit in array
            bra     multipleHits

hitArrayEmpty
            move.l  #11,-(SP)           ; hit array length
            pea     holdArray           ; hit array address
            jsr     arrayLength         ; get number indexes used in array
            move.l  (SP)+,d1            ; return value
            adda    #$4,a7              ; increment stack pointer
            tst.l   d1                  ; test array length
            beq     noPreviousHits      ; if 0 no hits in array
            move.l  #11,-(SP)           ; hold array length
            pea     holdArray  
            jsr     popArray    
            move.l  (SP)+,d1    
            adda    #$4,a7
            lea     hitArray,a1
            move.l  d1,(a1)
            bra     onePrevHit


multipleHits   
            move.l  #$000F000F,d2       ; min coord
            clr.l   d4

            lea     hitArray,a1         ; start address
            move.l  a1,a2
            move.l  #10,d3
            mulu    #4,d3
            adda    d3,a2               ; end address
            clr     d3

* get min and max coords from hit array     
            for.l   a1 = a1 to a2 by #$4 do
                move.l  (a1),d4

                cmp.l   #$FFFFFFFF,d4
                beq     continueLoop

                if.l d4 <lt> d2 then
                    move.l  d4,d2
                endi

                if.l d4 <gt> d3 then
                    move.l  d4,d3
                endi

continueLoop
            endf

            lea     posShots,a3
            cmp.w   d2,d3
            beq     targetIsHorizontal
* target vertical

            subq.w  #1,d2
            bmi     checkLowerTile
            
            move.l  d2,-(SP)
            jsr     getTileValue
            move.l  (SP)+,d1
            and.b   #$08,d1             ; get hit flag from tile value
            bne     checkLowerTile
            move.l  d2,(a3)+            ; add coord to possible shots
checkLowerTile
            addq    #1,d3
            cmp.w   #9,d3
            bgt     randomPosShot      
            move.l  d3,-(SP)
            jsr     getTileValue
            move.l  (SP)+,d1
            and.b   #$08,d1             ; get hit flag from tile value
            bne     randomPosShot
            move.l  d3,(a3)+            ; add coord to possible shots
            bra     randomPosShot


targetIsHorizontal

            lea     posShots,a3
            swap    d2                  ; put x into low word
            subq.w  #1,d2               ; tile to left
            bmi     checkRightTile      ; if minus then not on grid so skip
            swap    d2                  ; swap back
            move.l  d2,-(SP)            
            jsr     getTileValue        ; check if tile already hit
            move.l  (SP)+,d1
            and.b   #$08,d1             ; get hit flag from tile value
            bne     checkRightTile      ; if already hit then skip
            move.l  d2,(a3)+            ; else add coord to possible shots
checkRightTile
            swap    d3                  ; put x into low word
            addq    #1,d3
            cmp.w   #9,d3
            bgt     randomPosShot
            swap    d3
            move.l  d3,-(SP)
            jsr     getTileValue
            move.l  (SP)+,d1
            and.b   #$08,d1             ; get hit flag from tile value
            bne     randomPosShot
            move.l  d3,(a3)+            ; add coord to possible shots
            bra     randomPosShot


* one previous hit is in hit array
onePrevHit   
            lea     hitArray,a1
            move.l  #11,-(SP)
            move.l  a1,-(SP)
            jsr     popArray
            move.l  (SP)+,(a1)
            adda    #4,a7
            lea     posShots,a3
            move.l  (a1),d1             ; load x y of previous shot
            swap    d1
            addq.w  #1,d1               ; increase x value (tile above)
            cmp.w   #9,d1
            
            bgt     tileLeft           ; if out of bounds go to next tile
            swap    d1
            move.l  d1,-(SP)
            jsr     getTileValue
            move.l  (SP)+,d2
            and.b   #$08,d2             ; get hit flag from tile value
            bne     tileLeft
            move.l  d1,(a3)+            ; add coord to possible shots
tileLeft
            move.l  (a1),d1
            swap    d1
            subq.w  #1,d1
            cmp.w   #0,d1
            
            blt     tileBelow
            swap    d1
            move.l  d1,-(SP)
            jsr     getTileValue
            move.l  (SP)+,d2
            and.b   #$08,d2             ; get hit flag from tile value
            bne     tileBelow
            move.l  d1,(a3)+            ; add coord to possible shots
tileBelow
            move.l  (a1),d1
            addq.w  #1,d1               ; add to get right tile
            cmp.w   #9,d1
            bgt     tileAbove
            move.l  d1,-(SP)
            jsr     getTileValue
            move.l  (SP)+,d2
            and.b   #$08,d2             ; get hit flag from tile value
            bne     tileAbove
            move.l  d1,(a3)+            ; add coord to possible shots
tileAbove
            subq.w  #2,d1               ; add to get right tile
            cmp.w   #0,d1
            blt     randomPosShot
            move.l  d1,-(SP)
            jsr     getTileValue
            move.l  (SP)+,d2
            and.b   #$08,d2             ; get hit flag from tile value
            bne     randomPosShot
            move.l  d1,(a3)+            ; add coord to possible shots
            bra     randomPosShot


* hit array is empty so pick a coord at random
noPreviousHits
            move.l  #10,d2
            move.l  #0,d3
            jsr     getRandom
            move.l  d1,d4
            jsr     getRandom
            swap    d1
            move.w  d4,d1

* tile already hit
            move.l  d1,-(SP)
            jsr     getTileValue
            move.l  (SP)+,d2
            and     #$F,d2
            cmp.b   #8,d2
            bge     noPreviousHits

* get length of smallest remaining ship
            lea     remShips,a2
            move.l  a2,-8(a0)
            add.l   #4,-8(a0)
            clr     d2
            move.b  #$7F,d2
            for.l a2 = a2 to -8(a0) do
                if.b (a2) <ne> #$FF then
                    if.b (a2) <lt> d2 then
                        move.b  (a2),d2
                    endi
                endi
            endf

* check vertical space
            move.l  d1,d3               ; move coords into d3
            clr     d4                  ; count spaces in d4
            clr     d5

            * check below
            while.b d5 <lt> #$8 do
                addq    #1,d4           ; increment counter
                cmp.b   d2,d4           ; compare counter with ship length
                bge     enoughRoomForShip
                addq.l  #1,d3           ; increment y value
                if.w d3 <lt> #10 then
                    move.l  d3,-(SP)
                    jsr     getTileValue
                    move.l  (SP)+,d5
                    and     #$F,d5
                else
                    move.b  #$7F,d5
                endi
            endw
    
            * check above
            subq    #1,d4               ; decrement counter as centre tile is already counted
            move.l  d1,d3               ; put centre coord back in d3
            clr     d5

            while.b d5 <lt> #$8 do
                addq    #1,d4           ; increment counter
                cmp.b   d2,d4               ; compare counter with ship length
                bge     enoughRoomForShip
                subq.l  #1,d3
                if.w d3 <gt> #0 then
                    move.l  d3,-(SP)
                    jsr     getTileValue
                    move.l  (SP)+,d5
                    and     #$F,d5
                else
                    move.b  #$7F,d5
                endi          
            endw

* check horizontal
            * check right
            move.l  d1,d3               ; move coords into d3
            clr     d4                  ; count spaces in d4
            clr     d5

            while.b d5 <lt> #$8 do
                addq    #1,d4           ; increment counter
                cmp.b   d2,d4           ; compare counter with ship length
                bge     enoughRoomForShip
                swap    d3
                addq.l  #1,d3           ; increment x value
                if.w d3 <lt> #10 then
                    swap    d3
                    move.l  d3,-(SP)
                    jsr     getTileValue
                    move.l  (SP)+,d5
                    and     #$F,d5
                else
                    move.b  #$7F,d5
                endi
            endw

            * check below
            subq    #1,d4               ; decrement counter as centre tile is already counted
            move.l  d1,d3               ; put centre coord back in d3
            clr     d5

            while.b d5 <lt> #$8 do
                addq    #1,d4           ; increment counter                
                cmp.b   d2,d4               ; compare counter with ship length
                bge     enoughRoomForShip
                swap    d3
                subq.l  #1,d3           ; decrement x value
                if.w d3 <gt> #0 then
                    swap    d3
                    move.l  d3,-(SP)
                    jsr     getTileValue
                    move.l  (SP)+,d5
                    and     #$F,d5
                else
                    move.b  #$7F,d5
                endi
            endw

            bra     noPreviousHits

enoughRoomForShip
            move.l  d1,-4(a0)           ; move xy value into local variable
            bra     takeShot


* pick a shot at random from possible shots array
randomPosShot
            move.l  #4,-(SP)            ; possible shot array length
            pea     posShots            ; possible shot array address
            jsr     arrayLength         ; get number indexes used in array
            move.l  (SP)+,d2            ; return value
            adda    #$4,a7              ; increment stack pointer
            tst.l   d2
            bne     shotsAvailable

* if there are no possible shots but the hit array is not empty then multiple ships must be in the hit array
* move all coords from hit array into hold array then move one back into hit array and start the target process from that    
            move.l  #11,-(SP)           
            pea     hitArray            
            pea     holdArray           
            jsr     copyArray         
            adda    #$C,a7
            move.l  #11,-(SP)          
            pea     hitArray  
            jsr     clearArray
            adda    #$8,a7
            move.l  #11,-(SP)          
            pea     holdArray  
            jsr     popArray    
            move.l  (SP)+,d1    
            adda    #$4,a7
            lea     hitArray,a1
            move.l  d1,(a1)
            bra     onePrevHit      

shotsAvailable
            move.l  #0,d3
            jsr     getRandom
            lea     posShots,a1
            mulu    #4,d1
            adda    d1,a1
            move.l  (a1),-4(a0)         ; move xy value into local variable           
            move.l  #4,-(SP)            ; array length
            pea     posShots            
            jsr     clearArray
            adda    #$8,a7
            bra     takeShot

* take shot at selected coord
takeShot
            move.l  #1,-(SP)
            move.l  -4(a0),-(SP)
            jsr     shootTile
            move.l  (SP)+,d1            ; get return value 
            adda    #$4,a7              ; increment stack pointer

            cmp.w   #$FFFE,d1           ; if return value is -2 then shot was on invalid tile
            beq     repeatTurn          ; if tile is invalid then repeat turn
            cmp.w   #$FFFF,d1           ; if return value is -1 then shot was a miss
            beq     endOfCmpTurn

            lea     plyrShips,a2        ; else return value is a ship id
            mulu    #4,d1
            adda.l  d1,a2
            move.l  a2,-(SP)            ; push ship address onto stack
            move.l  -4(a0),-(SP)        ; push x y 
            jsr     shipIsHit
            move.l  (SP)+,d2            ; ship lives
            adda    #$4,a7

            move.l  -4(a0),-(SP)
            pea     hitArray
            jsr     addToArray
            adda    #$8,a7

            tst.l   d2
            beq     shipIsDestroyed
            bra     endOfCmpTurn

shipIsDestroyed

            move.l (a2),d3              ; ship data into d3-d5
            move.l (a2),d4              
            move.l (a2),d5              

            and.l   #$00000F00,d4
            lsr     #8,d4
            swap    d4
            and.l   #$000000F0,d5
            lsr     #4,d5
            add     d5,d4               ; d4 has x y
            move.l  d3,d5
            and.l   #$0000000F,d5       ; d5 has length
            and.l   #$00001000,d3       ; vertical flag


            move.b  d5,-(SP)
            move.l  #5,-(SP)
            pea     remShips
            jsr     remByteFromArray
            adda    #10,a7
            move.l  #5,-(SP)
            pea     remShips
            jsr     byteArrayLength
            move.l  (SP)+,d1
            adda    #4,a7
            tst.l   d1
            beq     cmpWin
            
            if.l d3 <eq> #0 then

                for.l d5 = d5 downto #1 do
                    move.l  d4,-(SP)
                    move.l  #$11,-(SP)
                    pea     hitArray
                    jsr     remArrayData
                    add.l   #$00000001,d4
                endf

            else

                for.l d5 = d5 downto #1 do
                    move.l  d4,-(SP)
                    move.l  #$11,-(SP)
                    pea     hitArray
                    jsr     remArrayData
                    add.l   #$00010000,d4
                endf
            endi    

    * check if array is empty

    * if check remaining coords against eachother

    * put odd coords into second array

    * continue


endOfCmpTurn
            not.b   playerTurn
            unlk    a0
            rts

cmpWin
            move.b  #2,winner
            move.b  #4,gameMode
            bra     endOfCmpTurn

*----------------------------------------------------------------------------------

* returns count of used locations in array not the total length

* parameters: array address, array total length (long)
* return used memory slots (long)


arrayLength
            link    a0,#-8
            move.l  8(a0),a1        ; array address parameter
            move.l  #0,-4(a0)       ; index counter local variable
.nextIndex   
            subq.l  #1,12(a0)       ; decrement array size counter
            bmi     .endOfArray
            move.l  (a1)+,d2        ; move array value into d1
            cmp.l   #$FFFFFFFF,d2   ; check if d2 is empty
            beq     .nextIndex       ; if equal to size then reached end of array
            addq.l  #1,-4(a0)       ; increment memory counter
            bra     .nextIndex
.endOfArray
            move.l  -4(a0),8(a0)    ; return the memory counter value
            unlk    a0
            rts

*----------------------------------------------------------------------------------

* returns count of used locations in array not the total length

* parameters: array address, array total length (long)
* return used memory slots (long)


byteArrayLength
            link    a0,#-8
            move.l  8(a0),a1        ; array address parameter
            move.l  #0,-4(a0)       ; index counter local variable
.nextIndex   
            subq.l  #1,12(a0)       ; decrement array size counter
            bmi     .endOfArray
            move.b  (a1)+,d2        ; move array value into d1
            cmp.b   #$FF,d2         ; check if d2 is empty
            beq     .nextIndex      ; if equal to size then reached end of array
            addq.l  #1,-4(a0)       ; increment memory counter
            bra     .nextIndex
.endOfArray
            move.l  -4(a0),8(a0)    ; return the memory counter value
            unlk    a0
            rts



*----------------------------------------------------------------------------------

* inserts a long in the next available location in array

* params: array address, data (long)


addToArray
            link    a0,#0
            move.l  8(a0),a1        ; array address parameter
.nextIndex
            cmp.l   #$FFFFFFFF,(a1)
            beq     .addData
            add     #4,a1
            bra     .nextIndex
.addData
            move.l  12(a0),(a1)
            unlk    a0
            rts


*----------------------------------------------------------------------------------

* inserts a long in the next available location in array

* params: array address, data (long)


addByteToArray
            link    a0,#0
            move.l  8(a0),a1        ; array address parameter
.nextIndex
            cmp.b   #$FF,(a1)
            beq     .addData
            add     #1,a1
            bra     .nextIndex
.addData
            move.b  12(a0),(a1)
            unlk    a0
            rts


*----------------------------------------------------------------------------------

* clears an entire array

* params: array address, array length

clearArray
            link    a0,#0
            move.l  8(a0),a1        ; array address parameter

            for.l   d1 = #1 TO 12(a0) DO                
                move.l  #$FFFFFFFF,(a1)+
            endf

            unlk    a0
            rts


*----------------------------------------------------------------------------------

* params: array address, array length, data to remove (longs)

remArrayData
            link    a0,#0
            move.l  8(a0),a1        ; array address parameter
            move.l  16(a0),d2
            clr     d1              ; counter
.loop
            cmp.l   (a1),d2
            beq     .removeData
            addq.l  #1,d1
            adda    #$4,a1                  * increment array
            cmp.l   12(a0),d1
            bge     .end
            bra     .loop
.removeData
            move.l  #$FFFFFFFF,(a1)
.end
            unlk    a0
            rts

*----------------------------------------------------------------------------------

* params: array address, array length, data to remove (byte)

remByteFromArray
            link    a0,#0
            move.l  8(a0),a1        ; array address parameter
            move.b  16(a0),d2

            clr     d1              ; counter
.loop
            cmp.b   (a1),d2
            beq     .removeData
            addq.l  #1,d1
            adda    #1,a1           ; increment array
            cmp.l   12(a0),d1
            bge     .end
            bra     .loop
.removeData
            move.b  #$FF,(a1)
.end
            unlk    a0
            rts
*----------------------------------------------------------------------------------

* removes first item from array and returns it

* params: array address, array length

popArray
            link    a0,#0
            move.l  8(a0),a1        ; array address parameter

            for.l   d1 = #1 to 12(a0) do
                if.l (a1) <ne> #$FFFFFFFF then      ; first non empty slot     
                    move.l  (a1),8(a0)              ; move to return value
                    move.l  #$FFFFFFFF,(a1)         ; remove from array
                    bra     break           
                endi
                adda    #$4,a1                  * increment array
            endf
            break:
            unlk    a0
            rts


*----------------------------------------------------------------------------------

* copy one array to another

* params: copy to address, copy from address, array length

copyArray
            link    a0,#0
            move.l  12(a0),a1        ; copy from array address 
            move.l  8(a0),a2        ; copy to array address 

            for.l   d1 = #1 to 16(a0) do
                move.l  (a1)+,(a2)+              
            endf

            unlk    a0
            rts


*----------------------------------------------------------------------------------
    
    INCLUDE     Random.X68
    INCLUDE     Grid.X68
    
cursorPos   dc.b    0,0

gameMode    dc.b    0           ; 0: setup, 1: play mode


* Ship data
*   0|0|0|0|0|0|0|H|H|H|H|H|C|C|C|C|0|0|0|V|X|X|X|X|Y|Y|Y|Y|L|L|L|L
*
*   S: Show ship flag
*   0: Unused
*   H: Ship hit location
*   C: Colour of ship
*   V: Vertical flag
*   X: X pos
*   Y: Y pos
*   L: Ship length/lives

plyrShips   dc.l    $00020002,$00020003,$00020003,$00020004,$00020005
cmpShips    dc.l    $00000002,$00000103,$00000203,$00000304,$00000405
selected    dc.l    $00000004

remShips    dc.b    $2,$3,$3,$4,$5
cmpSunk     ds.b    5
plyrSunk    ds.b    5


hitArray    ds.l    11
holdArray   ds.l    11
posShots    ds.l    4

playerTurn  dc.b    0

winner      dc.b    0

beginMsg    dc.b    'Press "y" to begin or "n" to move ships',0
startMsg    dc.b    'Start',0
plyrWinMsg  dc.b    'Player Won!',0
cmpWinMsg   dc.b    'Computer Won!',0
    
    END    START        ; last line of source



*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
