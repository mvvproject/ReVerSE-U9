 		DEVICE	ZXSPECTRUM48
; -----------------------------------------------------------------[21.09.2014]
; ReVerSE-U9 Loader Version 0.2.6 By MVV
; -----------------------------------------------------------------------------
; V0.2.2	12.08.2014	первая версия
; V0.2.6	21.09.2014	RTC Setup

system_port	EQU #0001	; bit2 = 0:loader on, 1:loader off; bit1 = 0:sram<->cpu0, 1:sram<->gs;
pr_param	EQU #7f00
page3init 	EQU #7f05      	; RAM mem in  BANK1 (lowest  addr)
block_16k_cnt 	EQU #7f06
cursor_pos	EQU #7f07
buffer		EQU #8000

	org #0000
startprog:
	di               	; disable int
	ld sp,#7ffe	 	; stack - bank1:(exec code - bank0):destination 
	
	xor a
	ld bc,system_port
	out (c),a
	out (#fe),a		; цвет бордюра
	call cls		; очистка экрана
	ld hl,str1
	call print_str


	ld bc,#13af
	in a,(c)
	ld (page3init),a

	xor a
	LD (block_16k_cnt), A

	ld a,%00000001		; bit2 = 0:loader on, 1:loader off; bit1 = 0:sram<->cpu0, 1:sram<->gs; bit0 = 0:tda1543, 1:m25p40
	ld bc,#0001
	out (c),a




; 060000 GS 	32K

; -----------------------------------------------------------------------------
; SPI autoloader
; -----------------------------------------------------------------------------
	CALL spi_start
	LD D,%00000011	; Command = READ
	CALL spi_w

	LD D,#06	; Address = #060000
	CALL spi_w
	LD D,#00
	CALL spi_w
	LD D,#00
	CALL spi_w
	
	LD HL,#8000	; GS ROM 32K
SPI_LOADER1
	CALL spi_r
	LD (HL),A
	INC HL
	LD A,L
	OR H
	JR NZ,SPI_LOADER1
	
	ld a,%00000010	; bit2 = 0:loader on, 1:loader off; bit1 = 0:sram<->cpu0, 1:sram<->gs; bit0 = 0:tda1543, 1:m25p40
	ld bc,#0001
	out (c),a

	ld hl,str3
	call print_str

	ld hl,str2
	call print_str

; -----------------------------------------------------------------------------
; FAT16 loader
; -----------------------------------------------------------------------------
SD_LOADER
	CALL COM_SD
	DB 0
	CP 0
	JP NZ,ERR

	LD HL,#8000
	LD BC,#0000
	LD DE,#0000
	CALL COM_SD
	DB 2		; читаем MBR
	LD A,(#81C6)
	PUSH AF
	LD E,A
	LD D,0
	LD BC,#0000
	LD HL,#8000
	CALL COM_SD
	DB 2		; читаем BOOT RECORD на логическом разделе
	LD A,(#800E)
	LD C,A
	LD HL,(#8016)	; читаем размер FAT-каталога
	ADD HL,HL	; умножаем на два
	LD B,0
	ADD HL,BC	; прибавляем размер Reserved sectors
	LD C,#20
	ADD HL,BC	; прибавляем константу из расчета "два каталога FAT" и "размер сектора = 512 байт".
	POP AF
	LD C,A
	ADD HL,BC	; прибавляем смещение между физическими и логическими секторами

LOAD_16kb
	push hl        		; (sp)<--hl //load data addr (sector number)
	ex de,hl       		; de - сектрор для считывания данных 
	ld a,(block_16k_cnt)	; загружаем ячейку счетчика страниц в a
	ld bc,#13af
	out (c),a

	ld hl,#c000 		; destination memory : cpu0_a_bus(15 downto 14) = %11
				; de - начальный сектрор для считывания данных 
	ld bc,#0000
	ld a,#20            	; number of sectors : 512 * 32 = 16kb
	call COM_SD
	db 3		     	; читаем 16k
	cp 0
	jr nz,ERR

	pop hl		; в стеке был предыдущий стартовый номер сектора для считывания
	ld de,#0020  
	add hl,de 
	ld a,(block_16k_cnt)	; загружаем ячейку счетчика страниц в A
	inc a
	ld (block_16k_cnt),a
	cp 32
	jr c,LOAD_16kb

	ld hl,str3
	call print_str

	ld a,(page3init)	; RESTORE initial PAGE for Win3
	ld bc,#c000
	out (c),a
	jp RESET_LOADER
;------------------------------------------------------------------------------		
ERR
	ld hl,str_error
	call print_str
	di
	halt
stop
	jp stop
;==============================================================================		



RESET_LOADER
	ld hl,str4		; инициализация RTC
	call print_str

	call rtc_read
	ld hl,str_absent
	jr z,label1
	ld hl,str3
label1
	call print_str

	ld hl,str3		;завершено
	call print_str

	ld hl,str0		; any key
	call print_str

; Start System
	call anykey
	call mc14818a_init

	ld a,%00000110	; bit2 = 0:loader on, 1:loader off; bit1 = 0:sram<->cpu0, 1:sram<->gs; bit0 = 0:tda1543, 1:m25p40
	ld bc,#0001
	out (c),a

	ld sp,#ffff
	jp #0000	; запуск системы


; -----------------------------------------------------------------------------
; SD Driver
; -----------------------------------------------------------------------------
P_DATA		EQU #57
P_CONF		EQU #77

CMD_09		EQU #49		;SEND_CSD
CMD_10		EQU #4A		;SEND_CID
CMD_12		EQU #4C		;STOP_TRANSMISSION
CMD_17		EQU #51		;READ_SINGLE_BLOCK
CMD_18		EQU #52		;READ_MULTIPLE_BLOCK
CMD_24		EQU #58		;WRITE_BLOCK
CMD_25		EQU #59		;WRITE_MULTIPLE_BLOCK
CMD_55		EQU #77		;APP_CMD
CMD_58		EQU #7A		;READ_OCR
CMD_59		EQU #7B		;CRC_ON_OFF
ACMD_41		EQU #69		;SD_SEND_OP_COND

Sd_init		EQU 0
Sd__off		EQU 1
Rdsingl		EQU 2
Rdmulti		EQU 3
Wrsingl		EQU 4
Wrmulti		EQU 5

COM_SD	
	EX AF,AF'
	EX (SP),HL
	LD A,(HL)
	INC HL
	EX (SP),HL
	ADD A,A
	PUSH HL
	LD HL,TABLSDZ
	ADD A,L
	LD L,A
	LD A,H
	ADC A,0
	LD H,A
	LD A,(HL)
	INC HL
	LD H,(HL)
	LD L,A
	EX AF,AF'
	EX (SP),HL
	RET

TABLSDZ	
	DW SD_INIT	; 0 параметров не требует, на выходе A
			; смотри выше первые 2 значения
	DW SD__OFF	; 1 просто вырубает питание карты
	DW RDSINGL	; 2
	DW RDMULTI	; 3
	DW WRSINGL	; 4
	DW WRMULTI	; 5

SD_INIT	
	CALL CS_HIGH
	LD BC,P_DATA
	LD DE,#10FF
	OUT (C),E
	DEC D
	JR NZ,$-3
	XOR A
	EX AF,AF'
ZAW001	
	LD HL,CMD00
	CALL OUTCOM
	CALL IN_OOUT
	EX AF,AF'
	DEC A
	JR Z,ZAW003
	EX AF,AF'
	DEC A
	JR NZ,ZAW001
	LD HL,CMD08
	CALL OUTCOM
	CALL IN_OOUT
	IN H,(C)
	NOP
	IN H,(C)
	NOP
	IN H,(C)
	NOP
	IN H,(C)
	LD HL,0
	BIT 2,A
	JR NZ,ZAW006
	LD H,#40
ZAW006	
	LD A,CMD_55
	CALL OUT_COM
	CALL IN_OOUT
	LD A,ACMD_41
	OUT (C),A
	NOP
	OUT (C),H
	NOP
	OUT (C),L
	NOP
	OUT (C),L
	NOP
	OUT (C),L
	LD A,#FF
	OUT (C),A
	CALL IN_OOUT
	AND A
	JR NZ,ZAW006
ZAW004	
	LD A,CMD_59
	CALL OUT_COM
	CALL IN_OOUT
	AND A
	JR NZ,ZAW004
ZAW005	
	LD HL,CMD16
	CALL OUTCOM
	CALL IN_OOUT
	AND A
	JR NZ,ZAW005
CS_HIGH	
	PUSH AF
	LD A,3
	OUT (P_CONF),A
	XOR A
	OUT (P_DATA),A
	POP AF
	RET
ZAW003	
	CALL SD__OFF
	INC A
	RET
SD__OFF	
	XOR A
	OUT (P_CONF),A
	OUT (P_DATA),A
	RET
CS__LOW	
	PUSH AF
	LD A,1
	OUT (P_CONF),A
	POP AF
	RET
OUTCOM
	CALL CS__LOW
	PUSH BC
	LD BC,#0600+P_DATA
	OTIR
	POP BC
	RET
OUT_COM	
	PUSH BC
	CALL CS__LOW
	LD BC,P_DATA
	OUT (C),A
	XOR A
	OUT (C),A
	NOP
	OUT (C),A
	NOP
	OUT (C),A
	NOP
	OUT (C),A
	DEC A
	OUT (C),A
	POP BC
	RET
SECM200	
	PUSH HL
	PUSH DE
	PUSH BC
	PUSH AF
	PUSH BC

	LD A,CMD_58
	LD BC,P_DATA
	CALL OUT_COM
	CALL IN_OOUT
	IN A,(C)
	NOP
	IN H,(C)
	NOP
	IN H,(C)
	NOP
	IN H,(C)
	
	BIT 6,A
	POP HL
	JR NZ,SECN200
	EX DE,HL
	ADD HL,HL
	EX DE,HL
	ADC HL,HL
	LD H,L
	LD L,D
	LD D,E
	LD E,0
SECN200	
	POP AF
	LD BC,P_DATA
	OUT (C),A
	NOP
	OUT (C),H
	NOP
	OUT (C),L
	NOP
	OUT (C),D
	NOP
	OUT (C),E
	LD A,#FF
	OUT (C),A
	POP BC
	POP DE
	POP HL
	RET
IN_OOUT	
	PUSH DE
	LD DE,#20FF
IN_WAIT	
	IN A,(P_DATA)
	CP E
	JR NZ,IN_EXIT
IN_NEXT	
	DEC D
	JR NZ,IN_WAIT
IN_EXIT	
	POP DE
	RET

CMD00	DB #40,#00,#00,#00,#00,#95	; GO_IDLE_STATE
CMD08	DB #48,#00,#00,#01,#AA,#87	; SEND_IF_COND
CMD16	DB #50,#00,#00,#02,#00,#FF	; SET_BLOCKEN

RD_SECT	
	PUSH BC
	LD BC,P_DATA
	INIR 
	NOP
	INIR
	NOP
	IN A,(C)
	NOP
	IN A,(C)
	POP BC
	RET
WR_SECT	
	PUSH BC
	LD BC,P_DATA
	OTIR
	NOP
	OTIR
	LD A,#FF
	OUT (C),A
	NOP
	OUT (C),A
	POP BC
	RET
RDMULTI
	EX AF,AF'
	LD A,CMD_18
	CALL SECM200
	EX AF,AF'
RDMULT1
	EX AF,AF'
	CALL IN_OOUT
	CP #FE
	JR NZ,$-5
	CALL RD_SECT
	EX AF,AF'
	DEC A
	JR NZ,RDMULT1
	LD A,CMD_12
	CALL OUT_COM
	CALL IN_OOUT
	INC A
	JR NZ,$-4
	JP CS_HIGH
RDSINGL
	LD A,CMD_17
	CALL SECM200
	CALL IN_OOUT
	CP #FE
	JR NZ,$-5
	CALL RD_SECT
	CALL IN_OOUT
	INC A
	JR NZ,$-4
	JP CS_HIGH
WRSINGL
	LD A,CMD_24
	CALL SECM200
	CALL IN_OOUT
	INC A
	JR NZ,$-4
	LD A,#FE
	CALL WR_SECT
	CALL IN_OOUT
	INC A
	JR NZ,$-4
	JP CS_HIGH
WRMULTI
	EX AF,AF'
	LD A,CMD_25
	CALL SECM200
	CALL IN_OOUT
	INC A
	JR NZ,$-4
	EX AF,AF'
WRMULT1
	EX AF,AF'
	LD A,#FC
	CALL WR_SECT
	CALL IN_OOUT
	INC A
	JR NZ,$-4
	EX AF,AF'
	DEC A
	JR NZ,WRMULT1
	LD C,P_DATA
	LD A,#FD
	OUT (C),A
	CALL IN_OOUT
	INC A
	JR NZ,$-4
	JP CS_HIGH		










; Ожидание клавиши
anykey1
	ld hl,str0
	call print_str
	ld bc,system_port
anykey2
	in a,(c)		; чтение сканкода клавиатуры
	cp #ff
	jr nz,anykey2
anykey
	ld hl,#0900		; координаты вывода даты и времени
	ld (pr_param),hl
	call rtc_read		; чтение даты и времени
	call rtc_data		; вывод
	ld bc,system_port
	in a,(c)		; чтение сканкода клавиатуры
	cp #1b			; <S> ?
	jp z,rtc_setup
	cp #5a			; <ENTER> ?
	jr nz,anykey
	ret

; _____________________________________________________________________________
	

; -----------------------------------------------------------------------------
; I2C PCF8583 read
; -----------------------------------------------------------------------------
rtc_read
	ld bc,#0000
	ld hl,buffer
	ld d,%10100001		; Device Address RTC PCF8583 + read
	call i2c

	ld b,#00
; проверка
; z=error, nz=ok
check_buffer
	ld hl,buffer
check_buffer1
	ld a,(hl)
	inc a
	ret nz
	ld (hl),a
	inc hl
	djnz check_buffer1
	ret
	
; -----------------------------------------------------------------------------
; инициализация MC14818A
; -----------------------------------------------------------------------------
mc14818a_init
	ld a,#80
	ld bc,#eff7
	out(c),a

; register b
	ld a,#0b
	ld b,#df
	out (c),a
	ld a,#82
	ld b,#bf
	out (c),a
; seconds
	ld a,#00
	ld b,#df
	out (c),a
	ld a,(buffer+2)		; 02h seconds
	ld b,#bf
	out (c),a
; minutes		
	ld a,#02
	ld b,#df
	out (c),a
	ld a,(buffer+3)		; 03h minutes
	ld b,#bf
	out (c),a
; hours		
	ld a,#04
	ld b,#df
	out (c),a
	ld a,(buffer+4)		; 04h hours
	and #3f
	ld b,#bf
	out (c),a
; day of the week		
	ld a,#06
	ld b,#df
	out (c),a
	ld a,(buffer+6)		; 06h day
	and #e0
	rlca
	rlca
	rlca
	inc a
	ld b,#bf
	out (c),a
; date of the month
	ld a,#07
	ld b,#df
	out (c),a
	ld a,(buffer+5)		; 04h date
	and #3f
	ld b,#bf
	out (c),a
; month
	ld a,#08
	ld b,#df
	out (c),a
	ld a,(buffer+6)		; 06h month
	and #1f
	ld b,#bf
	out (c),a
; year
	ld a,#09
	ld b,#df
	out (c),a
	ld a,(buffer+5)
	and #c0
	rlca
	rlca
	ld b,a
	ld a,(buffer+16)	; ячейка для хранения года (8 бит)
	and %11111100
	or b
	ld b,#bf
	out (c),a
; register b
	ld a,#0b
	ld b,#df
	out (c),a
	ld a,#02
	ld b,#bf
	out (c),a

	ld a,#00
	ld bc,#eff7
	out(c),a
	ret

; -----------------------------------------------------------------------------
; Вывод даты и времени
; -----------------------------------------------------------------------------
rtc_data
	; вывод даты
	ld a,(buffer+6)
	and %11100000
	rlca
	rlca
	rlca
	add a,a
	add a,a
	ld hl,day		; день недели
	ld e,a
	ld d,0
	add hl,de
	call print_str
	ld a,","
	call print_char
	ld a,(buffer+5)		; число
	and %00111111
	call print_hex
	ld a,"."
	call print_char
	ld a,(buffer+6)		; месяц
	and %00011111
	call print_hex
	ld a,"."
	call print_char
	ld a,#20
	call print_hex
	ld a,(buffer+5)		; год
	and %11000000
	rlca
	rlca
	ld b,a
	ld a,(buffer+16)	; ячейка для хранения года (8 бит)
	and %11111100
	or b
	call print_hex
	ld a," "
	call print_char
	; вывод времени
	ld a,(buffer+4)		; час
	and %00111111
	call print_hex
	ld a,":"
	call print_char
	ld a,(buffer+3)		; минуты
	call print_hex
	ld a,":"
	call print_char
	ld a,(buffer+2)		; секунды
	jp print_hex		

; -----------------------------------------------------------------------------	
; I2C 
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
; D = Device Address (bit0: 0=WR, 1=RD)

i2c	
	ld a,%11111101		; start
	out (#9c),a
	ld a,d			; slave address w
	and %11111110
	out (#8c),a
	call i2c_ack
	bit 0,d
	jr nz,i2c_4		; четение
	ld a,%11111100		; idle
	out (#9c),a
	ld a,c			; word address
	out (#8c),a
	call i2c_ack
	jr i2c_2
i2c_4
	ld a,%11111110		; nstart
	out (#9c),a
	ld a,c			; word address
	out (#8c),a
	call i2c_ack
	ld a,%11111101		; start
	out (#9c),a
	ld a,d			; slave address r/w
	out (#8c),a
	call i2c_ack
	ld a,%11111100		; idle
	out (#9c),a
i2c_2
	ld a,b
	dec a
	jr nz,i2c_1
	ld a,%11111111		; stop
	out (#9c),a
i2c_1
	ld a,(hl)
	out (#8c),a
	call i2c_ack
	bit 0,d
	jr z,i2c_3		; запись? да
	in a,(#8c)
	ld (hl),a
i2c_3	
	inc hl
	djnz i2c_2
	ret

; wait ack
i2c_ack
	in a,(#9c)
	rrca			; ack?
	jr c,i2c_ack
	rrca			; error?
	ret
	
; -----------------------------------------------------------------------------	
; SPI 
; -----------------------------------------------------------------------------
; Ports:

; #02: Data Buffer (write/read)
;	bit 7-0	= Stores SPI read/write data

; #03: Command/Status Register (write)
;	bit 7-1	= Reserved
;	bit 0	= 1:END   	(Deselect device after transfer/or immediately if START = '0')
; #03: Command/Status Register (read):
; 	bit 7	= 1:BUSY	(Currently transmitting data)
;	bit 6	= 0:INT ENC424J600
;	bit 5-0	= Reserved

spi_end
	ld a,%00000001		; config = end
	out (#03),a
	ret
spi_start
	xor a
	out (#03),a
	ret
spi_w
	in a,(#03)
	rlca
	jr c,spi_w
	ld a,d
	out (#02),a
	ret
spi_r
	ld d,#ff
	call spi_w
spi_r1	
	in a,(#03)
	rlca
	jr c,spi_r1
	in a,(#02)
	ret

;==============================================================================

; clear screen
cls
	xor a
	out (#fe),a
	ld hl,#5aff
cls1
	ld (hl),a
	or (hl)
	dec hl
	jr z,cls1
	ret

; print string i: hl - pointer to string zero-terminated
print_str
	ld a,(hl)
	cp 17
	jr z,print_color
	cp 23
	jr z,print_pos_xy
	cp 24
	jr z,print_pos_x
	cp 25
	jr z,print_pos_y
	or a
	ret z
	inc hl
	call print_char
	jr print_str
print_color
	inc hl
	ld a,(hl)
	ld (pr_param+2),a	; color
	inc hl
	jr print_str
print_pos_xy
	inc hl
	ld a,(hl)
	ld (pr_param),a		; x-coord
	inc hl
	ld a,(hl)
	ld (pr_param+1),a	; y-coord
	inc hl
	jr print_str
print_pos_x
	inc hl
	ld a,(hl)
	ld (pr_param),a		; x-coord
	inc hl
	jr print_str
print_pos_y
	inc hl
	ld a,(hl)
	ld (pr_param+1),a	; y-coord
	inc hl
	jr print_str

; print character i: a - ansi char
print_char
	push hl
	push de
	push bc
	cp 13
	jr z,pchar2
	sub 32
	ld c,a			; временно сохранить в с
	ld hl,(pr_param)	; hl=yx
	;координаты -> scr adr
	;in: H - Y координата, L - X координата
	;out:hl - screen adress
	ld a,h
	and 7
	rrca
	rrca
	rrca
	or l
	ld l,a
	ld a,h
        and 24
	or 64
	ld d,a
	;scr adr -> attr adr
	;in: hl - screen adress
	;out:hl - attr adress
	rrca
	rrca
	rrca
	and 3
	or #58
	ld h,a
	ld a,(pr_param+2)	; цвет
	ld (hl),a		; печать атрибута символа
	ld e,l
	ld l,c			; l= символ
	ld h,0
	add hl,hl
	add hl,hl
	add hl,hl
	ld bc,font
	add hl,bc
	ld b,8
pchar3	ld a,(hl)
	ld (de),a
	inc d
	inc hl
	djnz pchar3
	ld a,(pr_param)		; x
	inc a
	cp 32
	jr nz,pchar1
pchar2
	ld a,(pr_param+1)	; y
	inc a
	cp 24
	jr nz,pchar0
	;сдвиг вверх на один символ
	call ssrl_up
	call asrl_up
	jr pchar00
pchar0
	ld (pr_param+1),a
pchar00
	xor a
pchar1
	ld (pr_param),a
	pop bc
	pop de
	pop hl
	ret

; print hexadecimal i: a - 8 bit number
print_hex
	ld b,a
	and $f0
	rrca
	rrca
	rrca
	rrca
	call hex2
	ld a,b
	and $0f
hex2
	cp 10
	jr nc,hex1
	add 48
	jp print_char
hex1
	add 55
	jp print_char

; print decimal i: l,d,e - 24 bit number , e - low byte
print_dec
	ld ix,dectb_w
	ld b,8
	ld h,0
lp_pdw1
	ld c,"0"-1
lp_pdw2
	inc c
	ld a,e
	sub (ix+0)
	ld e,a
	ld a,d
	sbc (ix+1)
	ld d,a
	ld a,l
	sbc (ix+2)
	ld l,a
	jr nc,lp_pdw2
	ld a,e
	add (ix+0)
	ld e,a
	ld a,d
	adc (ix+1)
	ld d,a
	ld a,l
	adc (ix+2)
	ld l,a
	inc ix
	inc ix
	inc ix
	ld a,h
	or a
	jr nz,prd3
	ld a,c
	cp "0"
	ld a," "
	jr z,prd4
prd3
	ld a,c
	ld h,1
prd4
	call print_char
	djnz lp_pdw1
	ret
dectb_w
	db #80,#96,#98		; 10000000 decimal
	db #40,#42,#0f		; 1000000
	db #a0,#86,#01		; 100000
	db #10,#27,0		; 10000
	db #e8,#03,0		; 1000
	db 100,0,0		; 100
	db 10,0,0		; 10
	db 1,0,0		; 1



; -----------------------------------------------------------------------------	
; Сдвиг изображения вверх на один символ
; -----------------------------------------------------------------------------	
ssrl_up
        ld de,#4000     	; начало экранной области
lp_ssu1 
	push de           	; сохраняем адрес линии на стеке
        ld bc,#0020     	; в линии - 32 байта
        ld a,e          	; в регистре de находится адрес
        add a,c          	; верхней линии. в регистре
        ld l,a          	; hl необходимо получить адрес
        ld a,d          	; линии, лежащей ниже с шагом 8.
        jr nc,go_ssup   	; для этого к регистру e прибав-
        add a,#08        	; ляем 32 и заносим в l. если про-
go_ssup 
	ld h,a         		; изошло переполнение, то h=d+8
        ldir                 	; перенос одной линии (32 байта)
        pop de           	; восстанавливаем адрес начала линии
        ld a,h          	; проверяем: а не пора ли нам закру-
        cp #58          	; гляться? (перенесли все 23 ряда)
        jr nc,lp_ssu2   	; если да, то переход на очистку
        inc d            	; ---------------------------------
        ld a,d          	; down_de
        and #07          	; стандартная последовательность
        jr nz,lp_ssu1   	; команд для перехода на линию
        ld a,e         		; вниз в экранной области
        add a,#20        	; (для регистра de)
        ld e,a          	;
        jr c,lp_ssu1    	; на входе:  de - адрес линии
        ld a,d          	; на выходе: de - адрес линии ниже
        sub #08          	; используется аккумулятор
        ld d,a          	;
        jr lp_ssu1      	; ---------------------------------
lp_ssu2 
	xor a            	; очистка аккумулятора
lp_ssu3 
	ld (de),a       	; и с его помощью -
        inc e            	; очистка одной линии изображения
        jr nz,lp_ssu3   	; всего: 32 байта
        ld e,#e0        	; переход к следующей
        inc d            	; (нижней) линии изображения
        bit 3,d          	; заполнили весь последний ряд?
        jr z,lp_ssu2    	; если нет, то продолжаем заполнять
        ret                  	; выход из процедуры	

; -----------------------------------------------------------------------------	
; Сдвиг атрибутов вверх
; -----------------------------------------------------------------------------	
asrl_up
        ld hl,#5820     	; адрес второй линии атрибутов
        ld de,#5800     	; адрес первой линии атрибутов
        ld bc,#02e0     	; перемещать: 23 линии по 32 байта
        ldir                 	; сдвигаем 23 нижние линии вверх
        xor a   		; цвет для заполнения нижней линии
lp_asup 
	ld (de),a       	; устанавливаем новый атрибут
        inc e            	; если заполнили всю последнюю линию
        jr nz,lp_asup   	; (e=0), то прерываем цикл
        ret                  	; выход из процедуры

; -----------------------------------------------------------------------------	
; Расчет адреса атрибута
; -----------------------------------------------------------------------------
; e = y(0-23)		hl = адрес
; d = x(0-31)
attr_addr
	ld a,e
        rrca
        rrca
        rrca
        ld l,a
        and 31
        or 88
        ld h,a
        ld a,l
        and 252
        or d
        ld l,a
	ret




; RTC Setup
; -----------------------------------------------------------------------------
; a = позиция		ix = адрес
get_cursor
	ld de,cursor_pos_data
	ld l,a
	ld h,0
	add hl,hl
	add hl,hl
	add hl,hl
	add hl,de
	push hl
	pop ix
	ret

; -----------------------------------------------------------------------------
; c = цвет
; a = позиция
print_cursor
	ld c,%01001111		; цвет курсора
print_cursor1
	call get_cursor
	ld d,(hl)		; координата х
	inc hl
	ld b,(hl)		; ширина курсора
	ld e,#09
	call attr_addr
print_cursor2	
	ld (hl),c
	inc hl
	djnz print_cursor2
	ret


	
; -----------------------------------------------------------------------------
rtc_setup
	ld hl,str6
	call print_str
	call rtc_depac

	xor a
cursor1
	ld (cursor_pos),a	; курсор в начало
cursor2
	call print_cursor	; установить курсор
key_press
	ld bc,system_port
	in a,(c)		; чтение сканкода клавиатуры
	cp #ff
	jr nz,key_press
key_press1
	ld bc,system_port
	in a,(c)		; чтение сканкода клавиатуры
	cp #5a			; <ENTER> ?
	jr z,key_enter
	cp #75			; <UP> ?
	jr z,key_up
	cp #72			; <DOWN> ?
	jr z,key_down
	cp #6b			; <LEFT> ?
	jr z,key_left
	cp #74			; <RIGHT> ?
	jr z,key_right
	cp #76			; <ESC>?
	jp z,anykey1
	jr key_press1

key_left
	ld a,(cursor_pos)
	or a			; первая позиция?
	jr z,key_press		; да, оставить без изменений
	ld c,%00000111
	call print_cursor1	; убрать курсор
	ld a,(cursor_pos)
	dec a
	jr cursor1

key_right
	ld a,(cursor_pos)
	cp 6			; последняя позиция?
	jr nc,key_press		; да, оставить без изменений
	ld c,%00000111
	call print_cursor1	; убрать курсор
	ld a,(cursor_pos)
	inc a
	jr cursor1

key_up
	ld d,(ix+4)
	ld e,(ix+5)
	ld a,(de)
	cp (ix+3)
	jr z,key_up2		; = max?
	add a,1			; арифметическое сложение
key_up1
	daa
	ld (de),a
key_up2
	ld hl,#0900		; координаты вывода даты и времени
	ld (pr_param),hl
	call rtc_pac
	call rtc_data		; вывод
	ld a,(cursor_pos)
	jr cursor2

key_down
	ld d,(ix+4)
	ld e,(ix+5)
	ld a,(de)
	cp (ix+2)
	jr z,key_up2		; = min?
	sub 1			; арифметическое вычитание
	jr key_up1

key_enter
	call rtc_pac
	ld hl,buffer
	set 7,(hl)
	ld hl,buffer
	ld bc,#0000
	ld d,%10100000		; Device Address RTC PCF8583 + write
	call i2c

	ld hl,buffer
	res 7,(hl)
	ld bc,#0100
	ld d,%10100000		; Device Address RTC PCF8583 + write
	call i2c
	jp anykey1

rtc_depac
; расспаковка
	ld a,(buffer+4)		; час
	and #3f
	ld (buffer+256),a
	ld a,(buffer+6)		; день недели
	and %11100000
	rlca
	rlca
	rlca
	ld (buffer+257),a
	ld a,(buffer+5)		; день месяца
	and #3f
	ld (buffer+258),a
	ld a,(buffer+6)		; месяц
	and #1f
	ld (buffer+259),a
	ld a,(buffer+5)		; год
	and %11000000
	rlca
	rlca
	ld b,a
	ld a,(buffer+16)
	and %11111100
	or b
	ld (buffer+16),a
	ret

rtc_pac
; упаковка
	ld a,(buffer+256)
	ld (buffer+4),a		; 04 hours
	ld a,(buffer+16)	; year
	and %00000011
	rrca
	rrca
	ld b,a
	ld a,(buffer+258)	; data
	or b
	ld (buffer+5),a		; 05 year/data
	ld a,(buffer+257)	; weekdays
	rrca
	rrca
	rrca
	ld b,a
	ld a,(buffer+259)	; mounths
	or b
	ld (buffer+6),a		; 06 weekdays/mounths
	ret

;управляющие коды
;13 (0x0d)		- след строка
;17 (0x11),color	- изменить цвет последующих символов
;23 (0x17),x,y		- изменить позицию на координаты x,y
;24 (0x18),x		- изменить позицию по x
;25 (0x19),y		- изменить позицию по y
;0			- конец строки

str1	
	db 23,0,0,17,#47,"ReVerSE-U9 DevBoard  (c)MVV,2014",17,7,13
	db 17,7,"FPGA SoftCore - TSConf v0.2.6",13
	db "(build 20140921)",13,13
	db "Loading gs.rom...",0
str3
	db 17,4," Done",17,7,13,0
str4
	db 13,"RTC Data read...",0
str0
	db 23,0,22,"Press S to run RTC Setup        "
	db         "Press ENTER to Resume          ",0
str_error
	db 17,2," Error",17,7,13,0
str2
	db "Loading zxevo.rom...",0
str6
	db 23,0,22,"<>:Select Item   ENTER:Save&Exit"
	db "^",127,  ":Change Values   ESC:Abort   ",0
str_absent
	db 17,2," Absent",17,7,13,0

; Fri 05.09.2014 23:53:29
; 0-6 1-31 1-12 0-99 0-23 0-59 0-59
cursor_pos_data
	db 0,3,#00,#06,#81,#01,#00,#00		; х, ширина, min, max, адрес переменной
	db 4,2,#01,#31,#81,#02,#00,#00
	db 7,2,#01,#12,#81,#03,#00,#00
	db 10,4,#00,#99,#80,#10,#00,#00
	db 15,2,#00,#23,#81,#00,#00,#00
	db 18,2,#00,#59,#80,#03,#00,#00
	db 21,2,#00,#59,#80,#02,#00,#00

day
	db "Sun",0,"Mon",0,"Tue",0,"Wed",0,"Thu",0,"Fri",0,"Sat",0,"Err",0

font	
	INCBIN "font.bin"


		savebin "loader.bin",startprog, 8192
;		savesna "loader.sna",startprog