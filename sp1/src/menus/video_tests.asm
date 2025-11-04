	include "diag.inc"
	include "macros.inc"
	include "menu.inc"
	include "neogeo.inc"

	global video_tests_menu

	section code

video_tests_menu:

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
	MENU_ENTRY manual_color_bars_basic_test, d_str_color_bars_basic, 0
	MENU_ENTRY manual_color_bars_smpte_test, d_str_color_bars_smpte, 0
	MENU_ENTRY manual_video_dac_tests, d_str_video_dac_tests, 0
	MENU_LIST_END

d_xys_menu_title:		XY_STRING LEFT_MARGIN, 5, "VIDEO TESTS"

d_str_color_bars_basic:		STRING "COLOR BARS BASIC"
d_str_color_bars_smpte:		STRING "COLOR BARS SMPTE"
d_str_video_dac_tests:		STRING "VIDEO DAC TESTS"
