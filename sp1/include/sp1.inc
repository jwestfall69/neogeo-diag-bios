; defines specific the the diag bios

SP_INIT_ADDR			equ $110000
BIOS_CRC32_ADDR			equ $c07ffc
PALETTE_RAM_BACKUP_LOCATION	equ $100024
FIXMAP_BACKUP_LOCATION		equ $102024

; Dynamic subroutines
DSUB_INIT_PSEUDO		equ $0c
DSUB_INIT_REAL			equ $18

; variable locations in ram
; $100000 ?
; $100002 ?
rtc_pulse_state			equ $100004
timer_count			equ $100006
p1_input			equ $100008	; active buttons are 1
p2_input			equ $10000a
p1_input_edge			equ $10000c
p2_input_edge			equ $10000e
p1_input_aux			equ $100010
p2_input_aux			equ $100012
p1_input_aux_edge		equ $100014
p2_input_aux_edge		equ $100016
main_menu_cursor		equ $100018	; highlighted main menu item
z80_test_flags			equ $10001a
memcard_size			equ $10001c	; long, data size
memcard_flags			equ $100022

; bits we can set/check in z80_test_flags
Z80_TEST_FLAG_ENABLED		equ $0
Z80_TEST_FLAG_SLOT_SWITCH	equ $1

; bits for p1/2_input_edge
UP				equ $0
DOWN				equ $1
LEFT				equ $2
RIGHT				equ $3
A_BUTTON			equ $4
B_BUTTON			equ $5
C_BUTTON			equ $6
D_BUTTON			equ $7

; SMPTE colors
SMPTE_BLACK			equ $0000	; #000000
SMPTE_BLACK8			equ $f000	; #080808
SMPTE_BLACK16			equ $8111	; #101010
SMPTE_BLACK24			equ $f111	; #181818
SMPTE_BLUE			equ $000c	; #0000c6
SMPTE_CYAN			equ $00cc	; #00c6c6
SMPTE_DARK_BLUE			equ $9024	; #00214a
SMPTE_GRAY			equ $8ccc	; #c6c6c6
SMPTE_GREEN			equ $80c0	; #00c600
SMPTE_MAGENTA			equ $0c0c	; #c600c6
SMPTE_PURPLE			equ $9306	; #31006b
SMPTE_RED			equ $8c00	; #c60000
SMPTE_WHITE			equ $7fff	; #ffffff
SMPTE_YELLOW			equ $8cc0	; #c6c600

; SMPTE palette each color will be in
SMPTE_PAL_BLACK			equ $02
SMPTE_PAL_BLACK8		equ $03
SMPTE_PAL_BLACK16		equ $04
SMPTE_PAL_BLACK24		equ $05
SMPTE_PAL_BLUE			equ $06
SMPTE_PAL_CYAN			equ $07
SMPTE_PAL_DARK_BLUE		equ $08
SMPTE_PAL_GRAY			equ $09
SMPTE_PAL_GREEN			equ $0a
SMPTE_PAL_MAGENTA		equ $0b
SMPTE_PAL_PURPLE		equ $0c
SMPTE_PAL_RED			equ $0d
SMPTE_PAL_WHITE			equ $0e
SMPTE_PAL_YELLOW		equ $0f

; print error function ids
PRINT_ERROR_MEMORY		equ $01
PRINT_ERROR_HEX_BYTE		equ $02
PRINT_ERROR_BIOS_CRC32		equ $03
PRINT_ERROR_MMIO		equ $04
PRINT_ERROR_STRING		equ $05
PRINT_ERROR_INVALID		equ $ff

; memcard flags (bset/btst bits)
MEMCARD_FLAG_BAD_DATA		equ $00
MEMCARD_FLAG_DBUS_16BIT		equ $01
MEMCARD_FLAG_DBUS_WIDE		equ $02
