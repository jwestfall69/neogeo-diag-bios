; print error function ids
PRINT_ERROR_MEMORY		equ $01
PRINT_ERROR_HEX_BYTE		equ $02
PRINT_ERROR_BIOS_CRC32		equ $03
PRINT_ERROR_MMIO		equ $04
PRINT_ERROR_STRING		equ $05
PRINT_ERROR_INVALID		equ $ff

; struct EC_PRINT_ENTRY {
;	word dsub_id;
;	long dsub_address
; };
	rsreset
s_pe_print_error_id		rs.w 1
s_pe_function_ptr		rs.l 1
s_pe_struct_size		rs.b 0

	macro EC_PRINT_ENTRY
		dc.w \1
		dc.l \2
	endm

	macro EC_PRINT_LIST_END
		dc.w $0
		dc.l $0
	endm


; struct EC_ENTRY {
;	byte error_code;
;	byte print_error_dsub_id;
;	long description_string_address;
; }
	rsreset
s_ee_error_code		rs.b 1
s_ee_print_error_id	rs.b 1
s_ee_description_ptr	rs.l 1
s_ee_struct_size	rs.b 0

	macro EC_ENTRY
		dc.b \1, \2
		dc.l \3
	endm

	macro EC_LIST_END
		dc.b $0, $0
		dc.l $0
	endm

; struct EC_MMIO_ENTRY {
; 	long register;
;	long xys_string_list_ptr;
; };
	rsreset
s_em_register			rs.l 1
s_em_description_xys_list_ptr	rs.l 1
s_em_struct_size		rs.b 0

	macro EC_MMIO_ENTRY
		dc.l \1, \2
	endm

	macro EC_MMIO_LIST_END
		dc.l $0, $0
	endm
