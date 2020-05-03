; defines specific the the diag bios

SP_INIT_ADDR			equ $110000
BIOS_CRC32_ADDR			equ $c03ffc
PALETTE_RAM_BACKUP_LOCATION	equ $10001c
FIXMAP_BACKUP_LOCATION		equ $10201c

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
z80_test_flag			equ $10001a 
