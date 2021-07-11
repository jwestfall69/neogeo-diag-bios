

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

; Simple|Small Subroutine A3 (SSA3)
; One of the limitations with dsubs is only being able to nest 2 times.  This
; is mainly a problem with the print related dsubs as most will want to either
; seek to an x,y location in the fix layer and/or clearing a fix layer line.
; If print dsub were to dsub call fix_seek_xy|fix_clear_line it would often
; be one to many nests, so a bunch of the print dsub's had a copy of the code
; for fix_seek_xy|fix_clear_line in them.  SSA3 is meant to get around this by
; calling a simple|small subroutine that will always jmp (a3) to return.  This
; way we can get around having another dsub nest.
;
; ssa3 code blocks should be kept simple and should never call any other
; subroutines.  They should not touch a3/a4/a5/a7/d7 registers and/or use
; the stack.
;
; Two macros are setup to handle these
;  SSA3 <subroutine>
;   This will deal with setting up the return label and pushing it into a3,
;   then calling the subroutine. Note that the macro will automatically
;   append _ssa3 onto the supplied subroutine name.
;  SSA3_RETURN
;   When in a ssa3, SSA3_RETURN should be used to return from the subroutine.
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
