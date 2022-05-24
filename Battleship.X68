*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:

*-----------------------------------------------------------
    ORG    $1000
START:                              ; first instruction of program
            
* initialise

            move.l		#12,d0	    ; Turn Off Keyboard Echo (don't display characters)
		    move.l		#0,d1
		    trap		#15
		    jsr         setSeed     ; set the random seed
		    jsr         gameLoop

        

    SIMHALT                     ; halt simulator

    INCLUDE     Main.X68
    
END    START        ; last line of source



*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
