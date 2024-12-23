	include "neogeo.inc"
	include "macros.inc"
	include "diag.inc"

	global watchdog_stuck_test_dsub

	section code

watchdog_stuck_test_dsub:
		lea	d_xys_watchdog_delay, a0
		DSUB	print_xys_string_clear
		lea	d_xys_watchdog_text_remains, a0
		DSUB	print_xys_string_clear
		lea	d_xys_watchdog_stuck, a0
		DSUB	print_xys_string_clear

		move.l	#$c930, d0		; 128760us / 128.76ms
		DSUB	delay

		moveq	#8, d0
		SSA3	fix_clear_line
		moveq	#10, d0
		SSA3	fix_clear_line
		DSUB_RETURN

	section data
	align 1

d_xys_watchdog_delay:		XY_STRING LEFT_MARGIN,  5, "WATCHDOG DELAY..."
d_xys_watchdog_text_remains:	XY_STRING LEFT_MARGIN,  8, "IF THIS TEXT REMAINS HERE..."
d_xys_watchdog_stuck:		XY_STRING LEFT_MARGIN, 10, "THEN SYSTEM IS STUCK IN WATCHDOG"
