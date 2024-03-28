;==================================================================================
; Contents of this file are copyright Grant Searle
; Modified to use BIT Banged Serial port on Southern Cross SBC by Derek Cooper 27.03.24
;
;==================================================================================

KEYBUF	.EQU	86H	;KEYBOARD BUFFER
SCAN	.EQU	85H	;DISPLAY SCAN LATCH
;
; BIT BANG BAUD RATE CONSTANTS
;
B300	.EQU	0220H	;300 BAUD
B1200	.EQU	0080H	;1200 BAUD
B2400	.EQU	003FH	;2400 BAUD
B4800	.EQU	001BH	;4800 BAUD
B9600	.EQU	000BH	;9600 BAUD

TEMPSTACK       .EQU    $20ED ; Top of BASIC line input buffer so is "free ram" when BASIC resets
serBuf          .EQU    $2000
serFlag         .EQU    $2001
basicStarted	.EQU	$2002

CR              .EQU	0DH
LF              .EQU	0AH
CL		.EQU	0CH

warmb		.equ	$0203	;warm boot basic
coldb		.equ	$0200	;cold boot into basic
;------------------------------------------------------------------------------
; Reset

                .ORG	$0000
RST00		di                       ;Disable interrupts
		jp       INIT            ;Initialize Hardware and go

;------------------------------------------------------------------------------
; TX a character over RS232 

                .ORG     0008H
RST08            jp      TXA

;------------------------------------------------------------------------------
; RX a character over RS232 Channel A [Console], hold here until char ready.

                .ORG 0010H
RST10            jp      RXA

;------------------------------------------------------------------------------
; Check serial status

                .ORG 0018H
RST18            jp      CKINCHAR

;------------------------------------------------------------------------------
; RST 38 - INTERRUPT VECTOR [ for IM 1 ]

                .ORG     0038H
RST38            di
		 ret

;------------------------------------------------------------------------------
; SERIAL RECEIVE ROUTINE
;-----------------------
;RECEIVE SERIAL BYTE FROM DIN
;
; ENTRY : NONE
;  EXIT : A= RECEIVED BYTE IF CARRY CLEAR
;
; REGISTERS MODIFIED A AND F
;
RXA:		push	bc
		push	hl
;
; WAIT FOR START BIT
;
	ld	a,(serFlag)	; do we already have a byte
	or	a
	jr	z,RXDAT1	; no current data so wait as normal
	xor	a
	ld	(serFlag),a	; we have used up all bytes, set flag to say buf empty
	ld	a,(serBuf)	; get the key
	jr	RXDONE
	
RXDAT1	in	a,(KEYBUF)
	bit	7,a
	jr	nz,RXDAT1	;NO START BIT
;
; DETECTED START BIT
;
	ld	hl,B9600	;get the baud rate
	srl	h
	rr	l	;DELAY FOR HALF BIT TIME
	call	BITIME
	in	a,(KEYBUF)
	bit	7,a
	jr	nz,RXDAT1	;START BIT NOT VALID
;
; DETECTED VALID START BIT,READ IN DATA
;
	call	rxdata
RXDONE	or	a	;CLEAR CARRY FLAG
	pop	hl
	pop	bc
	ret

; read all 8 bits
rxdata	ld	b,08H
RXDAT2	ld	hl,B9600
	call	BITIME	;DELAY ONE BIT TIME
	in	a,(KEYBUF)
	rl	a
	rr	c	;SHIFT BIT INTO DATA REG
	djnz	RXDAT2
	ld	a,c
	ret

CKINCHAR
        push	BC
	push	HL
	in	a,(KEYBUF)	;see if it looks like a start bit
	bit	7,a
	jr	nz,ckinchar1	;no key pressed exit
		;
; DETECTED START BIT
   	ld	hl,B9600
       	srl     h
       	rr      l       ;DELAY FOR HALF BIT TIME
       	call    BITIME
       	in      a,(KEYBUF)
       	bit     7,a
       	jr      nz,ckinchar1       ;START BIT NOT VALID
;
; DETECTED VALID START BIT,READ IN DATA
;
	call	rxdata
        ld	(serBuf),a	;keep for later
	ld	a,0ffh
	ld	(serFlag),a	;say we have a byte
	or	a		;found a char (nz)
        pop	hl
        pop	bc
        ret
ckinchar1
	xor	a	; set z flag
	pop	hl
	pop	bc
        ret
	
;------------------------------------------------------------------------------
;------------------------
; SERIAL TRANSMIT ROUTINE
;------------------------
;TRANSMIT BYTE SERIALLY ON DOUT
;
; ENTRY : A = BYTE TO TRANSMIT
;  EXIT : NO REGISTERS MODIFIED
;
TXA:	PUSH	AF
	PUSH	BC
	PUSH	HL
	LD	HL,B9600
	LD	C,A
;
; TRANSMIT START BIT
;
	XOR	A
	OUT	(SCAN),A
	CALL	BITIME
;
; TRANSMIT DATA
;

	LD	B,08H
	RRC	C
NXTBIT	RRC	C	;SHIFT BITS TO D6,
	LD	A,C	;LSB FIRST AND OUTPUT
	AND	40H	;THEM FOR ONE BIT TIME.
	OUT	(SCAN),A
	CALL	BITIME
	DJNZ	NXTBIT
;
; SEND STOP BITS
;
	LD	A,40H
	OUT	(SCAN),A
	CALL	BITIME
	CALL	BITIME
	POP	HL
	POP	BC
	POP	AF
	RET
;
INIT:
	ld	a,40H
	out	(SCAN),a	;TURN OFF THE DISPLAY MAKE SERIAL TX HIGH
        ld 	hl,TEMPSTACK    ; Temp stack
	ld	sp,hl
	xor	a		;send break until terminal is in sync
	ld	b,a
waste:	RST	08H             ; Print it
	djnz	waste
    
        LD        HL,SIGNON1      ; Sign-on message
        CALL      PRINT           ; Output string
        
        LD        A,(basicStarted); Check the BASIC STARTED flag
        CP        'Y'             ; to see if this is power-up
        JR        NZ,COLDSTART    ; If not BASIC started then always do cold start
        LD        HL,SIGNON2      ; Cold/warm message
        CALL      PRINT           ; Output string
CORW:
        CALL      RXA
        AND       %11011111       ; lower to uppercase
        CP        'C'
        JR        NZ, CHECKWARM
        RST       08H
        LD        A,$0D
        RST       08H
        LD        A,$0A
        RST       08H
COLDSTART:
        LD        A,'Y'           ; Set the BASIC STARTED flag
        LD        (basicStarted),A
        JP        coldb           ; Start BASIC COLD
CHECKWARM:
        CP        'W'
        JR        NZ, CORW
        RST       08H
        LD        A,$0D
        RST       08H
        LD        A,$0A
        RST       08H
        JP        warmb           ; Start BASIC WARM

;
;---------------
; BIT TIME DELAY
;---------------
;DELAY FOR ONE SERIAL BIT TIME
;ENTRY : HL = DELAY TIME
; NO REGISTERS MODIFIED
;
BITIME	PUSH	HL
	PUSH	DE
	LD	DE,0001H
BITIM1	SBC	HL,DE
	JP	NC,BITIM1
	POP	DE
	POP	HL
	RET
;
;------------------------------------------------------------------------------
PRINT:  LD       A,(HL)          ; Get character
        OR       A               ; Is it $00 ?
        RET      Z               ; Then RETurn on terminator
        RST      08H             ; Print it
        INC      HL              ; Next Character
        JR       PRINT           ; Continue until $00
        RET
;------------------------------------------------------------------------------

SIGNON1:	.BYTE   CL,CR,LF,"Z80 Southern Cross MSBasic",CR,LF
		.BYTE	"Based on work by Grant Searle.",CR,LF,0
SIGNON2:	.BYTE   CR,LF
		.BYTE   "Cold or warm start (C or W)? ",0
              
	.END

