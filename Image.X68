
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
            move.l  #TEAL,d1
.shipPlaced
            cmp.b   #$FF,(a1)+
            bne     .shipDestroyed
            move.l  #MAROON,d1
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


borderWidth     dc.b    3
borderColour    dc.l    $00777777
bgColour        dc.l    $00337799
bgDim           dc.w    600,440
bgPos           dc.w    20,20