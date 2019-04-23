; command response R1
; 0x00 ok
; or bitfield
; 0x01 idle state
; 0x02 erase reset
; 0x04 illegal command
; 0x08 command crc error
; 0x10 erase sequence error
; 0x20 address error
; 0x40 parameter error
; 0x80 timeout (other bits meaningless)
;
; packet token
; 0xFF none yet
; 0xFE ok
; or bitfield
; 0x01 error
; 0x02 controller error
; 0x04 media ecc failed
; 0x08 out of range
; 0x10 card is locked

CMD0	EQU 040h |  0 ; resets the card
CMD9	EQU 040h |  9 ; read CSD
CMD10	EQU 040h | 10 ; read CID
CMD16	EQU 040h | 16 ; set R/W block
CMD17	EQU 040h | 17 ; read block
CMD24	EQU 040h | 24 ; write block
CMD55	EQU 040h | 55 ; next command is ACMDxx
ACMD41	EQU 040h | 41 ; send host capacity support, init card

SD_ON:	DB 3Eh
SD_OFF:	XRA A
	STA 0F700h
SD_FIN:	MVI A,0FFh
SD_PUT:	PUSH H
	LXI H,0F701h
	MOV M,A
	RLC
	MOV M,A
	RLC
	MOV M,A
	RLC
	MOV M,A
	RLC
	MOV M,A
	RLC
	MOV M,A
	RLC
	MOV M,A
	RLC
	MOV M,A
POPHRET:POP H
	RET

SD_GET:	PUSH H
	LXI H,0F701h
	MVI A,0FFh
	MOV M,A
	MOV M,A
	MOV M,A
	MOV M,A
	MOV M,A
	MOV M,A
	MOV M,A
	MOV M,A
	MOV A,M
	POP H
	RET

SD_CMD:	LXI H,0
SD_CMDW:LXI D,0
SD_CMDD:CALL SD_FIN
	MOV A,C
	CALL SD_PUT
	MOV A,D
	CALL SD_PUT
	MOV A,E
	CALL SD_PUT
	MOV A,H
	CALL SD_PUT
	MOV A,L
	CALL SD_PUT
	MVI A,95h
	CALL SD_PUT
	LXI D,8080h
SD_WAIT:LXI H,20000
SDW_L1:	CALL SD_GET
	MOV C,A
	SUB D
	CMP E
	MOV A,C
	RNC
	DCX H
	MOV A,H
	ORA L
	JNZ SDW_L1
	SUI 1
	RET

SD_INIT:CALL SD_OFF
	MVI B,10h
	CALL SD_FIN
	DCR B
	JNZ $-4
	CALL SD_ON
	MVI C,CMD0
	CALL SD_CMD
	CPI 1
	RNZ
SDI_L1:	MVI C,CMD55
	CALL SD_CMD
	ANI 0FEh
	RNZ
	MVI C,ACMD41
	CALL SD_CMD
	CPI 1
	JZ SDI_L1
	ORA A
	RET

SD_READ:PUSH H
	PUSH D
	PUSH B
	LXI D,0FFh
	CALL SD_WAIT
	POP B
	POP H
	JC POPHRET
	MOV A,C
	DAD H
	ADC A
	MOV D,A
	MOV E,H
	MOV H,L
	MVI L,0
	MVI C,CMD17
	CALL SD_CMDD
	JC POPHRET
	LXI D,0FF01h
	CALL SD_WAIT
	POP H
	CPI 0FEh
	RNZ
	MVI B,0
SDR_L1:	CALL SD_GET
	MOV M,A
	INX H
        CALL SD_GET
	MOV M,A
	INX H
	DCR B
	JNZ SDR_L1
	RET
