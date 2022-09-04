
drawBackground
            link    a0,#0
            move.b  borderWidth,d1
            move.w  #93,d0
            trap    #15
            move.l  borderColour,d1
            move.w  #80,d0
            trap    #15
            move.l  bgColour,d1
            move.w  #81,d0
            trap    #15
            lea     bgDim,a1
            lea     bgPos,a2
            move.w  (a2)+,d1
            move.w  (a2),d2
            move.w  d1,d3
            move.w  d2,d4
            add.w   (a1)+,d3
            add.w   (a1),d4 
            move.w  #87,d0
            trap    #15
            move.b  #1,d1
            move.w  #93,d0
            trap    #15
            move.l  #WHITE,d1
            move.w  #80,d0
            trap    #15
            move.l  #BLACK,d1
            move.w  #81,d0
            trap    #15
            unlk    a0
            rts



*---------------------------------------------------------------------------

* x pos, y pos, message id


drawTextBox
            link    a0,#0

            move.l  #WHITE,d1
            move.w  #80,d0
            trap    #15
            move.l  #$001F1F1F,d1
            move.w  #81,d0
            trap    #15

            move.w  8(a0),d1
            move.w  10(a0),d2
            lea     txtBoxDim,a1
            move.w  d1,d3
            move.w  d2,d4
            add.w   (a1)+,d3
            add.w   (a1),d4 
            move.w  #87,d0
            trap    #15

            move    d2,-(SP)        ; y pos
            move    d1,-(SP)        ; x pos
            move    12(a0),-(SP)        ; message id
            jsr     writeText
            adda    #6,SP

            unlk    a0
            rts



*---------------------------------------------------------------------------

writeText
            link    a0,#-36

            movem.l d1-d5/a1-a3,-36(a0) ; back up all registers used

            clr     d3
            clr     d4
            clr     d5
            lea     msgLen,a2           ; load array containing message lengths          
            move.l  #0,-4(a0)           ; set local counter variable to 0
            move    8(a0),d5            ; move the message index into d5
            tst.w   d5                  ; if index is zero then skip ahead
            beq     .cont

.accumulateValue
            add.b   (a2)+,d3            ; d3 is the first message index so lengths of previous messages are accumulated
            addq.l  #1,-4(a0)           ; increment counter
            cmp.l   -4(a0),d5           ; compare counter to message index
            beq     .cont
            bra     .accumulateValue

.cont
            move.l  #0,-4(a0)           ; clear the counter
            move.b  (a2),d4             ; a2 is currently at the correct index so d4 will be the number of messages to print

            move    10(a0),d1           ; start x TODO
            move    12(a0),d2           ; start y TODO
            
            add     #MARGIN,d1
            add     #MARGIN,d2              ; margin

            lea     msg,a3              ; load array containing pointers to messages
            mulu    #4,d3               
            adda    d3,a3               ; increment the message pointer array to correct index
.writeLine
            movea.l (a3),a1             ; load address of message
            move    #95,d0              ; print message
            trap    #15

            addq.l  #1,-4(a0)           ; increment counter
            cmp.l   -4(a0),d4           ; if counter equals the number of messages then break
            beq     .endWrite
            adda    #4,a3               ; increment the message pointer array
            add     #15,d2              ; increase y for new line
            bra     .writeLine        

.endWrite

            movem.l -36(a0),d1-d5/a1-a3 ; restore registers

            unlk    a0
            rts


*---------------------------------------------------------------------------

drawRemainingShips
            link    a0,#-24
            move.l  8(a0),a1        ; remaining ship array address
            move.l  12(a0),d1       ; x y coord of display
            move.w  d1,-6(a0)
            swap    d1
            move.w  d1,-8(a0)

            move.l  #3,-12(a0)       ; flag   
            move.l  #1,-16(a0)      ; ship counter
            sub.w   #30,-6(a0)
.nextShip
            addq.l  #1,-16(a0)
            cmp.l   #6,-16(a0)
            beq     .finished

            add.w   #30,-6(a0)

            move.l  d1,-20(a0)      ; back up d1
            move.l  #BLACK,d1        

            cmp.b   #$30,(a1)      ; if no ship then colour black
            blt     .shipPlaced
            move.l  #PLACED,d1
.shipPlaced
            cmp.b   #$FF,(a1)+
            bne     .shipDestroyed
            move.l  #SHIP,d1
.shipDestroyed          
            move    #81,d0          ; set fill color
            trap    #15             

            move.l  -20(a0),d1      ; restore d1

            subq.l  #1,-12(a0)            
            bne     .drawShip
            subq.l  #1,-16(a0)       
            bne     .drawShip

.drawShip
            move.l  -16(a0),-24(a0)          ; current ship
            
            move.w  -6(a0),d1   
            move.w  -6(a0),d3           ; x
            add     #tileSize,d3
            move.w  -8(a0),d4           ; y

.nextTile   
            move.w  d4,d2
            tst.l   16(a0)              ; flag for which way up to draw ships
            beq     .flipped
            add.w   #tileSize,d4
            bra     .continue
.flipped
            sub.w   #tileSize,d4
.continue
            move.w  #87,d0
            trap    #15

            subq.l  #1,-24(a0) 
            beq     .nextShip
            bra     .nextTile

.finished   
            move.l  #BLACK,d1    
            move    #81,d0          ; set fill color back to black
            trap    #15        
            unlk    a0
            rts


msgLen          dc.b    4,5,4,4,4,2
msg             dc.l    beginMsg1,beginMsg2,beginMsg3,beginMsg4,instrA1,instrA2,instrA3,instrA4,instrA5,instrB1,instrB2,instrB3,instrB4,cmpWin1,cmpWin2,cmpWin3,cmpWin4,plyrWin1,plyrWin2,plyrWin3,plyrWin4,start1,start2

beginMsg1       dc.b    '  Press "Y" to begin',0
beginMsg2       dc.b    '         or',0
beginMsg3       dc.b    ' Press "N" to go back',0
beginMsg4       dc.b    '   and move ships',0


instrA1         dc.b    '      CONTROLS',0
instrA2         dc.b    ' ',0
instrA3         dc.b    'W,A,S,D - move ship',0
instrA4         dc.b    '      R - rotate ship',0
instrA5         dc.b    '      E - place ship',0

instrB1         dc.b    '      CONTROLS',0
instrB2         dc.b    ' ',0
instrB3         dc.b    'W,A,S,D - move cursor',0
instrB4         dc.b    '      F - take shot',0

cmpWin1         dc.b    '    Computer Wins!',0
cmpWin2         dc.b    ' ',0
cmpWin3         dc.b    '    Press any key',0
cmpWin4         dc.b    '     to continue',0

plyrWin1        dc.b    '     Player Wins!',0
plyrWin2        dc.b    ' ',0
plyrWin3        dc.b    '    Press any key',0
plyrWin4        dc.b    '     to continue',0

start1        dc.b    ' ',0
start2        dc.b    ' Press any key to start ',0


borderWidth     dc.b    3
borderColour    dc.l    $00777777
bgColour        dc.l    $00000080
bgDim           dc.w    600,440
bgPos           dc.w    20,20
txtBoxDim       dc.w    190,90

MARGIN          EQU    10
