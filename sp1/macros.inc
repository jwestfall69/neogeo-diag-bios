

	macro WATCHDOG
		move.b	d0, (REG_WATCHDOG)
	endm

	macro DSUB
		lea (\1_dsub), a2
		lea (.\@), a3
		bra dsub_enter
.\@:
	endm

	macro DSUB_RETURN
		bra dsub_return
	endm

	macro PSUB
		lea (\1_dsub), a2
		lea (.\@), a3
		bra dsub_enter
.\@:
	endm

	macro RSUB
		subq.w #4, d7
		bsr \1_dsub
	endm

	macro SSA3
		lea (.\@), a3
		jmp \1_ssa3
.\@:
	endm

	macro SSA3_RETURN
		jmp (a3)
	endm

	macro STRING
		dc.b \1, $0
		align 1
	endm

	macro XY_STRING
		dc.b \1, \2
		dc.b \3, $0
		align 1
	endm

	macro XY_STRING_MULTI
		dc.b \1, \2 
		dc.b \3, $0
	endm

	macro XY_STRING_MULTI_END
		dc.b $0
	endm

	macro MAIN_MENU_ITEM
		dc.l \1, \2
		dc.w \3
	endm

	macro MISC_INPUT_ITEM
		dc.b \1,\2,\3,\4
		dc.l \5,\6\,\7
	endm

	macro STALL
.loop_stall:
		WATCHDOG
		bra .loop_stall
	endm

	macro EC_LOOKUP_STRUCT
		dc.b EC_\1, \2
		dc.l STR_\1
	endm

	macro PRINT_ERROR_STRUCT
		dc.b $00, \1
		dc.l \2
	endm
