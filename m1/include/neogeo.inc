IO_YM2610_PORT0_REGISTER	equ $04 ; read/write
IO_YM2610_PORT0_DATA		equ $05 ; read/write
IO_YM2610_PORT1_REGISTER	equ $06 ; read/write
IO_YM2610_PORT1_DATA		equ $07 ; read/write

IO_FROM_68K			equ $00	; read
IO_FROM_68K_CLEAR		equ $00	; write
IO_TO_68K			equ $0c ; write

IO_NMI_DISABLE			equ $18 ; write
IO_NMI_ENABLE			equ $08 ; write

IO_BANK_2K			equ $08 ; read
IO_BANK_4K			equ $09 ; read
IO_BANK_8K			equ $0a ; read
IO_BANK_16K			equ $0b ; read

Z80_RAM_START			equ $f800

