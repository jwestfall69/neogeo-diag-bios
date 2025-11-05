	include "diag.inc"
	include "macros.inc"
	include "menu.inc"
	include "neogeo.inc"

	global misc_tests_menu

	section code

misc_tests_menu:

		move.b	#0, r_menu_cursor

		moveq	#-$10, d0
		bsr	wait_p1_input
		bsr	wait_frame

	.loop_menu:
		lea	d_xys_menu_title, a0
		RSUB	print_xys_string

		lea	d_menu_list, a0
		jsr	menu

		cmp.b	#MENU_CONTINUE, d0
		beq	.loop_menu
		rts

	section data
	align 1

d_menu_list:
	MENU_ENTRY calendar_tests, d_str_calendar_io, 1
	MENU_ENTRY misc_input_tests, d_str_misc_input_test, 0
	MENU_ENTRY cpu_pal_addr_test, d_str_cpu_pal_addr_test, 0
	MENU_LIST_END

d_xys_menu_title:		XY_STRING LEFT_MARGIN, 5, "MISC TESTS"

d_str_calendar_io:		STRING "CALENDAR I/O (MVS ONLY)"
d_str_cpu_pal_addr_test:	STRING "CPU/PAL ADDR TEST"
d_str_misc_input_test:		STRING "MISC INPUT TEST"
