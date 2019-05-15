
; *************************************************************************
; Our data section. Here we declare our strings for our console message
; *************************************************************************

SGROUP 		GROUP 	CODE_SEG, DATA_SEG
			ASSUME 	CS:SGROUP, DS:SGROUP, SS:SGROUP

; *************************************************************************
; Our executable assembly code starts here in the .code section
; *************************************************************************
CODE_SEG	SEGMENT PUBLIC
			ORG 100h

MAIN 	PROC 	NEAR
	MOV BX, 0A34Ch	; number to display in binary format
	CALL PRINT_CHARACTER
	int 20h			; terminate program
MAIN	ENDP	

            		PUBLIC  PRINT_CHARACTER
PRINT_CHARACTER 	PROC    NEAR

	PUSH AX
	PUSH BX
	PUSH CX
	PUSH DX
	
	MOV AH, 2		; int 21h, service 2: writes ascii code in dl to screen
	MOV CX, 10h		; loop counter
	LOOP_DIGITS:
		MOV dl, 0
		RCL bx,1	; rotate left with carry
		ADC dl, 30h ; 30h is the asccii code for number '0'
		INT 21h		; int 21h, service 2: writes ascii code in dl to screen
		LOOP LOOP_DIGITS ; DEC CX and JNZ LABEL
		
	POP DX
	POP CX
	POP BX
	POP AX
	RET

PRINT_CHARACTER		ENDP

CODE_SEG 	ENDS

DATA_SEG	SEGMENT	PUBLIC
			DB 20 DUP (0)
DATA_SEG	ENDS

			END MAIN

; =================================================== 
; 16-bit DOS running restricts under Windows 2000/XP:
; ===================================================
;
; * All MS-DOS functions except task-switching API (application programming interface) functions are supported.
; * Block mode device drivers are not supported. Block devices are not supported, so MS-DOS I/O control 
;      (IOCTL) APIs that deal with block devices and SETDPB functions are not supported.
; * Interrupt 10 function 1A returns 0; all other functions are passed to read-only memory (ROM).
; * Interrupt 13 calls that deal with prohibited disk access are not supported.
; * Interrupt 18 (ROM BASIC) generates a message that says that ROM BASIC is not supported.
; * Interrupt 19 does not restart the computer, but cleanly closes the current virtual DOS machine (VDM).
; * Interrupt 2F, which deals with the DOSKEY program callouts (AX = 4800), is not supported.
; * Microsoft CD-ROM Extensions (MSCDEX) functions 2, 3, 4, 5, 8, E, and F are not supported.
; * The 16-bit Windows subsystem on an x86 computer supports enhanced mode programs; it does not, however, 
;      support 16-bit virtual device drivers (VxDs). The subsystem on a non-x86 computer emulates the Intel 
;      40486 instruction set, which lets the computer run Enhanced-mode programs, such as Microsoft 
;      Visual Basic, on reduced instruction set computers (RISC).
;
; This means that Windows does not support 16-bit programs that require unrestricted access to hardware. 
; If your program requires this, your program will not work in Windows NT, Windows 2000, or Windows XP.
; (source: http://wyding.blogspot.com/2009/04/helloworld-for-16bit-dos-assembly.html)
