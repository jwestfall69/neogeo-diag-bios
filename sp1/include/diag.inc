; defines specific the the diag bios

SP_INIT_ADDR			equ $110000
BIOS_CRC32_ADDR			equ $c07ffc

; Dynamic subroutines
DSUB_INIT_PSEUDO		equ $0c
DSUB_INIT_REAL			equ $18

; fix layer x offset where we start printing stuff
LEFT_MARGIN			equ 4

; bits we can set/check in z80_test_flags
Z80_TEST_FLAG_ENABLED		equ $0
Z80_TEST_FLAG_SLOT_SWITCH	equ $1
Z80_TEST_FLAG_SKIP_SM1_TESTS	equ $2

INPUT_UP_BIT			equ $0
INPUT_DOWN_BIT			equ $1
INPUT_LEFT_BIT			equ $2
INPUT_RIGHT_BIT			equ $3
INPUT_A_BIT			equ $4
INPUT_B_BIT			equ $5
INPUT_C_BIT			equ $6
INPUT_D_BIT			equ $7

INPUT_UP			equ $01
INPUT_DOWN			equ $02
INPUT_LEFT			equ $04
INPUT_RIGHT			equ $08
INPUT_A				equ $10
INPUT_B				equ $20
INPUT_C				equ $40
INPUT_D				equ $80

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

; memcard flags (bset/btst bits)
MEMCARD_FLAG_BAD_DATA		equ $00
MEMCARD_FLAG_DBUS_16BIT		equ $01
MEMCARD_FLAG_DBUS_WIDE		equ $02
