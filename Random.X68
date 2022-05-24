*
*   Module for generating random numbers
* 
*   Uses the Linear congruential generator algorithm
*
*   Rn+1 = (A x Rn + C) mod M
*
*   A (multiplier) = 2256
*   C (increment)  = 2
*   M (modulus)    = 65535
*
*   Seed value is taken from hundredths of seconds since midnight
*
*   setSeed must be called once before using getRandom function   
*
*   getRandom takes 2 parameters 
*       D2: Range of values
*       D3: Lower limit of values
*
*   D2 + D3 should not be greater than 65535


setSeed 
        move.w  #8,d0           ; get hundredths of seconds since midnight
        trap    #15             ;
        move.w  d1,seed         ; store low word as seed
        rts

            
getRandom
        clr.l   d1              ; 
        move.w  seed,d1         ;
        mulu    multiplier,d1   ; 
        add.l   increment,d1    ;
        divu    modulus,d1      ;
        swap    d1              ; 
        move.w  d1,seed         ; store result as next value
        and.l   #$0000FFFF,d1   ; clear high word
        divu.w  d2,d1           ; divide by range parameter
        swap    d1              ; swap to get remainder
        add.w   d3,d1           ; add lower limit parameter
        and.l   #$0000FFFF,d1   ; clear high word
        rts
       

seed        ds.w    1
multiplier  dc.w    2256
increment   dc.w    2
modulus     dc.w    $FFFF



*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
