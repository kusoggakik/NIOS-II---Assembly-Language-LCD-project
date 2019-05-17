
############################## DEFINITIONS #############################
        .equ    JTAG_DATA, 0x10001000   # Base address to the JTAG data register
        .equ    JTAG_CTRL, 0x10001004   # Base address to the JTAG control register

        .equ    LCD_INST, 0x10003050    # Base address to the LCD instruction register
        .equ    LCD_DATA, 0x10003051    # Base address to the LCD data register

        .equ    RS232_DATA, 0x10001010  # Base address to the RS-232 data register
        .equ    RS232_CTRL, 0x10001014  # Base address to the RS-232 control register

        
############################# CODE SEGMENT #############################


        .text
        .global _start

_start:
        movia r21, JTAG_CTRL
        movia r15, JTAG_DATA
		movia r14, RS232_CTRL
		movia r7, RS232_DATA
		call lcd_cursor_off
		
		
main_loop:

        ## laddar en byte med offset 1 från JTAG_DATA
		ldbuio r22 , 1 (r15)
		## kollar om den sjunde biten inom detta är satt till 1 med andi och returnerar detta till r12
		andi r12, r22 , 0b10000000
		## jämför r12 med r0 alltså kollar om den är 0 och om inte så har jtag data att läsa
		bne r0, r12, jtag_has_data
		## har jtag inte data så hoppa till labeln jtag_empty
		beq r0, r12, jtag_empty 
		
			


jtag_has_data:
       
	   call jtag_get
	   mov r4, r2
	   call jtag_put #echo to terminal?
	   
	  	   
	   ## till LED
	   mov r6, r2

	   movui r4, 0
	   movui r5, 0
	   call lcd_put
	   
	   
	   
	   mov r4, r2
	   call rs232_put
	   
hoppa_hit:
	   ## laddar en byte med offset 1 från RS232_DATA
	   ldbuio r3 , 1(r7)
	   ## kollar om den sjunde biten inom detta är satt till 1 med andi och returnerar detta till r13
       andi r13, r3 ,0b10000000
	   ## har RS-232 inte data så hoppa till labeln main_loop
       beq r0, r13, main_loop
	   
	   call rs232_get
	   mov r4, r2
	   call jtag_put #write to terminal?
	   
	   ## till LED
	   mov r6, r2
	   movui r4, 0
	   movui r5, 15
	   call lcd_put
	   
	   br main_loop

	   
	   
	   
		

jtag_empty:   

      br hoppa_hit


      
       
        ######################## JTAG FUNCTIONS ########################

        ################################################################
        # jtag_get                                                     #
        # Returns JTAG input.                                          #
        # Arguments: none                                              #
        # Returns:                                                     #
        #   r2  The data in bit field [0,7] of the                     #
        #       JTAG DATA register.                                    #
        ################################################################
jtag_get:

         ldwio r11 ,0(r15)
         andi r2, r11, 0xff
         
		 ret
		 
		 
		 
		 
		 
		 
		 
        
        
        
        ################################################################
        # jtag_put                                                     #
        # Writes a character to the JTAG port if there is space        #
        # available in the FIFO.                                       #
        # Arguments:                                                   #
        #   r4  The character to write                                 #
        ################################################################
jtag_put:

       ldhuio r18, 2(r21)
	   beq r0, r18, jtag_put_end
	   
       
	   stbio r4, 0(r15)
		
        

       
        
jtag_put_end:
        ret

        
        ####################### RS-232 FUNCTIONS #######################
        
        ################################################################
        # rs232_get                                                    #
        # Returns RS-232 input.                                        #
        # Arguments: none                                              #
        # Returns:                                                     #
        #   r2  The data in bit field [0,7] of the                     #
        #       RS-232 DATA register.                                  #
        ################################################################
rs232_get:

        ldwio r11 ,0(r7)
        andi r2, r11, 0xff
         
		ret

        
        ################################################################
        # rs232_put                                                    #
        # Writes a character to the RS-232 port if there is space      #
        # available in the FIFO.                                       #
        # Arguments:                                                   #
        #   r4  The character to write                                 #
        ################################################################
rs232_put:

       ldhuio r18, 2 (r14)
	   beq r0, r18, rs232_end_put
	   
       stbio r4, 0 (r7)


rs232_end_put:
        ret
        
        
        ######################## LCD FUNCTIONS #########################

        ################################################################
        # lcd_cursor_off                                               #
        # Turns off the LCD cursor.                                    #
        # Arguments: none                                              #
        ################################################################
lcd_cursor_off:
        movia   r8, LCD_INST    # Turn off LCD cursor
        movui   r9, 0x000C
        stbio   r9, 0(r8)
        
        ret
        
        
        ################################################################
        # lcd_put                                                      #
        # Prints a character at a given position on the LCD.           #
        # Arguments:                                                   #
        #   r4  The line (0: line one, 1: line two)                    #
        #   r5  The position on the line (0, 1, ... or 15)             #
        #   r6  The character to print                                 #
        ################################################################        
lcd_put:
        # Set cursor position
        slli    r8, r4, 7       # Shift line bit to position 6
        or      r8, r8, r5      # Concatenate line bit and positions bits
        ori     r8, r8, 0x80    # Set instruction bit
        movia   r9, LCD_INST
        stbio   r8, 0(r9)
        
        movia   r10, LCD_DATA    # Print character
        stbio   r6, 0(r10)
        
        ret

end:
        .end
        
