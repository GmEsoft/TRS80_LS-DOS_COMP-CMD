;** Z-80(tm) DISASSEMBLER V1.02beta5 - (c) 2015 GmEsoft, All rights reserved. **
;
;	Fri May 13 21:57:20 2016
;
;	Disassembly of : COMP.CMD
;	Equates file   : LSDOSSVC.equ
;	Equates file   : COMP_DASM.equ
;	Screening file : COMP_DASM.scr

;	Version history:
;	Id	Name	Comment
;	200	2.0.0	Last known version from MISOSYS
;	201	2.0.1	Patch to support 256-sectors cylinders
;	202	2.0.2	Added help on parameters
;	203	2.0.3	Wait if differences

VERSION	EQU	203	;Version selector

$SVC    MACRO   #N
        LD      A,#N
        RST     0028H
        ENDM

@KEY	EQU	0001H
@DSP	EQU	0002H
@PRT	EQU	0006H
@KBD	EQU	0008H
@KEYIN	EQU	0009H
@DSPLY	EQU	000AH
@LOGOT	EQU	000CH
@PARAM	EQU	0011H
@ERROR	EQU	001AH
@CKDRV	EQU	0021H
@RDSEC	EQU	0031H
@OPEN	EQU	003BH
@POSN	EQU	0042H
@READ	EQU	0043H
@FSPEC	EQU	004EH
@GTDCT	EQU	0051H
@MUL16	EQU	005BH
@HIGH$	EQU	0064H
@FLAGS	EQU	0065H
@BREAK	EQU	0067H


	ORG	3000H
;*=*=*
;	COMP entry point
;*=*=*
COMP	DI
	LD	(SAVSP),SP
	PUSH	HL
	LD	HL,0000H
	$SVC	@BREAK
	EI
	$SVC	@FLAGS
	LD	HL,0000H
	LD	B,L
	BIT	1,(IY+2)
	JR	Z,NOCMNDR
	INC	B
NOCMNDR	$SVC	@HIGH$
	DEC	H
	LD	(HIMEM),HL
	LD	DE,ENDBUF
	OR	A
	SBC	HL,DE
	JP	C,ERNOMEM
	PUSH	IY
	POP	DE
	LD	HL,000AH
	ADD	HL,DE
	LD	(KFLAG),HL
	RES	0,(HL)
	LD	HL,0012H
	ADD	HL,DE
	LD	(SFLAG),HL
	POP	HL
	CALL	EXEC
EXITOK:
;---> v203: wait on diff
	IF	VERSION.GE.203
	LD	HL,0
PWAIT	EQU	$-2
	LD	A,H
	OR	L
	JR	Z,NOWAIT
	LD	HL,0
PDIFF	EQU	$-2
	LD	A,H
	OR	L
	CALL	NZ,KEY
NOWAIT:
	ENDIF
;<--- end v203
	LD	HL,0000H
	XOR	A
EXIT	LD	SP,0000H
SAVSP	EQU	$-2
	RET

;*=*=*
;	Error exit, return -1
;*=*=*
EXITERR	LD	HL,0FFFFH
	JR	EXIT

;*=*=*
;	Get command line parameters
;*=*=*
PARAM	$SVC	@PARAM
	RET

;*=*=*
;	Get DCT of drive A in IY
;*=*=*
GTDCT	PUSH	BC
	LD	C,A
	$SVC	@GTDCT
	POP	BC
	RET

;*=*=*
;	Check drive
;*=*=*
CKDRV	PUSH	BC
	LD	A,C
	$SVC	@CKDRV
	POP	BC
	RET

;*=*=*
;	Get filespec
;*=*=*
FSPEC	$SVC	@FSPEC
	RET

;*=*=*
;	Open file
;*=*=*
OPEN	PUSH	HL
	LD	HL,0000H
SFLAG	EQU	$-2
	SET	0,(HL)
	POP	HL
	$SVC	@OPEN
	RET

;*=*=*
;	Console line input
;*=*=*
KEYIN	LD	C,00H
	$SVC	@KEYIN
	RET

;*=*=*
;	Scan keyboard
;*=*=*
KBD	$SVC	@KBD
	RET

;*=*=*
;	Get char from keyboard
;*=*=*
KEY	$SVC	@KEY
	RET

	$SVC	@RDSEC
	RET

;*=*=*
;	Seek record
;*=*=*
POSN	$SVC	@POSN
	RET

;*=*=*
;	Display DOS error
;*=*=*
ERROR	PUSH	BC
	PUSH	AF
	PUSH	DE
	LD	A,0DH
	CALL	DSP
	POP	DE
	POP	AF
	OR	80H
	LD	C,A
	$SVC	@ERROR
	POP	BC
	RET

;*=*=*
;	Display string @HL (end 0D/03)
;*=*=*
DSPLY	$SVC	@DSPLY
	RET	Z
	JR	ERRC0

;*=*=*
;	Log message
;*=*=*
LOGOT	$SVC	@LOGOT
	RET

;*=*=*
;	Read record
;*=*=*
READ	$SVC	@READ
	RET

;*=*=*
;	Print char
;*=*=*
PRT	PUSH	BC
	LD	C,A
	$SVC	@PRT
	POP	BC
	RET	Z
	JR	ERRC0

;*=*=*
;	Multiply A and HL to HLA
;*=*=*
MUL16	PUSH	BC
	LD	C,A
	$SVC	@MUL16
	POP	BC
	RET

;*=*=*
;	Display char
;*=*=*
DSP	PUSH	BC
	LD	C,A
	$SVC	@DSP
	POP	BC
	RET

;*=*=*
;	Display long error msg and exit with error code in A
;*=*=*
ERR00	LD	L,A
	JR	$ERR

;*=*=*
;	Display short error msg and exit with error code in A
;*=*=*
ERRC0	LD	H,00H
	LD	L,A
	OR	0C0H
$ERR	LD	H,00H
	CALL	ERROR
	JP	EXIT

;*=*=*
;	Error not enough memory
;*=*=*
ERNOMEM	LD	HL,NOMEM$
	CALL	LOGOT
	JP	EXITERR

NOMEM$	DB	'Not enough memory available. ',0DH

;*=*=*
;	Execute compare
;*=*=*
EXEC	CALL	SKPBLK
	LD	(PARGS),HL
	LD	HL,TITLE$
	CALL	DSPLY
	LD	HL,(PARGS)
	DEC	HL
$EXEC0	INC	HL
	LD	A,(HL)
	CP	0EH
	JR	C,$EXEC1
	CP	28H
	JR	NZ,$EXEC0
	LD	DE,TPARAM$
	CALL	PARAM
	JP	NZ,PARERR
;---> v202: show help
	IF	VERSION.GE.202
	LD	HL,0
PHELP	EQU	$-2
	LD	A,H
	OR	L
	JP	NZ,HELP
	ENDIF
;<--- end v202
$EXEC1	LD	HL,(PARGS)
	LD	A,(HL)
	CP	3AH
	JP	Z,CMPDSK
	PUSH	HL
	LD	HL,(PREC)
	LD	BC,(PNUM)
	ADD	HL,BC
	JR	NC,$EXEC2
	LD	HL,0FFFFH
$EXEC2	LD	(PNUM),HL
	POP	HL
	CP	28H
	JR	NZ,$EXEC3
	XOR	A
$EXEC3	CP	0EH
	CALL	C,ASKFIL1
	PUSH	HL
	LD	DE,FSPEC1
	CALL	FSPEC
	POP	HL
	LD	DE,FCB1$
	CALL	FSPEC
	LD	(PARGS),HL
	LD	B,00H
	LD	HL,BUF1
	CALL	OPEN
	JP	NZ,ERR00
	LD	A,(LOGDR1$)
	PUSH	DE
	LD	DE,POSN14$
	LD	HL,FSPEC1
	CALL	CPYFSP
	POP	DE
	LD	BC,(PREC)
	CALL	POSN
	LD	HL,(PARGS)
	CALL	SKPBLK
	LD	A,(HL)
	CP	3AH
	JR	NZ,$EXEC5
$EXEC4	INC	HL
	LD	A,(HL)
	SUB	30H
	JR	C,$EXEC6
	CP	08H
	JR	NC,$EXEC6
	LD	HL,FSPEC1
	LD	DE,CMPDSK
	CALL	CPYFSP2
	INC	DE
	LD	A,0DH
	LD	(DE),A
	LD	HL,CMPDSK
	JR	$EXEC8

$EXEC5	CP	28H
	JR	NZ,$EXEC7
$EXEC6	XOR	A
$EXEC7	CP	0EH
	JR	NC,$EXEC8
	LD	HL,FSPEC2$
	CALL	ASKFIL
	LD	A,(HL)
	CP	3AH
	JR	Z,$EXEC4
$EXEC8	LD	DE,FSPEC2
	PUSH	HL
	CALL	FSPEC
	POP	HL
	LD	DE,CMPDSK
	CALL	FSPEC
	LD	B,00H
	LD	HL,CMPBUF
	CALL	OPEN
	JP	NZ,ERR00
	PUSH	DE
	LD	A,(LOGDR0$)
	LD	DE,POSN2$
	LD	HL,FSPEC2
	CALL	CPYFSP
	POP	DE
	LD	BC,(PREC)
	CALL	POSN
	LD	IX,FCB1$
$EXEC9	LD	HL,BUF1
	LD	(IX+4),H
	LD	(IX+3),L
$EXECA	LD	DE,FCB1$
	LD	BC,(NXREC1$)
	LD	HL,(PNUM)
	OR	A
	SBC	HL,BC
	JP	C,ENDREC
	CALL	READ
	JP	NZ,ERREAD2
	LD	BC,(NXREC1$)
	LD	A,(HIMEMH)
	CP	(IX+4)
	JP	Z,$EXECB
	INC	(IX+4)
	JR	$EXECA

$EXECB	LD	A,0FFH
	LD	(L36AD),A
$EXECC	LD	HL,(COUNTER)
	LD	A,H
	OR	L
	LD	HL,BUF1
	JR	NZ,$EXECG
$EXECD	LD	DE,CMPDSK
	LD	BC,(NXREC0$)
	PUSH	HL
	LD	HL,(PNUM)
	OR	A
	SBC	HL,BC
	POP	HL
	JR	C,ERREOF
	CALL	READ
	JP	NZ,ERREAD
	LD	DE,CMPBUF
$EXECE	LD	A,(DE)
	CP	(HL)
	JR	NZ,$EXECK
$EXECF	INC	HL
	INC	E
	JR	NZ,$EXECE
	CALL	KBSCAN
	LD	A,(HIMEMH)
	INC	A
	CP	H
	JP	NZ,$EXECD
	LD	A,(L36AD)
	OR	A
	JP	NZ,$EXEC9
	JP	ERREOF

$EXECG	LD	DE,CMPDSK
	LD	BC,(NXREC0$)
	PUSH	HL
	LD	HL,(PNUM)
	OR	A
	SBC	HL,BC
	POP	HL
	JR	C,ERREOF
	CALL	READ
	JP	NZ,ERREAD
	LD	DE,CMPBUF
$EXECH	LD	A,(DE)
	CP	(HL)
	JR	Z,$EXECJ
$EXECI	CALL	TSTINC
	INC	HL
	INC	E
	JR	NZ,$EXECH
	CALL	KBSCAN
	LD	A,(HIMEMH)
	INC	A
	CP	H
	JP	NZ,$EXECG
	LD	A,(L36AD)
	OR	A
	JP	NZ,$EXEC9
	JP	ERREOF

$EXECJ	CALL	DISCNTR
	JP	$EXECF

$EXECK	CALL	DISDIFF
	LD	BC,0000H
PALL	EQU	$-2
	LD	A,B
	OR	C
	JR	NZ,$EXECF
	JP	$EXECI

;*=*=*
;	Read error, disp counter and close file if EOF
;*=*=*
ERREAD	CP	1CH
	JR	Z,ERREOF
	CP	1DH
	JP	Z,ERREOF
	JP	ERR00

ERREOF	CALL	DISCNTR
	JP	ENDFILE

;*=*=*
;	Read error, ...?
;*=*=*
ERREAD2	CP	1CH
	JR	Z,ENDREC
	CP	1DH
	JR	Z,ENDREC
	JP	ERR00

ENDREC	XOR	A
	LD	(L36AD),A
	JP	$EXECC

;*=*=*
;	Display diff in files
;*=*=*
DISDIFF	CALL	TSTEOF
	JP	NZ,ERREOF
	CALL	CLRCNTR
	PUSH	DE
	PUSH	HL
	LD	A,(HL)
	LD	HL,VAL11$
	CALL	HEXAHL
	LD	HL,VAL12$
	LD	A,(DE)
	CALL	HEXAHL
	LD	A,E
	LD	HL,POSN13$
	CALL	HEXAHL
	LD	DE,(NXREC0$)
	DEC	DE
	LD	A,D
	LD	HL,POSN11$
	CALL	HEXAHL
	LD	A,E
	CALL	HEXAHL
	LD	HL,MISMAT$
	CALL	DISPRT
	POP	HL
	POP	DE
	RET

;*=*=*
;	Display and possibly print message
;*=*=*
DISPRT	CALL	KBSCAN
	PUSH	HL
	CALL	DSPLY
	POP	HL
	LD	DE,0000H
PPRINT	EQU	$-2
	LD	A,D
	OR	E
	RET	Z
$DISPR0	LD	A,(HL)
	CP	03H
	RET	Z
	PUSH	HL
	PUSH	AF
	CP	0AH
	JR	NZ,$DISPR1
	LD	A,0DH
$DISPR1	CP	0DH
	JR	Z,$DISPR2
	CP	20H
	JR	C,$DISPR3
$DISPR2	CALL	PRT
$DISPR3	POP	AF
	POP	HL
	CP	0DH
	RET	Z
	INC	HL
	JR	$DISPR0

;*=*=*
;	Test for end of file
;*=*=*
TSTEOF	PUSH	HL
	LD	BC,(NXREC0$)
	LD	HL,(LSREC1$)
	LD	A,H
	OR	L
	LD	A,01H
	JR	Z,BTSTEO3
	DEC	HL
	OR	A
	SBC	HL,BC
	JR	NC,BTSTEO1
	INC	L
	LD	A,01H
	JR	NZ,BTSTEO3
	JR	BTSTEO4

BTSTEO1	LD	HL,(LSREC0$)
	LD	A,L
	OR	H
	LD	A,02H
	JR	Z,BTSTEO3
	SBC	HL,BC
	JR	Z,BTSTEO5
BTSTEO2	XOR	A
BTSTEO3	POP	HL
	OR	A
	RET

BTSTEO4	LD	A,(LROFF1$)
	DEC	A
	CP	E
	LD	A,01H
	JR	NC,BTSTEO2
	JR	BTSTEO3

BTSTEO5	LD	A,(LROFF0$)
	DEC	A
	CP	E
	LD	A,02H
	JR	NC,BTSTEO2
	JR	BTSTEO3

;*=*=*
;	Scan keyboard for pause/break
;*=*=*
KBSCAN	LD	A,(0000H)
KFLAG	EQU	$-2
	RRCA
	JR	C,BRKHIT
	RRCA
	RET	NC
	CALL	BKBSCN2
	PUSH	DE
BKBSCN0	CALL	KBD
	OR	A
	JR	NZ,BKBSCN0
	POP	DE
BKBSCN1	PUSH	DE
	CALL	KEY
	POP	DE
	CP	01H
	JR	Z,BRKHIT
	CP	60H
	JR	Z,BKBSCN1
BKBSCN2	PUSH	HL
	LD	HL,(KFLAG)
	LD	A,(HL)
	AND	0F8H
	LD	(HL),A
	POP	HL
	RET

BRKHIT	CALL	KBD
	CALL	BKBSCN2
	JP	EXITERR

;*=*=*
;	Store A as hex @ HL
;*=*=*
HEXAHL	PUSH	AF
	RRA
	RRA
	RRA
	RRA
	CALL	HEXNHL
	POP	AF
HEXNHL	AND	0FH
	ADD	A,90H
	DAA
	ADC	A,40H
	DAA
	LD	(HL),A
	INC	HL
	RET

;*=*=*
;	Display counter
;*=*=*
DISCNTR	PUSH	HL
	PUSH	DE
	LD	DE,(COUNTER)
	LD	HL,0001H
	OR	A
	SBC	HL,DE
	JR	NC,$DISCN0
	LD	HL,NBYTES$
	CALL	DEC5HL
	LD	HL,P1D1E$
	CALL	DISPRT
$DISCN0	CALL	CLRCNTR
	POP	DE
	POP	HL
	RET

;*=*=*
;	Finish comparing files
;*=*=*
ENDFILE	LD	BC,000EH
	PUSH	BC
	LD	HL,POSN14$
	LD	DE,FILSC1$
	LDIR
	POP	BC
	LD	HL,POSN2$
	LD	DE,FILSC2$
	LDIR
	LD	DE,(LSREC1$)
	PUSH	DE
	LD	HL,FSECS1$
	CALL	DEC5HL
	POP	DE
	LD	A,D
	OR	E
	JR	NZ,$ENDFI1
	LD	HL,FEOF1$
	LD	B,0EH
$ENDFI0	LD	(HL),20H
	INC	HL
	DJNZ	$ENDFI0
	JR	$ENDFI2

$ENDFI1	LD	A,(LROFF1$)
	DEC	A
	LD	D,00H
	LD	E,A
	LD	HL,FEOF01$
	CALL	DEC5HL
$ENDFI2	LD	DE,(LSREC0$)
	PUSH	DE
	LD	HL,FSECS2$
	CALL	DEC5HL
	POP	DE
	LD	A,D
	OR	E
	JR	NZ,$ENDFI4
	LD	HL,FEOF2$
	LD	B,0EH
$ENDFI3	LD	(HL),20H
	INC	HL
	DJNZ	$ENDFI3
	JR	$ENDFI5

$ENDFI4	LD	A,(LROFF0$)
	DEC	A
	LD	D,00H
	LD	E,A
	LD	HL,FEOF02$
	CALL	DEC5HL
$ENDFI5	LD	HL,SECTRS$
	CALL	DISPRT
	JP	EXITOK

;*=*=*
;	Store DE as decimal @ HL
;*=*=*
DEC5HL	PUSH	BC
	PUSH	DE
	PUSH	IX
	PUSH	IY
	LD	C,00H
	PUSH	HL
	POP	IX
	EX	DE,HL
	LD	IY,POW10S
$DEC5H0	XOR	A
	LD	D,(IY+1)
	LD	E,(IY+0)
$DEC5H1	OR	A
	SBC	HL,DE
	JR	C,$DEC5H2
	INC	A
	JR	$DEC5H1

$DEC5H2	ADD	HL,DE
	ADD	A,30H
	LD	(IX+0),A
	INC	IY
	INC	IY
	LD	A,E
	DEC	A
	JR	Z,$DEC5H5
	BIT	0,C
	JR	NZ,$DEC5H3
	LD	A,(IX+0)
	CP	30H
	JR	NZ,$DEC5H3
	LD	(IX+0),20H
	JR	$DEC5H4

$DEC5H3	LD	C,01H
$DEC5H4	INC	IX
	JR	$DEC5H0

$DEC5H5	POP	IY
	POP	IX
	POP	DE
	POP	BC
	RET

POW10S	DW	2710H,03E8H,0064H,000AH
	DW	0001H

;*=*=*
;	Clear counter
;*=*=*
CLRCNTR	PUSH	HL
	LD	HL,0000H
	JR	STOCNTR

;*=*=*
;	Test for EOF then increment counter
;*=*=*
TSTINC	CALL	TSTEOF
	JP	NZ,ERREOF

;*=*=*
;	Increment counter
;*=*=*
INCCNTR	PUSH	HL
	LD	HL,(COUNTER)
	INC	HL
;---> v203: wait on diff
	IF	VERSION.GE.203
	LD	(PDIFF),HL
	ENDIF
;<--- end v203
STOCNTR	LD	(COUNTER),HL
	POP	HL
	RET

;*=*=*
;	Messages
;*=*=*
MISMAT$	DB	'Posn= X'''
POSN11$	DB	' '
POSN12$	DB	'   ,'
POSN13$	DB	'     '
POSN14$	DB	'               = X'''
VAL11$	DB	'  ,   '
POSN2$	DB	'               = X'''
VAL12$	DB	'  ',0DH
P1D1E$	DB	1DH,1EH
	DB	' '
NBYTES$	DB	'      bytes did not match.',0AH,0DH
SECTRS$	DB	0AH
FILSC1$	DB	'               contains '
FSECS1$	DB	'      sectors'
FEOF1$	DB	', EOF offset ='
FEOF01$	DB	'     ',0AH
FILSC2$	DB	'               contains '
FSECS2$	DB	'      sectors'
FEOF2$	DB	', EOF offset ='
FEOF02$	DB	'     ',0DH
ILLDRV$	DB	'Illegal drive number!',0AH,0DH
DIFDSK$	DB	'Disks are not the same type!',0AH,0DH
DRVCYL$	DB	'Drive '
DRVC1$	DB	'x contains'
NCYLS1$	DB	'      cylinders, Drive '
DRVC2$	DB	'x contains'
NCYLS2$	DB	'      cylinders',0AH,0DH
DIFF$	DB	0AH
	DB	'Cyl X'''
NCYL$	DB	'xx, Sec X'''
NSEC$	DB	'xx, Byte X'''
NBYTE$	DB	'xx, Drive '
DRV1$	DB	'x = X'''
VAL1$	DB	'xx, Drive '
DRV2$	DB	'x = X'''
VAL2$	DB	'xx',0DH
RDDRV$	DB	0FH,1DH
	DB	'Reading drive   :'
RDDRVN$	DB	'x, ',03H
CPDRV$	DB	0FH,1DH
	DB	'Comparing drive :'
CPDRVN$	DB	'x  ',03H
TRACK$	DB	'Track X'''
TRACKN$	DB	'xx''',0EH,03H
CMPLTD$	DB	0AH
	DB	'Disk compare completed.',0DH
PDRIVE0	DB	00H,00H,00H
PDRIVE1	DB	00H,00H,00H
DCT0	DB	00H,00H
DCT1	DB	00H,00H
DNSECS0	DB	00H,00H
DNSECS1	DB	00H,00H
CYLSEC	DB	00H,00H
ICYLSC0	DB	00H,00H
ICYLSC1	DB	00H,00H
BUFPTR	DB	00H,00H
PARGS	DB	00H,00H
HIMEM	DB	00H
HIMEMH	DB	00H
PCYL	DB	00H,00H
PSEC	DB	00H,00H
COUNTER	DB	00H,00H
PREC	DB	00H,00H
PNUM	DB	0FFH,0FFH
L36AD	DB	00H

;*=*=*
;	FCBs for file compare
;*=*=*
FCB0$	EQU	$			;FCB file 0
LOGDR0$	EQU	FCB0$+6			;Ending record byte offset/logical drive #
LROFF0$	EQU	FCB0$+8			;LROFF/Ending record byte offset
NXREC0$	EQU	FCB0$+10		;next rec #
LSREC0$	EQU	FCB0$+12		;ending rec #
FCB1$	EQU	$+20H			;FCB file 1
LOGDR1$	EQU	FCB1$+6			;Ending record byte offset
LROFF1$	EQU	FCB1$+8			;LROFF
NXREC1$	EQU	FCB1$+10		;next rec #
LSREC1$	EQU	FCB1$+12		;ending rec #

;*=*=*
;	Compare disks
;*=*=*
CMPDSK	LD	IX,PDRIVE0
	INC	HL
	LD	A,(HL)
	LD	(DRV1$),A
	LD	(DRVC1$),A
	LD	(RDDRVN$),A
	PUSH	HL
	CALL	OPNDRV
	POP	HL
	JP	NZ,ILLDRV
	LD	(DCT0),IY
	LD	IX,PDRIVE1
	INC	HL
	CALL	SKPBLK
	LD	A,(HL)
	CP	3AH
	JP	NZ,ILLDRV
	INC	HL
	LD	A,(HL)
	LD	(DRV2$),A
	LD	(DRVC2$),A
	LD	(CPDRVN$),A
	CALL	OPNDRV
	JP	NZ,ILLDRV
	LD	(DCT1),IY
	LD	IX,PDRIVE0
	LD	A,(IX+0)
	CP	(IX+3)
	JP	NZ,DIFDSK
	INC	A
	LD	E,A
	LD	A,(IX+1)
	CP	(IX+4)
	PUSH	AF
	PUSH	DE
	CALL	NZ,DISCYLS
	POP	DE
	POP	AF
	JR	C,$CMPDS0
	LD	A,(IX+4)
$CMPDS0	INC	A
	LD	D,A
	LD	A,(PCYL)
	CP	D
	JP	NC,CMPLTD
	NEG
	ADD	A,D
	CALL	MULAE
	LD	DE,(PSEC)
	OR	A
	SBC	HL,DE
	LD	(DNSECS0),HL
	LD	(DNSECS1),HL
	LD	DE,(PNUM)
	OR	A
	SBC	HL,DE
	JR	C,$CMPDS1
	LD	(DNSECS0),DE
	LD	(DNSECS1),DE
$CMPDS1	LD	A,(PCYL)
	LD	D,A
	LD	A,(PSEC)
	LD	E,A
	LD	(ICYLSC0),DE
	LD	(ICYLSC1),DE

;	Main loop
$CMPDS2	LD	HL,DSRDDRV
	LD	(XRDCPDV),HL
	LD	HL,BUF1
	LD	IX,PDRIVE0		;1st drive's geometry
	LD	IY,(DCT0)		;1st drive's dct
	LD	BC,(DNSECS0)		;total remaining sectors loop counter 1st drive
	LD	DE,(ICYLSC0)		;sec/cyl 1st drive

;	Reading loop
$CMPDS3	LD	A,B			;loop counter == 0 ?
	OR	C
	JR	Z,$CMPDS4		;exit loop if yes
	CALL	NXSCTCY			;read sector and incr sec/cyl
	JP	NZ,ERRC0
	DEC	BC			;decrement loop counter
	LD	A,(HIMEMH)		;check if himem reached
	CP	H			;
	JR	Z,$CMPDS4		;jump if yes
	INC	H			;else next page
	JR	$CMPDS3			;and loop again

;	Finished reading
$CMPDS4	LD	(DNSECS0),BC		;save loop counter
	LD	(ICYLSC0),DE		;save current cyl/sec
	LD	IY,(DCT1)		;2nd drive's dct
	LD	IX,PDRIVE1		;2nd drive's geometry
	LD	BC,(DNSECS1)		;2nd drive's total remaining sectors
	LD	HL,BUF1			;1st drive's 1st read sector buffer
	LD	(BUFPTR),HL		;to pointer
	LD	HL,(COUNTER)		;diff counter
	LD	A,H
	OR	L
	JR	NZ,$CMPDS8		;jump if not null
	LD	HL,DSCPDRV		;ptr to "comparing drive" display subroutine
	LD	(XRDCPDV),HL
;	Loop to compare sectors
$CMPDS5	LD	A,B			;remaining sectors?
	OR	C
	JR	Z,CMPLTD		;jump if no => completed
	LD	HL,CMPBUF		;compare buffer
	LD	DE,(ICYLSC1)		;get current 2nd drive's cyl/sec
	LD	(CYLSEC),DE		;save
	CALL	NXSCTCY			;read sector and bump cyl/sec
	LD	(ICYLSC1),DE		;save
	JP	NZ,ERRC0		;exit if error
	DEC	BC			;decrement remaining sectors
	LD	DE,(BUFPTR)		;prepare to compare data
;	Loop to compare sector's bytes
$CMPDS6	LD	A,(DE)			;compare bytes
	CP	(HL)
	JR	NZ,FNDDIFF		;jump if diff found
NXTBYTE	INC	DE			;bump ptrs
	INC	L			;
	JR	NZ,$CMPDS6		;loop until sector done
	LD	(BUFPTR),DE		;save buffer ptr for next sector
	LD	A,(HIMEMH)		;check if HIMEM reached
	INC	A
	CP	D
	JR	NZ,$CMPDS5		;loop for next sector compare if not
$CMPDS7	LD	(DNSECS1),BC		;save 2nd drive's remaining sec ctr
	JP	$CMPDS2			;continue main loop

	LD	HL,DSCPDRV		;location not reached ???
	LD	(XRDCPDV),HL		;idem
;	We get here if diff counter not null ...
$CMPDS8	LD	A,B			;remaining sectors?
	OR	C
	JR	Z,CMPLTD		;exit if no
	LD	HL,CMPBUF
	LD	DE,(ICYLSC1)
	LD	(CYLSEC),DE
	CALL	NXSCTCY
	JP	NZ,ERRC0
	LD	(ICYLSC1),DE
	DEC	BC
	LD	DE,(BUFPTR)
$CMPDS9	LD	A,(DE)
	CP	(HL)
	JR	Z,DISNEXT
ENDSEC	CALL	INCCNTR
	INC	DE
	INC	L
	JR	NZ,$CMPDS9
	LD	(BUFPTR),DE
	LD	A,(HIMEMH)
	INC	A
	CP	D
	JR	NZ,$CMPDS8
	JR	$CMPDS7

CMPLTD	CALL	DISCNTR
	LD	HL,CMPLTD$
	CALL	DSPLY
	JP	EXITOK

FNDDIFF	PUSH	BC
	PUSH	DE
	PUSH	HL
	CALL	DISCMP
	LD	HL,(PALL)
	LD	A,H
	OR	L
	POP	HL
	POP	DE
	POP	BC
	JP	NZ,NXTBYTE
	JP	ENDSEC

DISNEXT	CALL	DISCNTR
	JP	NXTBYTE

;*=*=*
;	Read sector, Increment sector/cylinder & update display
;*=*=*
NXSCTCY	PUSH	HL
	PUSH	BC
	PUSH	DE
	CALL	KBSCAN
	EX	(SP),HL
	LD	A,L
	INC	L
	CP	(IX+0)
	JR	NZ,$NXSCT0
	CALL	DSRDDRV
XRDCPDV	EQU	$-2
	LD	L,00H
	INC	H
$NXSCT0	EX	(SP),HL
	LD	C,(IX+2)
	DI
	CALL	CALLDRV
	EI
	JR	Z,$NXSCT1
	CP	06H
$NXSCT1	POP	DE
	POP	BC
	POP	HL
	RET

;*=*=*
;	Call driver from DCT
;*=*=*
CALLDRV	LD	B,09H
	JP	(IY)

;*=*=*
;	Display cyl/sec as hex
;*=*=*
DISCYLS	LD	A,(IX+1)
	INC	A
	LD	D,00H
	LD	E,A
	LD	HL,NCYLS1$
	CALL	DEC5HL
	LD	A,(IX+4)
	INC	A
	LD	E,A
	LD	HL,NCYLS2$
	CALL	DEC5HL
	LD	HL,DRVCYL$
	JP	DISPRT

;*=*=*
;	Error: not same disk types
;*=*=*
DIFDSK	LD	HL,DIFDSK$

;*=*=*
;	Display error and exit
;*=*=*
DISPERR	CALL	DSPLY
	JP	EXITERR

;*=*=*
;	Error: illegal drive
;*=*=*
ILLDRV	LD	HL,ILLDRV$
	JR	DISPERR

;*=*=*
;	Display difference
;*=*=*
DISCMP	PUSH	DE
	PUSH	BC
	PUSH	HL
	CALL	KBSCAN
	LD	A,(DE)
	LD	HL,VAL1$
	CALL	HEXAHL
	LD	A,E
	LD	HL,NBYTE$
	CALL	HEXAHL
	LD	DE,(CYLSEC)
	LD	A,D
	LD	HL,NCYL$
	CALL	HEXAHL
	LD	A,E
	LD	HL,NSEC$
	CALL	HEXAHL
	POP	HL
	PUSH	HL
	LD	A,(HL)
	LD	HL,VAL2$
	CALL	HEXAHL
	LD	HL,DIFF$
	CALL	DISPRT
	POP	HL
	POP	BC
	POP	DE
	RET

;*=*=*
;	Store track number in D as hex
;*=*=*
HEXTRKN	LD	HL,TRACKN$
	LD	A,D
	CALL	HEXAHL
	RET

;*=*=*
;	Display reading drive
;*=*=*
DSRDDRV	PUSH	HL
	PUSH	DE
	CALL	HEXTRKN
	LD	HL,RDDRV$
	CALL	DSPLY
	LD	HL,TRACK$
	CALL	DSPLY
	POP	DE
	POP	HL
	RET

;*=*=*
;	Display comparing drive
;*=*=*
DSCPDRV	PUSH	HL
	PUSH	DE
	CALL	HEXTRKN
	LD	HL,CPDRV$
	CALL	DSPLY
	LD	HL,TRACK$
	CALL	DSPLY
	POP	DE
	POP	HL
	RET

;*=*=*
;	Buffers, from here at page boundaries
;*=*=*
CMPBUF	EQU	$-1<-8+1<+8	;compare buffer
BUF1	EQU	CMPBUF+100H	;read buffers


;*=*=*
;	Multiply A(=cyls) with E(=secs)
;	v200: does not work if E==256
;	v201: fixed to work if E==256
;*=*=*
MULAE	LD	H,00H
	LD	L,E
;---> begin v201 fix
	IF	VERSION.GE.201
	DEC	L		;0 -> 100H
	INC	HL
	ENDIF
;<--- end v201 fix
	CALL	MUL16
	LD	H,L
	LD	L,A
	RET


;*=*=*
;	Ask filespec 1 or 2
;*=*=*
ASKFIL1	LD	HL,FSPEC1$
;CMPBUF	EQU	$-2

;*=*=*
;	Ask filespec
;*=*=*
ASKFIL	CALL	DSPLY
	LD	HL,L3911
	LD	B,17H
	CALL	KEYIN
	RET	NC
	JP	EXITERR

L3911	DS	0019H		;Filespec buffer

;*=*=*
;	Skip blanks @ HL
;*=*=*
SKPBLK	LD	A,(HL)
	CP	20H
	RET	NZ
	INC	HL
	JR	SKPBLK

;*=*=*
;	Error: bad parameter(s)
;*=*=*
PARERR	LD	HL,PARERR$
	CALL	DSPLY
	JP	EXITERR

PARERR$	DB	'Parameter Error!',0AH,0DH


;*=*=*
;	Title and prompt
;*=*=*
TITLE$	DB	'COMP - Version '
	IFEQ	VERSION,200
	DB	'2.0.0'
	ENDIF
	IFEQ	VERSION,201
	DB	'2.0.1'
	ENDIF
	IFEQ	VERSION,202
	DB	'2.0.2'
	ENDIF
	IFEQ	VERSION,203
	DB	'2.0.3'
	ENDIF
	DB	' - File or Disk Compare program',0AH
	DB	'Copyright 1982/83/84/88 MISOSYS, Inc., All Rights Reserved.',0AH
	IF	VERSION.GT.200
	DB	'Enhanced by GmEsoft'
;---> v202: show help
	IF	VERSION.GE.202
	DB	' -- COMP (Help) for help on usage'
	ENDIF
;<--- end v202
	DB	0AH
	ENDIF
	DB	0DH
FSPEC1$	DB	0AH
	DB	'Filespec 1 ? ',03H
FSPEC2$	DB	0AH
	DB	'Filespec 2 ? ',03H

;---> v202: show help
	IF	VERSION.GE.202

HELP$	DB	'COMP filespec1[:d1] [filespec2][:d2] [(parameters)]',0AH
	DB	'    Compare files',0AH
	DB	'COMP :d1 :d2 [(parameters)]',0AH
	DB	'    Compare disks',0AH
	DB	'Optional parameters:',0AH
	DB	'    Rec  (files) Starting record number',0AH
	DB	'    Cyl  (disks) Starting cylinder number',0AH
	DB	'    Sec  (disks) Starting sector number',0AH
	DB	'    Num  Number of records/sectors to compare',0AH
	DB	'    All  Output all differences',0AH
	DB	'    P    Output to Printer',0AH
;---> v203: wait if diff
	IF	VERSION.GE.203
	DB	'    Wait Wait if differences found',0AH
	ENDIF
;<--- end v203
	DB	03H
;*=*=*
;	Show help
;*=*=*
HELP	LD	HL,HELP$	;help text
	CALL	DSPLY		;display
	RET			;successful exit

	ENDIF
;<--- end v202

;*=*=*
;	Parameters table
;*=*=*
TPARAM$	DB	'CYL   '	;starting cylinder
	DW	PCYL
	DB	'C     '
	DW	PCYL
	DB	'SEC   '	;starting sector
	DW	PSEC
	DB	'S     '
	DW	PSEC
	DB	'NUM   '	;number of sectors/records
	DW	PNUM
	DB	'N     '
	DW	PNUM
	DB	'REC   '	;starting record
	DW	PREC
	DB	'R     '
	DW	PREC
	DB	'ALL   '	;output all mismatching bytes
	DW	PALL
	DB	'A     '
	DW	PALL
	DB	'P     '	;output to printer
	DW	PPRINT
;---> v202: show help
	IF	VERSION.GE.202
	DB	'HELP  '	;show help screen
	DW	PHELP
	DB	'H     '
	DW	PHELP
	ENDIF
;<--- end v202
;---> v203: wait if diff
	IF	VERSION.GE.203
	DB	'WAIT  '	;wait if diff
	DW	PWAIT
	DB	'W     '
	DW	PWAIT
	ENDIF
;<--- end v203
	DB	00H,00H

;*=*=*
;	Copy filespec w/o password
;*=*=*
CPYFSP	ADD	A,30H
	LD	C,A
	LD	B,0CH
$CPYFS0	LD	A,(HL)
	CP	21H		;'!' ?
	JR	Z,$CPYFS1	;copy if yes
	CP	2FH		;<'/' ?
	JR	C,$CPYFS2	;end if yes
	CP	3AH		;':' ?
	JR	Z,$CPYFS2	;end if yes
$CPYFS1	LD	(DE),A
	INC	HL
	INC	DE
	DJNZ	$CPYFS0
$CPYFS2	LD	A,3AH
	LD	(DE),A
	INC	DE
	LD	A,C
	LD	(DE),A
	RET

;*=*=*
;	Copy filespec with password
;*=*=*
CPYFSP2	ADD	A,30H
	LD	C,A
	LD	B,13H
$CPYFS3	LD	A,(HL)
	CP	21H		;'!'
	JR	Z,$CPYFS4	;copy if yes
	CP	2EH		;'.'
	JR	Z,$CPYFS4	;copy if yes
	CP	2FH		;<'/'
	JR	C,$CPYFS5	;end if yes
	CP	3AH		;':'
	JR	Z,$CPYFS5	;end if yes
$CPYFS4	LD	(DE),A
	INC	HL
	INC	DE
	DJNZ	$CPYFS3
$CPYFS5	LD	A,3AH
	LD	(DE),A
	INC	DE
	LD	A,C
	LD	(DE),A
	RET

ERRNDRV	OR	0FFH
	RET

;*=*=*
;	Open drive '0' to '7'
;*=*=*
OPNDRV	SUB	30H
	RET	C
	CP	08H
	JR	NC,ERRNDRV
	LD	(IX+2),A
	LD	C,A
	PUSH	HL
	PUSH	DE
	PUSH	BC
	CALL	GTDCT
	POP	BC
	LD	A,C
	CALL	CKDRV
	POP	DE
	POP	HL
	RET	NZ
	LD	H,(IY+6)
	INC	H
	LD	A,(IY+7)
	AND	1FH
	INC	A
	BIT	3,(IY+3)
	JR	Z,$OPNDR2
	LD	D,A
	LD	A,(IY+7)
	RLCA
	RLCA
	RLCA
	AND	07H
	INC	A
	LD	E,A
	XOR	A
	LD	B,08H
$OPNDR0	ADD	A,A
	SLA	E
	JR	NC,$OPNDR1
	ADD	A,D
$OPNDR1	DJNZ	$OPNDR0
	JR	$OPNDR3

$OPNDR2	BIT	5,(IY+4)
	JR	Z,$OPNDR3
	ADD	A,A
$OPNDR3	DEC	A
	LD	(IX+0),A
	DEC	H
	LD	(IX+1),H
	LD	E,00H
	LD	A,(PCYL)
	LD	D,A
	INC	H
	CP	H
	JR	C,$OPNDR4
	JP	PARERR

$OPNDR4	LD	B,06H
	JP	(IY)

;*=*=*
;	Buffers
;*=*=*
;BUF1	EQU	3A00H
FSPEC1	DS	0020H
FSPEC2	DS	0020H
	DS	-$&0FFH
ENDBUF	EQU	$

	END	COMP

