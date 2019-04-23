 		DEVICE	ZXSPECTRUM48
; ---------------------------------------------------------------[Rev.20121009]
; U9EP3C Loader Version 0.06 By MVV
; -----------------------------------------------------------------------------
; V0.01 Rev.20110212	первая версия
; V0.06 Rev.20120910	96K ROM грузится из M25P40, FAT16 loader отключен

; На будущее: В память с CD/MMC карты грузится файл u9ldr и запускается.
; u9ldr представляет собой BIOS, проверяет, настраивает, загружает файлы системы

		ORG #0000
StartProg:
		DI
		LD SP,#7FFE

		LD A,%00000001	; Bit2 = 0:Loader ON, 1:Loader OFF; Bit1 = 0:SRAM<->CPU0, 1:SRAM<->GS; Bit0 = 0:TDA1543, 1:M25P40
		OUT (#01),A

; -----------------------------------------------------------------------------
; SPI autoloader
; -----------------------------------------------------------------------------
		CALL SPI_START
		LD D,%00000011	; Command = READ
		CALL SPI_W

		LD D,#06	; Address = #060000
		CALL SPI_W
		LD D,#00
		CALL SPI_W
		LD D,#00
		CALL SPI_W
		LD HL,#8000
SPI_LOADER1	CALL SPI_R
		LD (HL),A
		INC HL
		LD A,L
		OR H
		JR NZ,SPI_LOADER1
		
		LD A,%00000111	; Bit2 = 0:Loader ON, 1:Loader OFF; Bit1 = 0:SRAM<->CPU0, 1:SRAM<->GS; Bit0 = 0:TDA1543, 1:M25P40
		OUT (#01),A
		LD A,%11111111	; Маска порта #DFFD по AND
		OUT (#00),A
		LD A,%10000000
		LD BC,#DFFD
		OUT (C),A
			
		LD A,%00000000	; открываем страницу ОЗУ
		LD BC,#7FFD
		OUT (C),A
		LD HL,#C000
SPI_LOADER2	CALL SPI_R
		LD (HL),A
		INC HL
		LD A,L
		OR H
		JR NZ,SPI_LOADER2

		LD A,%00000001	; открываем страницу ОЗУ
		LD BC,#7FFD
		OUT (C),A
		LD HL,#C000
SPI_LOADER3	CALL SPI_R
		LD (HL),A
		INC HL
		LD A,L
		OR H
		JR NZ,SPI_LOADER3
		
		LD A,%00000010	; открываем страницу ОЗУ
		LD BC,#7FFD
		OUT (C),A
		LD HL,#C000
SPI_LOADER4	CALL SPI_R
		LD (HL),A
		INC HL
		LD A,L
		OR H
		JR NZ,SPI_LOADER4

		LD A,%00000011	; открываем страницу ОЗУ
		LD BC,#7FFD
		OUT (C),A
		LD HL,#C000
SPI_LOADER5	CALL SPI_R
		LD (HL),A
		INC HL
		LD A,L
		OR H
		JR NZ,SPI_LOADER5
		
		CALL SPI_END

		XOR A
		LD BC,#7FFD
		OUT (C),A
		LD B,#DF
		OUT (C),A
		LD A,%00011111	; Маска порта #DFFD (разрешаем 4MB)
		OUT (#00),A
		LD A,%00000110	; Bit2 = 0:Loader ON, 1:Loader OFF; Bit1 = 0:SRAM<->CPU0, 1:SRAM<->GS; Bit0 = 0:TDA1543, 1:M25P40
		OUT (#01),A

; -----------------------------------------------------------------------------
; FAT16 loader
; -----------------------------------------------------------------------------
; SD_LOADER	CALL COM_SD
		; DB 0
		; CP 0
		; JP NZ,ERR

		; LD HL,#8000
		; LD BC,#0000
		; LD DE,#0000
		; CALL COM_SD
		; DB 2		; читаем MBR
		; LD A,(#81C6)
		; PUSH AF
		; LD E,A
		; LD D,0
		; LD BC,#0000
		; LD HL,#8000
		; CALL COM_SD
		; DB 2		; читаем BOOT RECORD на логическом разделе
		; LD A,(#800E)
		; LD C,A
		; LD HL,(#8016)	; читаем размер FAT-каталога
		; ADD HL,HL	; умножаем на два
		; LD B,0
		; ADD HL,BC	; прибавляем размер Reserved sectors
		; LD C,#20
		; ADD HL,BC	; прибавляем константу из расчета "два каталога FAT" и "размер сектора = 512 байт".
		; POP AF
		; LD C,A
		
		; ADD HL,BC	; прибавляем смещение между физическими и логическими секторами
		; PUSH HL
		; EX DE,HL
		; LD A,%00000000	; открываем страницу ОЗУ
		; LD BC,#7FFD
		; OUT (C),A
		; LD HL,#C000
		; LD BC,#0000
		; LD A,#20
		; CALL COM_SD
		; DB 3		; читаем первые 16K
		; CP 0
		; JR NZ,ERR

		; POP HL
		; LD DE,#0020
		; ADD HL,DE
		; PUSH HL
		; EX DE,HL	; номер сектора + 20h
		; LD A,%00000001	; открываем страницу ОЗУ
		; LD BC,#7FFD
		; OUT (C),A
		; LD HL,#C000
		; LD BC,#0000    
		; LD A,#20
		; CALL COM_SD
		; DB 3    	; читаем вторую половину
		; CP 0
		; JR NZ,ERR

		; POP HL
		; LD DE,#0020
		; ADD HL,DE
		; PUSH HL
		; EX DE,HL	; номер сектора + 20h
		; LD A,%00000010	; открываем страницу ОЗУ
		; LD BC,#7FFD
		; OUT (C),A
		; LD HL,#C000
		; LD BC,#0000    
		; LD A,#20
		; CALL COM_SD
		; DB 3    	; читаем вторую половину
		; CP 0
		; JR NZ,ERR

		; POP HL
		; LD DE,#0020
		; ADD HL,DE
		; PUSH HL
		; EX DE,HL	; номер сектора + 20h
		; LD A,%00000011	; открываем страницу ОЗУ
		; LD BC,#7FFD
		; OUT (C),A
		; LD HL,#C000
		; LD BC,#0000    
		; LD A,#20
		; CALL COM_SD
		; DB 3    	; читаем вторую половину
		; CP 0
		; JR NZ,ERR

		; XOR A
		; LD BC,#7FFD
		; OUT (C),A
		; LD B,#DF
		; OUT (C),A
		; LD A,%00011111	; Маска порта #DFFD (разрешаем 4MB)
		; OUT (#00),A
		; JP RTC_INIT
		
; ERR		LD A,#02	; ошибка		
		; OUT (#FE),A
		; JP SD_LOADER
		
; -----------------------------------------------------------------------------
; I2C PCF8583 to MC14818 loader
; -----------------------------------------------------------------------------
RTC_INIT	LD BC,#0000
		LD HL,#8000
		CALL I2C_GET

		LD A,#80
		LD BC,#EFF7
		OUT(C),A

; REGISTER B
		LD A,#0B
		LD B,#DF
		OUT (C),A
		LD A,#82
		LD B,#BF
		OUT (C),A
; SECONDS
		LD A,#00
		LD B,#DF
		OUT (C),A
		LD A,(#8002)
		LD B,#BF
		OUT (C),A
; MINUTES		
		LD A,#02
		LD B,#DF
		OUT (C),A
		LD A,(#8003)
		LD B,#BF
		OUT (C),A
; HOURS		
		LD A,#04
		LD B,#DF
		OUT (C),A
		LD A,(#8004)
		AND #3F
		LD B,#BF
		OUT (C),A
; DAY OF THE WEEK		
		LD A,#06
		LD B,#DF
		OUT (C),A
		LD A,(#8006)
		AND #E0
		RLCA
		RLCA
		RLCA
		INC A
		LD B,#BF
		OUT (C),A
; DATE OF THE MONTH
		LD A,#07
		LD B,#DF
		OUT (C),A
		LD A,(#8005)
		AND #3F
		LD B,#BF
		OUT (C),A
; MONTH
		LD A,#08
		LD B,#DF
		OUT (C),A
		LD A,(#8006)
		AND #1F
		LD B,#BF
		OUT (C),A
; YEAR
		LD A,#09
		LD B,#DF
		OUT (C),A
		LD A,(#8005)
		AND #C0
		RLCA
		RLCA
		LD HL,#8010	; ячейка для хранения года (8 бит)
		ADD A,(HL)	; год из PCF + поправка из ячейки
		LD B,#BF
		OUT (C),A
; REGISTER B
		LD A,#0B
		LD B,#DF
		OUT (C),A
		LD A,#02
		LD B,#BF
		OUT (C),A

		LD A,#00
		LD BC,#EFF7
		OUT(C),A

;------------------------------------------------------------------------------
		LD SP,#FFFF
		JP #0000	; Запуск системы

; -----------------------------------------------------------------------------
; SD Driver
; -----------------------------------------------------------------------------
; P_DATA		EQU #57
; P_CONF		EQU #77

; CMD_09		EQU #49		;SEND_CSD
; CMD_10		EQU #4A		;SEND_CID
; CMD_12		EQU #4C		;STOP_TRANSMISSION
; CMD_17		EQU #51		;READ_SINGLE_BLOCK
; CMD_18		EQU #52		;READ_MULTIPLE_BLOCK
; CMD_24		EQU #58		;WRITE_BLOCK
; CMD_25		EQU #59		;WRITE_MULTIPLE_BLOCK
; CMD_55		EQU #77		;APP_CMD
; CMD_58		EQU #7A		;READ_OCR
; CMD_59		EQU #7B		;CRC_ON_OFF
; ACMD_41		EQU #69		;SD_SEND_OP_COND

; Sd_init		EQU 0
; Sd__off		EQU 1
; Rdsingl		EQU 2
; Rdmulti		EQU 3
; Wrsingl		EQU 4
; Wrmulti		EQU 5

; COM_SD		EX AF,AF'
		; EX (SP),HL
		; LD A,(HL)
		; INC HL
		; EX (SP),HL
		; ADD A,A
		; PUSH HL
		; LD HL,TABLSDZ
		; ADD A,L
		; LD L,A
		; LD A,H
		; ADC A,0
		; LD H,A
		; LD A,(HL)
		; INC HL
		; LD H,(HL)
		; LD L,A
		; EX AF,AF'
		; EX (SP),HL
		; RET

; TABLSDZ		DW SD_INIT	; 0 параметров не требует, на выходе A
				; ; смотри выше первые 2 значения
		; DW SD__OFF	; 1 просто вырубает питание карты
		; DW RDSINGL	; 2
		; DW RDMULTI	; 3
		; DW WRSINGL	; 4
		; DW WRMULTI	; 5

; SD_INIT		CALL CS_HIGH
		; LD BC,P_DATA
		; LD DE,#10FF
		; OUT (C),E
		; DEC D
		; JR NZ,$-3
		; XOR A
		; EX AF,AF'
; ZAW001		LD HL,CMD00
		; CALL OUTCOM
		; CALL IN_OOUT
		; EX AF,AF'
		; DEC A
		; JR Z,ZAW003
		; EX AF,AF'
		; DEC A
		; JR NZ,ZAW001
		; LD HL,CMD08
		; CALL OUTCOM
		; CALL IN_OOUT
		; IN H,(C)
		; NOP
		; IN H,(C)
		; NOP
		; IN H,(C)
		; NOP
		; IN H,(C)
		; LD HL,0
		; BIT 2,A
		; JR NZ,ZAW006
		; LD H,#40
; ZAW006		LD A,CMD_55
		; CALL OUT_COM
		; CALL IN_OOUT
		; LD A,ACMD_41
		; OUT (C),A
		; NOP
		; OUT (C),H
		; NOP
		; OUT (C),L
		; NOP
		; OUT (C),L
		; NOP
		; OUT (C),L
		; LD A,#FF
		; OUT (C),A
		; CALL IN_OOUT
		; AND A
		; JR NZ,ZAW006
; ZAW004		LD A,CMD_59
		; CALL OUT_COM
		; CALL IN_OOUT
		; AND A
		; JR NZ,ZAW004
; ZAW005		LD HL,CMD16
		; CALL OUTCOM
		; CALL IN_OOUT
		; AND A
		; JR NZ,ZAW005

; CS_HIGH		PUSH AF
		; LD A,3
		; OUT (P_CONF),A
		; XOR A
		; OUT (P_DATA),A
		; POP AF
		; RET

; ZAW003		CALL SD__OFF
		; INC A
		; RET

; SD__OFF		XOR A
		; OUT (P_CONF),A
		; OUT (P_DATA),A
		; RET

; CS__LOW		PUSH AF
		; LD A,1
		; OUT (P_CONF),A
		; POP AF
		; RET

; OUTCOM		CALL CS__LOW
		; PUSH BC
		; LD BC,#0600+P_DATA
		; OTIR
		; POP BC
		; RET

; OUT_COM		PUSH BC
		; CALL CS__LOW
		; LD BC,P_DATA
		; OUT (C),A
		; XOR A
		; OUT (C),A
		; NOP
		; OUT (C),A
		; NOP
		; OUT (C),A
		; NOP
		; OUT (C),A
		; DEC A
		; OUT (C),A
		; POP BC
		; RET

; SECM200		PUSH HL
		; PUSH DE
		; PUSH BC
		; PUSH AF
		; PUSH BC

		; LD A,CMD_58
		; LD BC,P_DATA
		; CALL OUT_COM
		; CALL IN_OOUT
		; IN A,(C)
		; NOP
		; IN H,(C)
		; NOP
		; IN H,(C)
		; NOP
		; IN H,(C)
		
		; BIT 6,A
		; POP HL
		; JR NZ,SECN200
		; EX DE,HL
		; ADD HL,HL
		; EX DE,HL
		; ADC HL,HL
		; LD H,L
		; LD L,D
		; LD D,E
		; LD E,0
; SECN200		POP AF
		; LD BC,P_DATA
		; OUT (C),A
		; NOP
		; OUT (C),H
		; NOP
		; OUT (C),L
		; NOP
		; OUT (C),D
		; NOP
		; OUT (C),E
		; LD A,#FF
		; OUT (C),A
		; POP BC
		; POP DE
		; POP HL
		; RET

; IN_OOUT		PUSH DE
		; LD DE,#20FF
; IN_WAIT		IN A,(P_DATA)
		; CP E
		; JR NZ,IN_EXIT
; IN_NEXT		DEC D
		; JR NZ,IN_WAIT
; IN_EXIT		POP DE
		; RET

; CMD00		DB #40,#00,#00,#00,#00,#95	; GO_IDLE_STATE
; CMD08		DB #48,#00,#00,#01,#AA,#87	; SEND_IF_COND
; CMD16		DB #50,#00,#00,#02,#00,#FF	; SET_BLOCKEN

; RD_SECT		PUSH BC
		; LD BC,P_DATA
		; INIR 
		; NOP
		; INIR
		; NOP
		; IN A,(C)
		; NOP
		; IN A,(C)
		; POP BC
		; RET

; WR_SECT		PUSH BC
		; LD BC,P_DATA
		; OTIR
		; NOP
		; OTIR
		; LD A,#FF
		; OUT (C),A
		; NOP
		; OUT (C),A
		; POP BC
		; RET

; RDMULTI		EX AF,AF'
		; LD A,CMD_18
		; CALL SECM200
		; EX AF,AF'
; RDMULT1		EX AF,AF'
		; CALL IN_OOUT
		; CP #FE
		; JR NZ,$-5
		; CALL RD_SECT
		; EX AF,AF'
		; DEC A
		; JR NZ,RDMULT1
		; LD A,CMD_12
		; CALL OUT_COM
		; CALL IN_OOUT
		; INC A
		; JR NZ,$-4
		; JP CS_HIGH

; RDSINGL		LD A,CMD_17
		; CALL SECM200
		; CALL IN_OOUT
		; CP #FE
		; JR NZ,$-5
		; CALL RD_SECT
		; CALL IN_OOUT
		; INC A
		; JR NZ,$-4
		; JP CS_HIGH

; WRSINGL		LD A,CMD_24
		; CALL SECM200
		; CALL IN_OOUT
		; INC A
		; JR NZ,$-4
		; LD A,#FE
		; CALL WR_SECT
		; CALL IN_OOUT
		; INC A
		; JR NZ,$-4
		; JP CS_HIGH

; WRMULTI		EX AF,AF'
		; LD A,CMD_25
		; CALL SECM200
		; CALL IN_OOUT
		; INC A
		; JR NZ,$-4
		; EX AF,AF'
; WRMULT1		EX AF,AF'
		; LD A,#FC
		; CALL WR_SECT
		; CALL IN_OOUT
		; INC A
		; JR NZ,$-4
		; EX AF,AF'
		; DEC A
		; JR NZ,WRMULT1
		; LD C,P_DATA
		; LD A,#FD
		; OUT (C),A
		; CALL IN_OOUT
		; INC A
		; JR NZ,$-4
		; JP CS_HIGH		

; -----------------------------------------------------------------------------	
; I2C PCF8583 
; -----------------------------------------------------------------------------
; Ports:
; #8C: Data (write/read)
;	bit 7-0	= Stores I2C read/write data
; #8C: Address (write)
; 	bit 7-1	= Holds the first seven address bits of the I2C slave device
; 	bit 0	= I2C 1:read/0:write bit

; #9C: Command/Status Register (write)
;	bit 7-2	= Reserved
;	bit 1-0	= 00: IDLE; 01: START; 10: nSTART; 11: STOP
; #9C: Command/Status Register (read)
;	bit 7-2	= Reserved
;	bit 1 	= 1:ERROR 	(I2C transaction error)
;	bit 0 	= 1:BUSY 	(I2C bus busy)

; HL= адрес буфера
; B = длина (0=256 байт)
; C = адрес
I2C_GET		LD A,%11111101	; START
		OUT (#9C),A
		LD A,%10100000	; SLAVE ADDRESS W
		OUT (#8C),A
		CALL I2C_ACK
		LD A,%11111110	; NSTART
		OUT (#9C),A
		LD A,C		; WORD ADDRESS
		OUT (#8C),A
		CALL I2C_ACK
		LD A,%11111101	; START
		OUT (#9C),A
		LD A,%10100001	; SLAVE ADDRESS R
		OUT (#8C),A
		CALL I2C_ACK
		LD A,%11111100	; IDLE
		OUT (#9C),A
		
I2C_GET2	OUT (#8C),A
		CALL I2C_ACK
		IN A,(#8C)
		LD (HL),A
		INC HL
		LD A,B
		CP 2
		JR NZ,I2C_GET1
		LD A,%11111111	; STOP
		OUT (#9C),A
I2C_GET1	DJNZ I2C_GET2
		RET

; Wait ACK
I2C_ACK		IN A,(#9C)
		RRCA		; ACK?
		JR C,I2C_ACK
		RRCA		; ERROR?
		RET
	
; -----------------------------------------------------------------------------	
; SPI 
; -----------------------------------------------------------------------------
; Ports:

; #02: Data Buffer (write/read)
;	bit 7-0	= Stores SPI read/write data

; #03: Command/Status Register (write)
;	bit 7-2	= Reserved
;	bit 1	= 1:IRQEN 	(Generate IRQ at end of transfer)
;	bit 0	= 1:END   	(Deselect device after transfer/or immediately if START = '0')
; #03: Command/Status Register (read):
; 	bit 7	= 1:BUSY	(Currently transmitting data)
;	bit 6	= 1:DESEL	(Deselect device)
;	bit 5-0	= Reserved

SPI_END		LD A,%00000001	; Config = END
		OUT (#03),A
		RET
		
SPI_START	XOR A
		OUT (#03),A
		RET
		
SPI_W		IN A,(#03)
		RLCA
		JR C,SPI_W
		LD A,D
		OUT (#02),A
		RET
		
SPI_R		LD D,#FF
		CALL SPI_W
SPI_R1		IN A,(#03)
		RLCA
		JR C,SPI_R1
		IN A,(#02)
		RET

		savebin "loader.bin",StartProg, 2048
;		savesna "loader.sna",StartProg	