

	macro WATCHDOG
		move.b	d0, (REG_WATCHDOG)
	endm

	macro PSUB
		lea (\1_psub), a2
		lea (.\@), a3
		bra psub_enter
.\@:
	endm

	macro PSUB_RETURN
		bra psub_exit
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

	macro XYP_STRING
		dc.b \1, \2, \3
		dc.b \4, $0
		align 1
	endm

	macro XYP_STRING_MULTI
		dc.b \1, \2, \3
		dc.b \4, $0
	endm

	macro XYP_STRING_MULTI_END
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

	macro EC_LOOKUP_ITEM
		dc.b $0, EC_\1
		dc.l STR_\1
	endm

	macro ECT_DATA_LOOKUP_ITEM
		dc.w \1
		dc.l \2
	endm

	macro FILLTO
\@:
		blk.b \1 - \@, \2
	endm