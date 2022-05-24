  

* Game loop

gameLoop    cmp.b   #0,gameMode       
            beq     setupMode
            cmp.b   #1,gameMode       
            beq     beginMessage
            cmp.b   #2,gameMode
            beq     cmpSetup
            cmp.b   #3,gameMode
            beq     playMode    
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
            jsr     playRound
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
            or.l    #$10000000,d2       ; set the show bit 
            move.l  d2,(a3)
            and.l   #$0000000F,d2       ; get length attribute         
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
            move.l  #0,-(SP)            ; computer player flag
            pea     plyrShips   
            pea     plyrGrid     
            jsr     clearGrd           
            jsr     shipsOnGrd
            adda    #$8,a7              
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
            link    a0,#0
    * load selected ship
loadNextShip  
            lea     cmpShips,a3         ; select ship data from array
            move.l  selected,d1
            mulu    #4,d1
            adda.l  d1,a3               ; increment array to get selected ship data
            or.l    #$10000000,(a3)
            
    * get random x y pos
            move.l  (a3),d4             ; move ship data into d2
            and.l   #$0000000F,d4       ; get length attribute
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
            
            move.l  #1,-(SP)            ; computer player flag
            pea     cmpShips   
            pea     cmpGrid     
            jsr     clearGrd
            jsr     shipsOnGrd
            adda    #$8,a7
            tst.b   d5                  ; collision flag
            bne     placeShipAgain
            subq.l  #1,selected
placeShipAgain
            tst.l   selected
            bpl     loadNextShip
            unlk    a0
            rts



*------------------------------------------------------------------------

playRound   
            move.l  #0,-(SP)            ; make room on stack for return value
            jsr     userInput
            move.l  (SP)+,d1
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

    
    INCLUDE     Random.X68
    INCLUDE     Grid.X68
    
cursorPos   dc.b    0,0

gameMode    dc.b    0           ; 0: setup, 1: play mode


* Ship data
*   S|0|0|0|0|0|0|0|0|0|0|0|C|C|C|C|0|0|0|V|X|X|X|X|Y|Y|Y|Y|L|L|L|L
*
*   S: Show ship flag
*   0: Unused
*   C: Colour of ship
*   V: Vertical flag
*   X: X pos
*   Y: Y pos
*   L: Ship length/lives

plyrShips   dc.l    $00020001,$00020001,$00020002,$00020003,$00020004
cmpShips    dc.l    $00020001,$00020101,$00020202,$00020303,$00020404
selected    dc.l    $00000004

*   Tile data is stored as follows
*   
*   Data: C|N
*       
*       C: Colour
*       N: Ship ID


beginMsg    dc.b    'Press "y" to begin or "n" to move ships',0
startMsg    dc.b    'Start',0
    
    END    START        ; last line of source



*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
