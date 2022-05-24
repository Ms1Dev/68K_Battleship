

* add ships to grid *
shipsOnGrd
            link    a0,#-4
            move.l  #0,-4(a0)           ; counter variable
            move.l  12(a0),a4
nxtShip     move.l  (a4),d1             ; put ship data into d1
            and.l   #$10000000,d1       ; bit mask to get show bit
            tst.l   d1                  ; test to see whether to show ship or not   
            beq     incShip             ; if not then skip
            move.l  selected,d1
            cmp.l   -4(a0),d1           ; compare counter to selected 
            beq     incShip             ; skip selected ship
            move.l  8(a0),-(SP)         ; push grid parameter
            move.l  (a4),-(SP)          ; push ship data onto stack
            jsr     addToGrid
            adda    #$4,a7   
            
                          
incShip     addq.l  #4,a4               ; increment array
            addq.l  #1,-4(a0)           ; decrement counter
            move.l  -4(a0),d1
            cmp     #5,d1           
            bne     nxtShip             ; if counter equals 5 then break
            move.l  12(a0),a4
            move.l  selected,d1
            mulu    #4,d1
            adda.l  d1,a4               ; selected ship data
            move.l  8(a0),-(SP)         ; push grid parameter
            move.l  (a4),-(SP)          ; push ship data onto stack
            jsr     addToGrid
            adda    #$4,a7
            tst.b   d5                  ; collision detected flag
            beq     noCollision
* if collision colour ship red and add to grid *
            and.l   #$FFF0FFFF,(a4)     ; clear colour attribute
            add.l   #$00040000,(a4)     ; set colour
            move.l  8(a0),-(SP)         ; push grid parameter
            move.l  (a4),-(SP)          ; push ship data onto stack
            jsr     addToGrid
            adda    #$4,a7
noCollision            
            unlk    a0
            rts

addToGrid   
            link    a0,#-16         
            move.l  8(a0),d1
            and.l   #$00000F00,d1       ; x pos bitmask
            lsr.l   #$8,d1              ; shift bits right
            move.l  d1,-4(a0)           ; store x value locally
            move.l  8(a0),d1            ; 
            and.l   #$000000F0,d1       ; y pos bitmask
            lsr.l   #$4,d1              ; shift bits right
            mulu    #10,d1              ; multiply by tiles in row
            move.l  d1,-8(a0)           ; store y value locally
            move.l  8(a0),d1    
            and.l   #$0000000F,d1       ; length bitmask
            addq.l  #1,d1
            move.l  d1,-12(a0)          ; length value
            move.l  8(a0),d1        
            and.l   #$00001000,d1       ; vertical/horizontal bitmask
            lsr.l   #$8,d1
            lsr.l   #$4,d1
            move.b  d1,-13(a0)          ; v/h flag (true = vertical)
            move.l  8(a0),d1
            swap    d1
            lsl.b   #4,d1
            move.b  d1,-14(a0)          ; value to set grid tile to
            
            move.l  12(a0),a2
   
            move.l  -4(a0),d1
            add.l   -8(a0),d1           ; add x and y values to get first tile                     
            adda.l  d1,a2               ; get array index
            clr     d5                  ; clear collision flag
setTile     
            tst.b   d5                  ; if d5 is set then skip
            bne     setValue            ; this avoids unsetting the collision flag on the next tile
            tst.b   (a2)                ; test the tile to see if anything already there
            sne     d5                  ; if tile not empty set d5
setValue
            move.b  -14(a0),(a2)        ; set value of tile
            tst.b   -13(a0)             ; test horizontal bit
            beq     incRow
            addq    #1,a2               ; increment the address counter by 1 (next column)
            bra     cntnue
incRow      adda    #10,a2              ; inc address by 10 (next row)
cntnue      subq.l  #1,-12(a0)          ; decrement length variable
            bne     setTile
            
            
            * move.l  -12(a0),d1          ; push length value on stack
            * move.w  d1,-(SP)
            
            * clr     d1
            * move.b  -13(a0),d1          ; push horizontal flag on stack
            * move.w  d1,-(SP)
            
            * move.l  -8(a0),d1           ; push y value on stack
            * move.w  d1,-(SP)
            * move.l  -4(a0),d1           ; push x value on stack
            * move.w  d1,-(SP)
            
            * jsr     addMargin
            * adda    #$8,a7                                    
            
            unlk    a0
            rts

*-----------------------------------------------------------------------------------



*-----------------------------------------------------------------------------------

* clears the player grid
clearGrd    
            link    a0,#0
            move.l  8(a0),a2            ; load the player grid
            move.l  #0,d1               ; load counter into d1
clrGrdLoop  
            movea.l a2,a3
            adda.l  d1,a3
            move.b  #0,(a3)             ; move 0 into grid
            addq.l  #1,d1               ; decrement counter
            cmp     #100,d1
            bne     clrGrdLoop          ; if equals 100 then break
            unlk    a0
            rts

*-------------------------------------------------------------------------------------

* draws the grid *

drwGrid     move.l  4(a7),d4            ; starting lower y value
            clr     d5                  ; row counter
drwRow      move.w  #GRIDX,d3           ; starting x value
            move.w  d4,d2               ; move lower y value into upper y
            add.w   tileSize,d4         ; add tile size to lower y
            clr     d6                  ; column counter
            jsr     drwCol          
            addq    #1,d5               ; increment row counter
            cmp     #$a,d5
            bne     drwRow
            rts 

drwCol      jsr     fillRct
            move.w  d3,d1               ; move right x value into left xx
            add.w   tileSize,d3         ; add tile size to right x
            move.w  #87,d0              ; draw rectangle
            trap    #15             
            addq    #1,d6               ; increment column counter
            cmp     #$a,d6
            bne     drwCol
            rts           

fillRct     link    a0,#-4
            lea     (a2),a3             ; load grid
            move.b  tileNum,d7          ; move 10 to d7 (number of tiles)
            mulu    d5,d7               ; multiply row counter with d7
            add.b   d6,d7               ; add column counter with d7
            adda    d7,a3               ; add d7 to grid address
            move.b  (a3),4(a0)          ; move value of a3 to local variable
            move.b  #$F0,d7             ; put bit mask 11110000 into d7                       
            and.b   4(a0),d7            ; and bit mask with tile data bits
            divu    #$10,d7             ; shift bits right
            mulu    #$4,d7              ; multiply by 4 to increment array of longs
            lea     tileclr,a3          ; load tile colour array address
            adda    d7,a3               ; increment array  
            move.l  (a3),d1             ; move selected colour into d1
fill        move.b  #81,d0              ; set fill colour
            trap    #15 
            
            unlk    a0 
            rts
            
            

*-----------------------------------------------------------------------------------

drawCursorTarget

            link    a0,#-8

            move.l  #FUCHSIA,d1
            move    #80,d0
            trap    #15


            clr     d1
            clr     d2
            move.b  10(a0),d1           
            mulu    tileSize,d1
            add     #GRIDX,d1

            move.b  8(a0),d2
            mulu    tileSize,d2
            add.l   12(a0),d2

            move.l  d1,d3
            move.l  d2,d4
            add     tileSize,d3
            add     tileSize,d4

            move.w  #91,d0
            trap    #15

            move.l  d1,-4(a0)           ; store x values in local variable
            move.l  d3,-8(a0)

            move    tileSize,d1
            divu    #2,d1
            add.l   -4(a0),d1              
            move    d1,d3

            move.w  #84,d0
            trap    #15

            move.l  -4(a0),d1           ; restore x values
            move.l  -8(a0),d3

            move.l  d2,-4(a0)           ; store y values in local variable
            move.l  d4,-8(a0)

            move    tileSize,d2
            divu    #2,d2
            add.l   -4(a0),d2              
            move    d2,d4

            move.w  #84,d0
            trap    #15

            move.l  #WHITE,d1
            move    #80,d0
            trap    #15

            unlk    a0
            rts


*-----------------------------------------------------------------------------------

addMargin
            link    a0,#-8
            move.w  8(a0),d1            ; ship x
            move.w  10(a0),d2           ; ship y
            
            subq.w  #1,d1            
            move.w  d1,-2(a0)           ; store start x pos
            subq.w  #1,d2
            
            move.w  d2,-4(a0)           ; store start y pos
            tst.w   8(a0)               ; test the horizontal flag
            beq     isVertical
            move.w  14(a0),d1           ; x counter 
            addq.w  #2,d1
            move.w  d1,-6(a0)           ; store x counter
            move.w  #2,-8(a0)           ; store y counter
            bra     addMarginToGrid
isVertical
            move.w  #2,-6(a0)           ; store x counter
            move.w  14(a0),d2
            addq.w  #2,d2               ; y counter is length plus 2
            move.w  d2,-8(a0)           ; store y counter
            
addMarginToGrid            
            lea     cmpGrid,a1
            add.w   -2(a0),a1
            move.w  -4(a0),d2           
            mulu    #10,d2              ; multiply y by 10 to get row position
            add.w   d2,a1               ; start x y position
            move.w  -6(a0),d1           ; x counter
addNextMargin
            tst.b   (a1)                ; if tile is not empty then skip
            beq     addMarginCont
            addq    #1,(a1)
addMarginCont
            move.b  #$10,(a1)+
            subq.w  #1,d1
            beq     incrementRow 
            bra     addNextMargin  
endOfLoop          
            unlk    a0
            rts

incrementRow
            tst.w   -8(a0)
            beq     endOfLoop          
            adda    #10,a1              ; add row
            suba    -6(a0),a1           ; set x back to start
            move.w  -6(a0),d1           ; reset x counter
            subq.w  #1,-8(a0)           ; decrement row counter
            bra     addNextMargin
 
 

plyrGrid    dc.b    0,0,0,0,0,0,0,0,0,0
            dc.b    0,0,0,0,0,0,0,0,0,0
            dc.b    0,0,0,0,0,0,0,0,0,0
            dc.b    0,0,0,0,0,0,0,0,0,0
            dc.b    0,0,0,0,0,0,0,0,0,0
            dc.b    0,0,0,0,0,0,0,0,0,0
            dc.b    0,0,0,0,0,0,0,0,0,0
            dc.b    0,0,0,0,0,0,0,0,0,0
            dc.b    0,0,0,0,0,0,0,0,0,0
            dc.b    0,0,0,0,0,0,0,0,0,0

cmpGrid     dc.b    0,0,0,0,0,0,0,0,0,0
            dc.b    0,0,0,0,0,0,0,0,0,0
            dc.b    0,0,0,0,0,0,0,0,0,0
            dc.b    0,0,0,0,0,0,0,0,0,0
            dc.b    0,0,0,0,0,0,0,0,0,0
            dc.b    0,0,0,0,0,0,0,0,0,0
            dc.b    0,0,0,0,0,0,0,0,0,0
            dc.b    0,0,0,0,0,0,0,0,0,0
            dc.b    0,0,0,0,0,0,0,0,0,0
            dc.b    0,0,0,0,0,0,0,0,0,0


GRIDX       equ     100
tileSize    dc.w    20
tileNum     dc.b    10


tileclr     dc.l    BLACK,GRAY,AQUA,YELLOW,RED,GREEN

BLACK       equ     $00000000 
MAROON      equ     $00000080 
GREEN       equ     $00008000 
OLIVE       equ     $00008080 
NAVY        equ     $00800000 
PURPLE      equ     $00800080 
TEAL        equ     $00808000 
GRAY        equ     $00808080 
RED         equ     $000000FF 
LIME        equ     $0000FF00 
YELLOW      equ     $0000FFFF 
BLUE        equ     $00FF0000 
FUCHSIA     equ     $00FF00FF 
AQUA        equ     $00FFFF00 
LTGRAY      equ     $00C0C0C0 
WHITE       equ     $00FFFFFF 




*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
