		DEVICE	ZXSPECTRUM48

; U9EP3C Rev.A POST v1.04 By MVV

; 26.06.2011 Last Edition

; MemPage   70h
; mem21a14  60h A21..14
; mem24a22  61h A24..22

; VideoChar 90h
; Cursor_X  91h
; Cursor_Y  92h

	ORG #0000
StartProg:
;Start
	ld ix,Title
	jp Cls
Title
        ld ix,Test_memport
        ld hl,str_title
        ld de,#4000          	; #Video Memory address
        jp prn_txt
;----------------------------------------------------------------------
;Test MemPort
;----------------------------------------------------------------------
Test_memport
        xor a
        out (#70),a          	; Bank0
        in a,(#70)
        cp #00
        jr nz,Test_memport_err
        ld a,#01
        out (#70),a
        in a,(#70)
        cp #01
        jr z,Test_ram

Test_memport_err
	ld ix,Cpu_stop
	ld hl,str_io_err
	ld de,#4140          	; #Video Memory address
	jp prn_txt
;----------------------------------------------------------------------
;Test VRAM #52C0 - #7FFF
;----------------------------------------------------------------------
Test_ram
	ld ix,test_ram1
	ld hl,str_ram
	ld de,#4140          	; #Video Memory address
	jp prn_txt
test_ram1
	ld hl,#52c0          	; Test VRAM
test_ram2
	ld a,#55
	ld (hl),a
        cp (hl)
        jr nz,Test_ram_err
        ld a,#AA
        ld (hl),a
        cp (hl)
        jr nz,Test_ram_err
        inc hl
        ld a,h
        cp #80
        jr c,test_ram2
        jr test_ram3

Test_ram_err
        ld ix,Cpu_stop
        ld hl,str_ram_err
        ld de,#4160          	; #Video Memory address
        jp prn_txt
Cpu_stop
        jp Cpu_stop          	;CPU Stop

test_ram3
        ld ix,Test_sram
        ld hl,str_ok
        ld de,#4160          	; #Video Memory address
        jp prn_txt
;----------------------------------------------------------------------
;Test SRAM #C000 - #FFFF
;----------------------------------------------------------------------
Test_sram
        ld ix,test_sram1
        ld hl,str_sram
        ld de,#4280          	; #Video Memory address
        jp prn_txt
test_sram1
        ld ix,test_sram2
        ld hl,str_page
        ld de,#4320          	; #Video Memory address
        jp prn_txt
test_sram2
        ld ix,test_sram3
        ld hl,str_data
        ld de,#43C0          	; #Video Memory address
        jp prn_txt

test_sram3
        xor a
        ld c,a
        ld d,a
        ld e,a               	;CDE = Address in SRAM
test_sram11
        out (#70),a          	;Page
;Print Hex Page
        ld hl,#4338          	; #Video Memory address
        ld ix,test_sram6
        jp ByteToHexStr      	;A = byte, HL = buffer, IX = return
;Print Hex Data
test_sram6
        ld a,c
        ld hl,#43D0          	; #Video Memory address
        ld ix,test_sram7
        jp ByteToHexStr      	;A = byte, HL = buffer, IX = return
test_sram7
        ld a,d
        ld ix,test_sram8
        jp ByteToHexStr    	;A = byte, HL = buffer, IX = return
test_sram8
        ld a,e
        ld ix,test_sram9
        jp ByteToHexStr      	;A = byte, HL = buffer, IX = return
test_sram9
        in a,(#70)
        bit 5,a
        jr nz,test_sram_end
	
        ld ix,test_sram10
        jp Test_mem
test_sram10
        jr nz,Test_sram_err
;CDE = CDE + 4000h
        ld a,d
        add a,#40
        ld d,a
        ld a,0
        adc a,c
        ld c,a
        in a,(#70)
        ld (#FFFF),a
        inc a
        jp test_sram11

;Test SRAM Data OK
test_sram_end
	ld ix,test_sram12
	ld hl,str_ok
	ld de,#43E0        	; #Video Memory address
	jp prn_txt
;Test Page
test_sram12
	xor a
	ld hl,#FFFF
test_sram14
	out (#70),a
	cp (hl)
	jr nz,test_sram13
	inc a
	bit 5,a
	jr z,test_sram14

;Test SRAM Page OK
	ld ix,Test_sdram
	ld hl,str_ok
	ld de,#4340        	; #Video Memory address
	jp prn_txt
;Test SRAM Page Error
test_sram13
	ld hl,4338h		; #Video Memory address
	ld ix,test_sram15
	jp ByteToHexStr    	;A = byte, HL = buffer, IX = return
test_sram15
	ld ix,Test_sdram
	ld hl,str_err
	ld de,#4340	        ; #Video Memory address
	jp prn_txt

;Test SRAM ERROR
Test_sram_err
;CDE = CDE + HL (error address in page)
	ex af,af'		;Test Byte
	ld b,(hl)           	;Error Byte in Page
        ld a,h
	and #3F
	ld h,a
	add hl,de
	ex de,hl
	ld a,0
	adc a,c
	ld c,a
	exx
;Print Bit Address
	ld ix,test_sram_err2
	ld hl,str_bit
	ld de,#4524         	; #Video Memory address
	jp prn_txt
test_sram_err2
	ld ix,test_sram_err3
	ld hl,str_addr
	ld de,#45A0         	; #Video Memory address
	jp prn_txt
;Print Bit Read
test_sram_err3
	exx
	ld a,b
	ld hl,#462E         	; #Video Memory address
	ld ix,test_sram_err4
	jp ByteToBitStr     	;  A = byte, HL = buffer, IX = return
test_sram_err4
	ex af,af'
	ld hl,#460E         	; #Video Memory address
	ld ix,test_sram_err5
	jp ByteToBitStr  	; A = byte, HL = buffer, IX = return
test_sram_err5
	ld a,c
	ld hl,#45C8        	; #Video Memory address
	ld ix,test_sram_err6
	jp ByteToBitStr  	; A = byte, HL = buffer, IX = return
test_sram_err6
	ld a,d
	inc hl
	ld ix,test_sram_err7
	jp ByteToBitStr  	; A = byte, HL = buffer, IX = return
test_sram_err7
	ld a,e
	inc hl
	ld ix,Test_sdram
	jp ByteToBitStr  	; A = byte, HL = buffer, IX = return
	
;----------------------------------------------------------------------
;Test SDRAM #8000 - #BFFF
;----------------------------------------------------------------------
Test_sdram
	ld ix,test_sdram1
	ld hl,str_sdram
	ld de,#46E0          	; #Video Memory address
	jp prn_txt
test_sdram1
	ld ix,test_sdram2
	ld hl,str_page
	ld de,#4780          	; #Video Memory address
	jp prn_txt
test_sdram2
	ld ix,test_sdram3
	ld hl,str_data
	ld de,#4820          	; #Video Memory address
	jp prn_txt

test_sdram3
	xor a
	ld c,a               	; port 61h
	ld sp,#0000          	;SPDE = Address in SDRAM
	ld de,#0000
test_sdram11
	out (#60),a          	;Page
;Print Hex Page
	ld hl,#4798          	; #Video Memory address
	ld ix,test_sdram6a
	jp ByteToHexStr      	;A = byte, HL = buffer, IX = return
test_sdram6a
	ld a,c
	out (#61),a
	ld hl,#4794          	; #Video Memory address
	ld ix,test_sdram6
	jp ByteToHexStr      	;A = byte, HL = buffer, IX = return
;Print Hex Data
test_sdram6
	ld hl,#0000
	add hl,sp
	ld a,h
	ld hl,#482C          	; #Video Memory address
	ld ix,test_sdram6b
	jp ByteToHexStr      	;A = byte, HL = buffer, IX = return
test_sdram6b
	ld hl,#0000
	add hl,sp
	ld a,l
	ld hl,#4830          	; #Video Memory address
	ld ix,test_sdram7
	jp ByteToHexStr      	;A = byte, HL = buffer, IX = return
test_sdram7
	ld a,d
	ld ix,test_sdram8
	jp ByteToHexStr      	;A = byte, HL = buffer, IX = return
test_sdram8
	ld a,e
	ld ix,test_sdram9
	jp ByteToHexStr      	;A = byte, HL = buffer, IX = return
test_sdram9
	bit 3,c
	jr nz,test_sdram_end

	ld ix,test_sdram10
	jp Test_mem2

test_sdram10
	jr nz,Test_sdram_err
	in a,(#60)
	ld (#BFFE),a
	in a,(#61)
	ld (#BFFF),a

;SPDE = SPDE + 4000h
	ld a,#40
	add a,d
	ld d,a
	jr nc,LC
	inc sp
LC
	in a,(#60)
	ld l,a
	ld h,c
	inc hl
	ld a,l
	ld c,h
	jp test_sdram11

;Test SDRAM Data OK
test_sdram_end:
	ld ix,test_sdram12
	ld hl,str_ok
	ld de,#4840        	; #Video Memory address
	jp prn_txt
;Test Page
test_sdram12
	ld de,#0000
test_sdram14
	ld hl,#BFFF
	ld a,e
	out (#60),a
	ld a,d
	out (#61),a
	
	cp (hl)
	jr nz,test_sdram13
	dec hl
	ld a,e
	cp (hl)
	jr nz,test_sdram13
	inc de
	bit 3,d
	jr z,test_sdram14

;Test SDRAM Page OK
	ld ix,Test_wr
	ld hl,str_ok
	ld de,#47A0        	; #Video Memory address
	jp prn_txt
;Test SDRAM Page Error
test_sdram13
	ld a,d
	ld hl,#4794		; #
	ld ix,test_sdram13a
	jp ByteToHexStr    	;A = byte, HL = buffer, IX = return
test_sdram13a
	ld a,e
	ld ix,test_sdram15
	jp ByteToHexStr    	;A = byte, HL = buffer, IX = return

test_sdram15
	ld ix,Test_wr
	ld hl,str_err
	ld de,#47A0       	; #Video Memory address
	jp prn_txt

;Test SDRAM ERROR
Test_sdram_err
;SPDE = SPDE + HL (error address in page)
	ld c,a              	;reg A = Test Byte; reg B = Error Byte in Page
	ld a,h
	and #3F
	ld h,a
	ld a,e
	add a,l
	ld e,a
	ld a,d
	adc a,h
	ld d,a
	jr nc,LL
	inc sp
LL
	exx
;Print Bit Address
	ld ix,test_sdram_err2
	ld hl,str_bit
	ld de,#4984         	; #Video Memory address
	jp prn_txt
test_sdram_err2
	ld ix,test_sdram_err3
	ld hl,str_addr
	ld de,#4A00         	; #Video Memory address
	jp prn_txt
;Print Bit Read
test_sdram_err3
	exx
	ld a,b
	ld hl,#4A8E        	; #Video Memory address
	ld ix,test_sdram_err4
	jp ByteToBitStr     	; A = byte, HL = buffer, IX = return
test_sdram_err4
	ld a,c
	ld hl,#4A6E         	; #Video Memory address
	ld ix,test_sdram_err5
	jp ByteToBitStr  	; A = byte, HL = buffer, IX = return
test_sdram_err5
	ld hl,0
	add hl,sp
	ld a,#30
	bit 0,h
	jr z,test_sdram_err5a
	inc a
test_sdram_err5a
	ld (#4512),a          	; bit 24 error adress
	ld a,l
	ld hl,#4A28        	; #Video Memory address
	ld ix,test_sdram_err6
	jp ByteToBitStr  	; A = byte, HL = buffer, IX = return
test_sdram_err6
	ld a,d
	inc hl
	ld ix,test_sdram_err7
	jp ByteToBitStr  	; A = byte, HL = buffer, IX = return
test_sdram_err7
	ld a,e
	inc hl
	ld ix,Test_wr
	jp ByteToBitStr  	; A = byte, HL = buffer, IX = return


;--------------------------------------------------------------------
;Test SDRAM WR/RD Data
;--------------------------------------------------------------------
Test_wr
	ld ix,test_wr1
	ld hl,str_write
	ld de,#47B2         	; #Video Memory address
	jp prn_txt
test_wr1
	ld ix,test_wr2
	ld hl,str_read
	ld de,#4852         	; #Video Memory address
	jp prn_txt




;@@@@@@@@@@
test_wr2
	ld hl,#8000
	ld b,l
test_wr3
	ld (hl),l
	inc hl
	djnz test_wr3
;@@@@@@@@@@





;--------------------------------------------------------------------
;Test GPIO
;--------------------------------------------------------------------
Test_gpio
	ld ix,test_gpio1
	ld hl,str_gpio
	ld de,#4B40     	; #Video Memory address
	jp prn_txt
test_gpio1
	ld ix,test_gpio2
	ld hl,str_gpio1
	ld de,#4BE0    		; #Video Memory address
	jp prn_txt
test_gpio2
	ld ix,test_gpio3
	ld hl,str_gpio2
	ld de,#5180    		; #Video Memory address
	jp prn_txt

;Read GPIO
test_gpio3
	ld de,#00A0		; #
	ld hl,#4BFE    		; #Video Memory address
;Port SD
	in a,(#71)     		; Port Read SD/MMC
	ld b,8
test_gpio5
	rlca
	ld c,#30
	jr nc,test_gpio4
	ld c,#31
test_gpio4
	ld (hl),c
	add hl,de
	djnz test_gpio5

;Port SRAM Data
	ld hl,#4C28		; #
	in a,(#72)     		; Port Read SRAM Data 7..0
	ld b,8
test_gpio7
	rrca
	ld c,#30
	jr nc,test_gpio6
	ld c,#31
test_gpio6
	ld (hl),c
	add hl,de
	djnz test_gpio7

;Port DRAM Data
	ld hl,#4C52		; #
	in a,(#73)     		; Port Read SDRAM Data 7..0
	ld b,8
test_gpio9
	rrca
	ld c,#30
	jr nc,test_gpio8
	ld c,#31
test_gpio8
	ld (hl),c
	add hl,de
	djnz test_gpio9
	
;Test write data to SDRAM




;@@@@@@@@@@
	ld hl,#4860		; #
	ld c,#10
test_wr5
	ld b,#80
	ld a,(bc)
	ld ix,test_wr4
	jp ByteToHexStr    	;A = byte, HL = buffer, IX = return
test_wr4
	inc hl
	inc hl			; #
	inc c
	ld a,c
	cp #20
	jr nz,test_wr5
;@@@@@@@@@@







;Port SCL, SDA, RTC, ASDO, DAC, NCSO, DCLK, DATA0
	ld hl,#4C7C		; #
	in a,(#74)      	; Port Read GPIO
	ld b,8
test_gpio11
	rlca
	ld c,#30
	jr nc,test_gpio10
	ld c,#31
test_gpio10
	ld (hl),c
	add hl,de
	djnz test_gpio11

;Port MSDAT, KBDAT, TXD, GPI, MSCLK, KBCLK, RXD, CBUS4
	ld de,#002A		; #
	ld hl,#519E		; #
	in a,(#75)
	ld b,4
test_gpio13
	rlca
	ld c,#30
	jr nc,test_gpio12
	ld c,#31
test_gpio12
	ld (hl),c
	add hl,de
	djnz test_gpio13

	ld hl,#523E		; #
	ld b,4
test_gpio15
	rlca
	ld c,#30
	jr nc,test_gpio14
	ld c,#31
test_gpio14
	ld (hl),c
	add hl,de
	djnz test_gpio15

	jp test_gpio3

;------------------------------------------------------------
; Test Block 16K C000h-FFFFh (SRAM)
;IX = return
Test_mem
	ld hl,#c000
test_mem1
	ld a,#55
	ld (hl),a
	cp (hl)
	jr nz,test_err
	ld a,#AA
	ld (hl),a
	cp (hl)
	jr nz,test_err
	inc hl
	ld a,h
	or l
	jr nz,test_mem1
test_err
;A = Test Byte, HL = Address in Page
	jp (ix)        		;nz = error, z = ok
;------------------------------------------------------------
; Test Block 16K 8000h-BFFFh (SDRAM)
;IX = return
Test_mem2
	ld hl,#8000
test_mem3
	ld a,#55
	ld (hl),a
	ld b,(hl)
	cp b
	jr nz,test_err1
	ld a,#AA
	ld (hl),a
	ld b,(hl)
	cp b
	jr nz,test_err1
	inc hl
	ld a,#40
	add a,h
	jr nz,test_mem3
	or a
test_err1
;A = Test Byte, HL = Address in Page
	jp (ix)        		;nz = error, z = ok

;------------------------------------------------------------
;IX = return
;HL = start
;DE = screen
prn_txt
	ld a,(hl)
	or a
	jr z,prn_txt1
	cp 1
	jr nz,prn_txt2
	inc hl
	ld a,(hl)
	ld i,a
	inc hl
	jr prn_txt
prn_txt2	
	ld (de),a
	inc de
	ld a,i
	ld (de),a
	inc de
	inc hl
	jr prn_txt
prn_txt1
        jp (ix)

Cls
        ld bc,2400
	ld hl,#4000
cls1
        ld (hl),#20      	; print character to video
	inc hl
	ld (hl),7
	inc hl
	dec bc
        ld a,b
        or c
        jr nz,cls1
        jp (ix)
        
;----------------------------------
; A = byte
; HL = buffer
; IX = return
ByteToBitStr
	ld b,#08
byteToBitStr2
	rlca
	jr nc,byteToBitStr1
	ld (hl),#31
	inc hl
	inc hl
	djnz byteToBitStr2
	jp (ix)
byteToBitStr1
	ld (hl),#30
	inc hl
	inc hl
	djnz byteToBitStr2
	jp (ix)

;----------------------------------
; A = byte
; HL = buffer
; IX = return
ByteToHexStr
	ld b,a
	rrca
	rrca
	rrca
	rrca
	and #0f
	add a,#90
	daa
	adc a,#40
	daa
	ld (hl),a
	inc hl
	inc hl
	ld a,b
	and #0f
	add a,#90
	daa
	adc a,#40
	daa
	ld (hl),a
	inc hl
	inc hl
	jp (ix)

str_title
	db 1,15
	db " U9EP3C POST Version 1.04 (build 20110626) By MVV                               ",0
str_ram
	db 1,7
	db "Test VRAM:            ",1,5,"CPU T80 @ 105MHz",0
str_sram
	db 1,7
	db "Test SRAM 512K:",0
str_sdram
	db 1,7
	db "Test SDRAM 32M:",0
str_gpio
	db 1,7
	db "Test GPIO:",0
str_page
	db 1,5
	db "Page:",1,6,"          ",0
str_data
	db 1,5
	db "Data:",1,6,"          ",0
str_bit
	db 1,5
	db "8 76543210 FEDCBA98 76543210         76543210        76543210",0
str_addr
	db 1,%00010111
	db "ERROR Address:    0 00000000 00000000 00000000  Write: 00000000  Read: 00000000",0
str_gpio1
	db 1,5
	db "SD_PROT  [24]= ",1,6,"0",1,5,"     SRAM_D0 [115]= ",1,6,"0",1,5,"     DRAM_D0  [60]= ",1,6,"0",1,5,"     SCL      [10]= ",1,6,"0",1,5," "
	db "SD_DETECT[25]= ",1,6,"0",1,5,"     SRAM_D1 [119]= ",1,6,"0",1,5,"     DRAM_D1  [64]= ",1,6,"0",1,5,"     SDA      [11]= ",1,6,"0",1,5," "
	db "SD_DAT2  [28]= ",1,6,"0",1,5,"     SRAM_D2 [120]= ",1,6,"0",1,5,"     DRAM_D2  [65]= ",1,6,"0",1,5,"     RTC_INT  [23]= ",1,6,"0",1,5," "
	db "SD_DAT3  [30]= ",1,6,"0",1,5,"     SRAM_D3 [121]= ",1,6,"0",1,5,"     DRAM_D3  [66]= ",1,6,"0",1,5,"     ASDO      [6]= ",1,6,"0",1,5," "
	db "SD_CMD   [31]= ",1,6,"0",1,5,"     SRAM_D4 [143]= ",1,6,"0",1,5,"     DRAM_D4  [39]= ",1,6,"0",1,5,"     DAC_BCK   [7]= ",1,6,"0",1,5," "
	db "SD_CLK   [32]= ",1,6,"0",1,5,"     SRAM_D5 [142]= ",1,6,"0",1,5,"     DRAM_D5  [38]= ",1,6,"0",1,5,"     NCSO      [8]= ",1,6,"0",1,5," "
	db "SD_DAT0  [33]= ",1,6,"0",1,5,"     SRAM_D6 [141]= ",1,6,"0",1,5,"     DRAM_D6  [58]= ",1,6,"0",1,5,"     DCLK     [12]= ",1,6,"0",1,5," "
	db "SD_DAT1  [34]= ",1,6,"0",1,5,"     SRAM_D7 [138]= ",1,6,"0",1,5,"     DRAM_D7  [59]= ",1,6,"0",1,5,"     DATA0    [13]= ",1,6,"0",1,5," ",0
str_gpio2
	db 1,5
	db "MSDAT    [79]= ",1,6,"0",1,5,"     KBDAT   [105]= ",1,6,"0",1,5,"     TXD      [91]= ",1,6,"0",1,5,"     GPI      [89]= ",1,6,"0",1,5," "
	db "MSCLK    [80]= ",1,6,"0",1,5,"     KBCLK   [106]= ",1,6,"0",1,5,"     RXD      [77]= ",1,6,"0",1,5,"     CBUS4    [90]= ",1,6,"0",1,5," ",0

str_write
	db 1,5
	db "Write: ",1,3,"10 11 12 13 14 15 16 17 18 19 1A 1B 1C 1D 1E 1F",0
str_read
        db 1,5
	db "Read : ",1,6,"                                               ",0
str_ok
	db 1,4
	db "OK",0
str_err
	db 1,%00010111
	db "ERROR",0
str_io_err
	db 1,2
	db "PORT I/O ERROR! CPU HALT.",0
str_ram_err
	db 1,2
	db "INTERNAL RAM ERROR! CPU HALT.",0
	
	savebin "test01.bin",StartProg, 4096