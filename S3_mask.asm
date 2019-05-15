SGROUP 		GROUP 	CODE_SEG, DATA_SEG
			ASSUME 	CS:SGROUP, DS:SGROUP, SS:SGROUP

; DEFINE YOUR CONSTANTS HERE
    INIT_MASK     EQU 80h
	ASCII_0		  EQU '0'

; *************************************************************************
; The code starts here
; *************************************************************************
CODE_SEG	SEGMENT PUBLIC
		ORG 100h

; ****************************************
; The main function, as stated by the directive: END MAIN
; ****************************************
MAIN 	PROC 	NEAR

      MOV BL, 07Eh	; Any number
      CALL DISPLAY_BINARY_NUMBER
   
	int 20h			; terminate program
MAIN	ENDP	

; ****************************************
; Displays in binary in stdout the 8-bit number in BL
; Entry:
;   - BX: the 8-bit number (in BL)
; Returns:
;   -
; Modifies:
;   DX
; Uses: 
;   -
; Calls:
;   DISPLAY_BINARY_DIGIT
; ****************************************
            PUBLIC  DISPLAY_BINARY_NUMBER
DISPLAY_BINARY_NUMBER PROC NEAR

      MOV DH, INIT_MASK ; The mask

NEW_DIGIT:	  
	  MOV DL, DH
	  AND DL, BL
	  JZ IS_ZERO
	  MOV DL, 1

IS_ZERO:	  
      CALL DISPLAY_BINARY_DIGIT

	  SHR DH, 1		; Shift mask right (to less significant bits)
      CMP DH, 0
      JNZ NEW_DIGIT

      RET
      
DISPLAY_BINARY_NUMBER ENDP

; ****************************************
; Displays in stdout a binary digit (0/1 raw) in AL
; Entry:
;   - DL: binary digit
; Returns:
;   -
; Modifies:
;   - AH, DL
; Uses: 
;   -
; Calls:
;   - int21h, service ah=2
; ****************************************
            PUBLIC  DISPLAY_BINARY_DIGIT
DISPLAY_BINARY_DIGIT 	PROC    NEAR

      add dl, ASCII_0
      mov ah, 2
      int 21h      

      RET
      
DISPLAY_BINARY_DIGIT	ENDP

CODE_SEG 	ENDS

; *************************************************************************
; The data starts here
; *************************************************************************
DATA_SEG	SEGMENT	PUBLIC
    ; DEFINE YOUR MEMORY HERE

DATA_SEG	ENDS

	END MAIN