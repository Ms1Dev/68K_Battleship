*
*   Module for generating random numbers
* 
*   Uses 16 bit Linear-feedback shift register 
*
*   Taps are at bits 1, 11, 13, 14 and 16
*
*   Seed value is taken from hundredths of seconds since midnight
*
*   setSeed must be called once before using getRandom function   
*
*   getRandom takes 2 parameters 
*       D2.W: Range of values
*       D3.W: Lower limit of values
*
*   D2 + D3 should not be greater than 65535 ($FFFF)
*
*---------------------------------------------------------------------------


setSeed    
        move.w  #8,d0           ; get hundredths of seconds since midnight
        trap    #15             ;
        move.w  d1,seed         ; store low word as seed
        rts

            
getRandom
        link    a0,#0

        movem.l d2-d5,registerData          ; back up register data
        clr.l   d1 
        tst.w   d2                          ; if range is set to 0 then return 
        beq     rand_return                 ; return value will be 0
        move.w  seed,d1                 
        clr.l   d4             

        for d5 = #0 to #15 do
            
                move.l  d1,d3               ; d3 will be lsb
                and.l   #1,d3               ; get lsb                      
                lsl.l   #1,d4               ; shift output to make room for new bit
                or      d3,d4               ; add bit to output      
                lsr.l   #1,d1               ; shift start state
                move.l  d1,d2               ; use d2 to shift and xor with d3
                eor     d2,d3               ; xor d2 with lsb (tap position 1)
                lsr.l   #8,d2               ; shift d2 a further 10 bits
                lsr.l   #2,d2               ; (can only shift 8 at a time)
                eor     d2,d3               ; xor d2 with lsb (tap position 11)
                lsr.l   #2,d2               ; shift d2 2 bits
                eor     d2,d3               ; xor d2 with lsb (tap position 13)
                lsr.l   #1,d2               ; shift d2 1 bit       
                eor     d2,d3               ; xor d2 with lsb (tap position 14)
                lsr.l   #2,d2               ; shift d2 2 bits
                eor     d2,d3               ; xor d2 with lsb (tap position 16)
                and.l   #1,d3               ; get lsb  
                ror.w   #1,d3               ; rotate to put it at start of word
                or.l    d3,d1               ; add it to the start state
        
        endf
        
        move.w  d1,seed                 ; store d1 as seed 
        move.w  d4,d1                   ; move the output into d1 
        
        movem.l registerData,d2-d5      ; restore data registers

        and.l   #$0000FFFF,d1           ; clear high word
        divu.w  d2,d1                   ; divide by range parameter
        swap    d1                      ; swap to get remainder
        add.w   d3,d1                   ; add lower limit parameter
        and.l   #$0000FFFF,d1           ; clear high word
        rand_return:   
        unlk    a0
        rts
       

seed            ds.l    1
registerData    ds.l    4

