SGROUP 		GROUP 	CODE_SEG, DATA_SEG
			ASSUME 	CS:SGROUP, DS:SGROUP, SS:SGROUP
			
	TRUE  EQU 1
    FALSE EQU 0
	
; EXTENDED ASCII CODES
    ASCII_SPECIAL_KEY 	EQU 00
    ASCII_N1        	EQU 04Bh
    ASCII_N2       		EQU 04Dh
    ASCII_N3          	EQU 048h
    ASCII_N4        	EQU 050h
    ASCII_N5        	EQU 050h
    ASCII_QUIT        	EQU 071h ; 'q'
	ASCII_STRUM_GUITAR	EQU 01Dh ; 'ENTER'

; COLOR SCREEN DIMENSIONS IN NUMBER OF CHARACTERS
    SCREEN_MAX_ROWS EQU 25
    SCREEN_MAX_COLS EQU 80

; RAILS DIMENSIONS
	RAILS_C_DISTANCE EQU 5
    RAIL_R1 EQU 3
    RAIL_R2 EQU SCREEN_MAX_ROWS-3
    RAIL_C1 EQU 6
    RAIL_C2 EQU RAILS_C_DISTANCE+RAIL_C1
	RAIL_C3 EQU RAILS_C_DISTANCE+RAIL_C2
	RAIL_C4 EQU RAILS_C_DISTANCE+RAIL_C3
	RAIL_C5 EQU RAILS_C_DISTANCE+RAIL_C4
	
; STRUM AREA
	; ASCII_STRUM_ACTIVE		EQU 02Ah
	; ASCII_STRUM_ACTIVE		EQU 07Fh
	ASCII_STRUM_ACTIVE		EQU 0B0h
	ASCII_STRUM_DISABLE		EQU 020h
	; ASCII_STRUM		EQU 018h
	; ASCII_STRUM		EQU 013h
	; ASCII_STRUM		EQU 020h
	STRUM_R			EQU RAIL_R2-1
	ATTR_STRUM_C1	EQU 02Fh ; green
	ATTR_STRUM_C2	EQU 03Fh ; red
	ATTR_STRUM_C3	EQU 06Fh ; yellow
	ATTR_STRUM_C4	EQU 01Fh ; blue
	ATTR_STRUM_C5	EQU 05Fh ; pink
	
; ASCII / ATTR CODES TO DRAW THE RAILS
    ASCII_RAIL    EQU 020h
    ATTR_RAIL     EQU 070h
	
; ASCII / ATTR CODES TO DRAW THE NOTES
	ASCII_NOTE		EQU 020h
	ATTR_NOTE		EQU 04h

; CURSOR
    CURSOR_SIZE_HIDE EQU 02607h  ; BIT 5 OF CH = 1 MEANS HIDE CURSOR
    CURSOR_SIZE_SHOW EQU 00607h

; *************************************************************************
; The code starts here
; *************************************************************************
CODE_SEG	SEGMENT PUBLIC
		ORG 100h

MAIN 	PROC 	NEAR

	MAIN_GO:

      CALL REGISTER_TIMER_INTERRUPT

      CALL INIT_GAME
      CALL INIT_SCREEN
      CALL HIDE_CURSOR
      CALL DRAW_RAILS

      MOV DH, SCREEN_MAX_ROWS/2
      MOV DL, SCREEN_MAX_COLS/2
      
      CALL MOVE_CURSOR
	  
  MAIN_LOOP:
      CMP [END_GAME], TRUE
      JZ END_PROG
	  
	  ; Draw strum depending of rails active
	  CALL DRAW_STRUM

      ; Check if a key is available to read
      MOV AH, 0Bh
      INT 21h
      CMP AL, 0
      JZ MAIN_LOOP

      ; A key is available -> read
      CALL READ_CHAR
	  
	  ; Reset strum area
	  MOV [N1_ACTIVE], FALSE
	  MOV [N2_ACTIVE], FALSE
	  MOV [N3_ACTIVE], FALSE
	  MOV [N4_ACTIVE], FALSE
	  MOV [N5_ACTIVE], FALSE
      
	  CMP AL, ASCII_N1
      JZ N1_KEY
	  CMP AL, ASCII_N2
      JZ N2_KEY
	  CMP AL, ASCII_N3
      JZ N3_KEY
	  CMP AL, ASCII_N4
      JZ N4_KEY
	  CMP AL, ASCII_N5
      JZ N5_KEY
	  CMP AL, ASCII_QUIT
      JZ END_PROG
	  
   N1_KEY:
	  MOV [N1_ACTIVE], TRUE
	  JMP MAIN_LOOP
   N2_KEY:
	  MOV [N2_ACTIVE], TRUE
	  JMP MAIN_LOOP
   N3_KEY:
	  MOV [N3_ACTIVE], TRUE
	  JMP MAIN_LOOP
   N4_KEY:
	  MOV [N4_ACTIVE], TRUE
	  JMP MAIN_LOOP
   N5_KEY:
	  MOV [N5_ACTIVE], TRUE
	  JMP MAIN_LOOP
      
      ; Is it an special key?
      ; CMP AL, ASCII_SPECIAL_KEY
      ; JNZ MAIN_LOOP
      
      ; CALL READ_CHAR	  

      ; The game is on!
      MOV [START_GAME], TRUE
      
      JMP MAIN_LOOP

  END_PROG:
      CALL RESTORE_TIMER_INTERRUPT
	  
	  CALL RESTORE_CONSOLE
	  
      ;CALL PRINT_SCORE_STRING
      ;CALL PRINT_SCORE
      ;CALL PRINT_PLAY_AGAIN_STRING
      
      ;CALL READ_CHAR

      ;CMP AL, ASCII_YES_UPPERCASE
      ;JZ MAIN_GO
      ;CMP AL, ASCII_YES_LOWERCASE
      ;JZ MAIN_GO

	INT 20h		

MAIN	ENDP

; ****************************************
; Change what is necessary to return to the normal console
; Entry: 
;   -
; Returns:
;   -
; Modifies:
;   -
; Uses: 
;   -
; Calls:
;   MOVE_CURSOR
;	SHOW_CURSOR
; ****************************************
PUBLIC RESTORE_CONSOLE
RESTORE_CONSOLE PROC NEAR

	MOV DH, SCREEN_MAX_ROWS-1
	MOV DL, 1
	CALL MOVE_CURSOR
    CALL SHOW_CURSOR
    RET

RESTORE_CONSOLE       ENDP

; ****************************************
; Shows the cursor (standard size)
; Entry: 
;   -
; Returns:
;   -
; Modifies:
;   -
; Uses: 
;   -
; Calls:
;   int 10h, service AH=1
; ****************************************
PUBLIC SHOW_CURSOR
SHOW_CURSOR PROC NEAR

    PUSH AX
    PUSH CX
      
    MOV AH, 1
    MOV CX, CURSOR_SIZE_SHOW
    INT 10h

    POP CX
    POP AX
    RET

SHOW_CURSOR       ENDP
   
; ****************************************
; Reads char from keyboard
; If char is not available, blocks until a key is pressed
; The char is not output to screen
; Entry: 
;
; Returns:
;   AL: ASCII CODE
;   AH: ATTRIBUTE
; Modifies:
;   
; Uses: 
;   
; Calls:
;   
; ****************************************
PUBLIC  READ_CHAR
READ_CHAR PROC NEAR

    MOV AH, 8
    INT 21h

    RET
      
READ_CHAR ENDP

; ****************************************
; Reset internal variables
; Entry: 
;   
; Returns:
;   -
; Modifies:
;   -
; Uses:
;   START_GAME memory variable
;   END_GAME memory variable
; Calls:
;   -
; ****************************************
PUBLIC  INIT_GAME
INIT_GAME         PROC    NEAR

	; poner variables a 0
    ;MOV [NUM_TILES], 0
    
    MOV [START_GAME], FALSE
    MOV [END_GAME], FALSE

    RET
INIT_GAME	ENDP	

; ****************************************
; Set screen to mode 3 (80x25, color) and 
; clears the screen
; Entry: 
;   -
; Returns:
;   -
; Modifies:
;   -
; Uses: 
;   Screen size: SCREEN_MAX_ROWS, SCREEN_MAX_COLS
; Calls:
;   int 10h, service AH=0
;   int 10h, service AH=6
; ****************************************
PUBLIC INIT_SCREEN
INIT_SCREEN	PROC NEAR

      PUSH AX
      PUSH BX
      PUSH CX
      PUSH DX

      ; Set screen mode
      MOV AL,3
      MOV AH,0
      INT 10h

      ; Clear screen
      XOR AL, AL
      XOR CX, CX
      MOV DH, SCREEN_MAX_ROWS
      MOV DL, SCREEN_MAX_COLS
      MOV BH, 7
      MOV AH, 6
      INT 10h
      
      POP DX      
      POP CX      
      POP BX      
      POP AX      
	RET

INIT_SCREEN		ENDP

; ****************************************
; Hides the cursor 
; Entry: 
;   -
; Returns:
;   -
; Modifies:
;   -
; Uses: 
;   -
; Calls:
;   int 10h, service AH=1
; ****************************************
PUBLIC  HIDE_CURSOR
HIDE_CURSOR PROC NEAR

      PUSH AX
      PUSH CX
      
      MOV AH, 1
      MOV CX, CURSOR_SIZE_HIDE
      INT 10h

      POP CX
      POP AX
      RET

HIDE_CURSOR       ENDP

; ****************************************
; Draws the vertical rails of the guitar notes
; Entry: 
; 
; Returns:
;   
; Modifies:
;   
; Uses: 
;   Coordinates of the rails: 
;    left - top: (RAIL_R1, RAIL_C1) 
;    right - bottom: (RAIL_R2, RAIL_C5)
;   Character: ASCII_RAIL
;   Attribute: ATTR_RAIL
; Calls:
;   PRINT_CHAR_ATTR
; ****************************************
PUBLIC DRAW_RAILS
DRAW_RAILS PROC NEAR

    PUSH AX
    PUSH BX
    PUSH DX

    MOV AL, ASCII_RAIL
    MOV BL, ATTR_RAIL

    MOV DH, RAIL_R2
  LEFT_RIGHT_SCREEN_LIMIT:
    MOV DL, RAIL_C1
    CALL MOVE_CURSOR
    CALL PRINT_CHAR_ATTR

    MOV DL, RAIL_C2
    CALL MOVE_CURSOR
    CALL PRINT_CHAR_ATTR
	
	MOV DL, RAIL_C3
    CALL MOVE_CURSOR
    CALL PRINT_CHAR_ATTR
	
	MOV DL, RAIL_C4
    CALL MOVE_CURSOR
    CALL PRINT_CHAR_ATTR
	
	MOV DL, RAIL_C5
    CALL MOVE_CURSOR
    CALL PRINT_CHAR_ATTR

    DEC DH
    CMP DH, RAIL_R1
    JNS LEFT_RIGHT_SCREEN_LIMIT
                 
    POP DX
    POP BX
    POP AX
    RET

DRAW_RAILS       ENDP

; ****************************************
; Draws the five areas to detect the notes, the strum area
; Entry: 
; 
; Returns:
;   
; Modifies:
;   
; Uses: 
;   Coordinates of the areas: 
;    STRUM_R
;	 RAIL_C1, RAIL_C2, RAIL_C3, RAIL_C4, RAIL_C5
;   Character: ASCII_STRUM
;   Attribute: ATTR_STRUM_C1, ATTR_STRUM_C2, ATTR_STRUM_C3, ATTR_STRUM_C4, ATTR_STRUM_C5
; Calls:
;   PRINT_CHAR_ATTR
; ****************************************
PUBLIC DRAW_STRUM
DRAW_STRUM PROC NEAR

    PUSH AX
    PUSH BX
    PUSH DX

    MOV DH, STRUM_R
	
	;n1
	MOV AL, ASCII_STRUM_DISABLE

	CMP [N1_ACTIVE], TRUE
	JNZ PRINT_N1
	
	MOV AL, ASCII_STRUM_ACTIVE
		
	PRINT_N1:
		MOV DL, RAIL_C1-1
		MOV BL, ATTR_STRUM_C1
		CALL MOVE_CURSOR
		CALL PRINT_CHAR_ATTR
		MOV DL, RAIL_C1+1
		CALL MOVE_CURSOR
		CALL PRINT_CHAR_ATTR

	;n2
	MOV AL, ASCII_STRUM_DISABLE

	CMP [N2_ACTIVE], TRUE
	JNZ PRINT_N2
	
	MOV AL, ASCII_STRUM_ACTIVE
	
	PRINT_N2:
		MOV DL, RAIL_C2-1
		MOV BL, ATTR_STRUM_C2
		CALL MOVE_CURSOR
		CALL PRINT_CHAR_ATTR
		MOV DL, RAIL_C2+1
		CALL MOVE_CURSOR
		CALL PRINT_CHAR_ATTR
	
	;n3	
	MOV AL, ASCII_STRUM_DISABLE

	CMP [N3_ACTIVE], TRUE
	JNZ PRINT_N3
	
	MOV AL, ASCII_STRUM_ACTIVE
	
	PRINT_N3:
		MOV DL, RAIL_C3-1
		MOV BL, ATTR_STRUM_C3
		CALL MOVE_CURSOR
		CALL PRINT_CHAR_ATTR
		MOV DL, RAIL_C3+1
		CALL MOVE_CURSOR
		CALL PRINT_CHAR_ATTR
	
	;n4
	MOV AL, ASCII_STRUM_DISABLE

	CMP [N4_ACTIVE], TRUE
	JNZ PRINT_N4
	
	MOV AL, ASCII_STRUM_ACTIVE
	
	PRINT_N4:
		MOV DL, RAIL_C4-1
		MOV BL, ATTR_STRUM_C4
		CALL MOVE_CURSOR
		CALL PRINT_CHAR_ATTR
		MOV DL, RAIL_C4+1
		CALL MOVE_CURSOR
		CALL PRINT_CHAR_ATTR
	
	;n5
	MOV AL, ASCII_STRUM_DISABLE

	CMP [N5_ACTIVE], TRUE
	JNZ PRINT_N5
	
	MOV AL, ASCII_STRUM_ACTIVE
	
	PRINT_N5:
		MOV DL, RAIL_C5-1
		MOV BL, ATTR_STRUM_C5
		CALL MOVE_CURSOR
		CALL PRINT_CHAR_ATTR
		MOV DL, RAIL_C5+1
		CALL MOVE_CURSOR
		CALL PRINT_CHAR_ATTR
                 
    POP DX
    POP BX
    POP AX
    RET

DRAW_STRUM       ENDP

; ****************************************
; Prints character and attribute in the 
; current cursor position, page 0 
; Keeps the cursor position
; Entry: 
;   AL: ASCII to print
;   BL: ATTRIBUTE to print
; Returns:
;   
; Modifies:
;   
; Uses: 
;
; Calls:
;   int 10h, service AH=9
; Nota:
;   Compatibility problem when debugging
; ****************************************
PUBLIC PRINT_CHAR_ATTR
PRINT_CHAR_ATTR PROC NEAR

    PUSH AX
    PUSH BX
    PUSH CX

    MOV AH, 9
    MOV BH, 0
    MOV CX, 1
    INT 10h

    POP CX
    POP BX
    POP AX
    RET

PRINT_CHAR_ATTR        ENDP

; ****************************************
; Move cursor to coordinate
; Cursor size if kept
; Entry: 
;   (DH, DL): coordinates -> (row, col)
; Returns:
;   -
; Modifies:
;   -
; Uses: 
;   -
; Calls:
;   GET_CURSOR_PROP
;   SET_CURSOR_PROP
; ****************************************
PUBLIC MOVE_CURSOR
MOVE_CURSOR PROC NEAR

      PUSH DX
      CALL GET_CURSOR_PROP  ; Get cursor size
      POP DX
      CALL SET_CURSOR_PROP
      RET

MOVE_CURSOR       ENDP

; ****************************************
; Get cursor properties: coordinates and size (page 0)
; Entry: 
;   -
; Returns:
;   (DH, DL): coordinates -> (row, col)
;   (CH, CL): cursor size
; Modifies:
;   -
; Uses: 
;   -
; Calls:
;   int 10h, service AH=3
; ****************************************
PUBLIC GET_CURSOR_PROP
GET_CURSOR_PROP PROC NEAR

      PUSH AX
      PUSH BX

      MOV AH, 3
      XOR BX, BX ; si bx == bx -> bx = 0
      INT 10h

      POP BX
      POP AX
      RET
      
GET_CURSOR_PROP       ENDP

; ****************************************
; Set cursor properties: coordinates and size (page 0)
; Entry: 
;   (DH, DL): coordinates -> (row, col)
;   (CH, CL): cursor size
; Returns:
;   -
; Modifies:
;   -
; Uses: 
;   -
; Calls:
;   int 10h, service AH=2
; ****************************************
PUBLIC SET_CURSOR_PROP
SET_CURSOR_PROP PROC NEAR

      PUSH AX
      PUSH BX

      MOV AH, 2
      XOR BX, BX
      INT 10h

      POP BX
      POP AX
      RET
      
SET_CURSOR_PROP       ENDP

; ****************************************
; Game timer interrupt service routine
; Called 18.2 times per second by the operating system
; Calls previous ISR
; Manages the movement of the notes: 
;   position, direction, display, collisions with strumming area
; Entry: 
;   -
; Returns:
;   -
; Modifies:
;   -
; Uses: 
;   OLD_INTERRUPT_BASE memory variable
;   START_GAME memory variable
;   END_GAME memory variable
;   ATTR_NOTE constant
; Calls:
;   MOVE_CURSOR
;   READ_SCREEN_CHAR
;   PRINT_NOTE
; ****************************************
PUBLIC NEW_TIMER_INTERRUPT
NEW_TIMER_INTERRUPT PROC NEAR

    ; Call previous interrupt
    PUSHF
    CALL DWORD PTR [OLD_INTERRUPT_BASE]

    PUSH AX

    ; Do nothing if game is stopped
    CMP [START_GAME], TRUE
    JNZ END_ISR
	
	; borrar ultima posicion
	MOV AL, 020h ; caracter
    MOV BL, 0h	; color_fondo
    CALL PRINT_CHAR_ATTR

    ; Load worm coordinates
	XOR DL, DL ; DL = 0
	MOV DH, 1

    ; Move notes on the screen
    CALL MOVE_CURSOR

    ; Check if snake collided with the field or with himself
    ;CALL READ_SCREEN_CHAR
    ;CMP AH, ATTR_SNAKE
    ;JZ END_SNAKES

    CALL PRINT_NOTE

    JMP END_ISR
      
END_SNAKES:
      MOV [END_GAME], TRUE
      
END_ISR:

      POP AX
      IRET

NEW_TIMER_INTERRUPT ENDP

; ****************************************
; Replaces current timer ISR with the game timer ISR
; Entry: 
;   -
; Returns:
;   -
; Modifies:
;   -
; Uses: 
;   OLD_INTERRUPT_BASE memory variable
;   NEW_TIMER_INTERRUPT memory variable
; Calls:
;   int 21h, service AH=35 (system interrupt 08)
; ****************************************
PUBLIC REGISTER_TIMER_INTERRUPT
REGISTER_TIMER_INTERRUPT PROC NEAR

        PUSH AX
        PUSH BX
        PUSH DS
        PUSH ES 

        CLI                                 ;Disable Ints
        
        ;Get current 01CH ISR segment:offset
        MOV  AX, 3508h                      ;Select MS-DOS service 35h, interrupt 08h
        INT  21h                            ;Get the existing ISR entry for 08h
        MOV  WORD PTR OLD_INTERRUPT_BASE+02h, ES  ;Store Segment 
        MOV  WORD PTR OLD_INTERRUPT_BASE, BX  ;Store Offset

        ;Set new 01Ch ISR segment:offset
        MOV  AX, 2508h                      ;MS-DOS serivce 25h, IVT entry 01Ch
        MOV  DX, offset NEW_TIMER_INTERRUPT ;Set the offset where the new IVT entry should point to
        INT  21h                            ;Define the new vector

        STI                                 ;Re-enable interrupts

        POP  ES                             ;Restore interrupts
        POP  DS
        POP  BX
        POP  AX
        RET      

REGISTER_TIMER_INTERRUPT ENDP

; ****************************************
; Restore timer ISR
; Entry: 
;   -
; Returns:
;   -
; Modifies:
;   -
; Uses: 
;   OLD_INTERRUPT_BASE memory variable
; Calls:
;   int 21h, service AH=25 (system interrupt 08)
; ****************************************
PUBLIC RESTORE_TIMER_INTERRUPT
RESTORE_TIMER_INTERRUPT PROC NEAR

      PUSH AX                             
      PUSH DS
      PUSH DX 

      CLI                                 ;Disable Ints
        
      ;Restore 08h ISR
      MOV  AX, 2508h                      ;MS-DOS service 25h, ISR 08h
      MOV  DX, WORD PTR OLD_INTERRUPT_BASE
      MOV  DS, WORD PTR OLD_INTERRUPT_BASE+02h
      INT  21h                            ;Define the new vector

      STI                                 ;Re-enable interrupts

      POP  DX                             
      POP  DS
      POP  AX
      RET    
      
RESTORE_TIMER_INTERRUPT ENDP

; ****************************************
; Prints notes, at the current cursor position
; Entry: 
; 
; Returns:
;   
; Modifies:
;   
; Uses: 
;   character: ASCII_NOTE
;   attribute: ATTR_NOTE
; Calls:
;   PRINT_CHAR_ATTR
; ****************************************
PUBLIC PRINT_NOTE
PRINT_NOTE PROC NEAR

    PUSH AX
    PUSH BX
    MOV AL, ASCII_NOTE
    MOV BL, ATTR_NOTE
    CALL PRINT_CHAR_ATTR
      
    POP BX
    POP AX
    RET

PRINT_NOTE        ENDP

CODE_SEG 	ENDS

; *************************************************************************
; The data starts here
; *************************************************************************
DATA_SEG	SEGMENT	PUBLIC
    
	OLD_INTERRUPT_BASE    DW  0, 0  ; Stores the current (system) timer ISR address

	; Determinates if can capture the note of a rail
	N1_ACTIVE DB FALSE
	N2_ACTIVE DB FALSE
	N3_ACTIVE DB FALSE
	N4_ACTIVE DB FALSE
	N5_ACTIVE DB FALSE

    START_GAME DB 0             ; 'MAIN' sets START_GAME to 'TRUE' when a key is pressed
    END_GAME DB 0               ; 'NEW_TIMER_INTERRUPT' sets END_GAME to 'TRUE' when a condition to end the game happens

    SCORE_STR           DB "Your score is $"
	
DATA_SEG	ENDS

	END MAIN