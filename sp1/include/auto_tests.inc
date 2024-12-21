; struct AUTO_ENTRY {
;	long function_ptr;
;	long name_ptr
; };
	rsreset
s_ae_function_ptr		rs.l 1
s_ae_name_ptr			rs.l 1
s_ae_struct_size		rs.b 0

	macro AUTO_ENTRY
		dc.l \1
		dc.l \2
	endm

	macro AUTO_LIST_END
		dc.l $0, $0
	endm
