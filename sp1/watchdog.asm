	include "neogeo.inc"
	include "macros.inc"
	include "sp1.inc"

	global watchdog_stuck_test_dsub

	section text

watchdog_stuck_test_dsub:
		lea	XY_STR_WATCHDOG_DELAY, a0
		DSUB	print_xy_string_struct_clear
		lea	XY_STR_WATCHDOG_TEXT_REMAINS, a0
		DSUB	print_xy_string_struct_clear
		lea	XY_STR_WATCHDOG_STUCK, a0
		DSUB	print_xy_string_struct_clear

		move.l	#$c930, d0		; 128760us / 128.76ms
		DSUB	delay

		moveq	#8, d0
		SSA3	fix_clear_line
		moveq	#10, d0
		SSA3	fix_clear_line
		DSUB_RETURN

XY_STR_WATCHDOG_DELAY:		XY_STRING  4,  5, "WATCHDOG DELAY..."
XY_STR_WATCHDOG_TEXT_REMAINS:	XY_STRING  4,  8, "IF THIS TEXT REMAINS HERE..."
XY_STR_WATCHDOG_STUCK:		XY_STRING  4, 10, "THEN SYSTEM IS STUCK IN WATCHDOG"
