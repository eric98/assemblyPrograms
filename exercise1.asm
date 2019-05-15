SGROUP 		GROUP 	CODE_SEG, DATA_SEG
			ASSUME 	CS:SGROUP, DS:SGROUP, SS:SGROUP

; DEFINE YOUR CONSTANTS HERE
    WRITE_CHAR_TO_STDOUT_INT21h_SERVICE EQU 2
    CHAR_READ_FROM_STDIN_INT21h_SERVICE EQU 8
    ASCII_EXT                           EQU 00    ; ASCII indicating extended ASCII
    ASCII_ARROW_UP                      EQU 48h
    ASCII_U                             EQU 55h
    ASCII_O                             EQU 4Fh


; *************************************************************************
; The code starts here
; *************************************************************************
CODE_SEG	SEGMENT PUBLIC
		ORG 100h

; ****************************************
; The main function, as stated by the directive: END MAIN
; ****************************************
MAIN 	PROC 	NEAR

      ; INSERT YOUR CODE HERE
      CALL DETECT_ARROW_UP
   
	int 20h			; terminate program
MAIN	ENDP	

; ****************************************
; Writes 'U' to stdout if a the character read from stdin is arrow up,  ; An example of a function definition
; otherwise 'O'
; Entry:
;   -
; Returns:
;   -   ; values returned by the function ; Ex: AH: number of hits
; Modifies:
;   AL, AH, DL  ; registers modified by the function and not restored
; Uses: 
;   ; constants used by the function ; Ex: CONSTANT_1 
;   WRITE_CHAR_TO_STDOUT_INT21h_SERVICE
;   CHAR_READ_FROM_STDIN_INT21h_SERVICE
;   ASCII_EXT
;   ASCII_ARROW_UP
;   ASCII_U
;   ASCII_O
; Calls:
;   Int 21h, service 08 ; functions calls
;   Int 21h, service 02
; ****************************************
            PUBLIC  DETECT_ARROW_UP
DETECT_ARROW_UP 	PROC    NEAR
                                                ; posem una h despres dels nombres per a indicar que esta escrit amb hexadecimal, sino posem res ho detecta com a decimal
    MOV AH, CHAR_READ_FROM_STDIN_INT21h_SERVICE
    INT 21h                                     ; executa la funcio de AH (8) de la llibreria 21h 
    CMP AL, ASCII_EXT
    JNZ IS_NOT_EXTENDED
    INT 21h
    CMP AL, ASCII_ARROW_UP
    JNZ IS_NOT_ARROW_UP
    MOV DL, ASCII_U
    JMP PRINT_CHAR

IS_NOT_EXTENDED:
IS_NOT_ARROW_UP:
    MOV DL, ASCII_O

PRINT_CHAR:
    MOV AH, WRITE_CHAR_TO_STDOUT_INT21h_SERVICE
    INT 21h

    RET

DETECT_ARROW_UP	ENDP

CODE_SEG 	ENDS

; *************************************************************************
; The data starts here
; *************************************************************************
DATA_SEG	SEGMENT	PUBLIC
    ; DEFINE YOUR MEMORY HERE
	DATA		DB 20 DUP (0)
DATA_SEG	ENDS

	END MAIN