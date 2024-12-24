	include "neogeo.inc"
	include "macros.inc"
	include "diag.inc"

	global watchdog_stuck_test_dsub

	section code

watchdog_stuck_test_dsub:
		lea	d_xys_screen_list, a0
		DSUB	print_xys_string_clear_list

		move.l	#$c930, d0		; 128760us / 128.76ms
		DSUB	delay

		moveq	#8, d0
		SSA3	fix_clear_line
		moveq	#10, d0
		SSA3	fix_clear_line
		DSUB_RETURN

	section data
	align 1

d_xys_screen_list:
	XY_STRING LEFT_MARGIN,  5, "WATCHDOG DELAY..."
	XY_STRING LEFT_MARGIN,  8, "IF THIS TEXT REMAINS HERE..."
	XY_STRING LEFT_MARGIN, 10, "THEN SYSTEM IS STUCK IN WATCHDOG"
	XY_STRING_LIST_END
