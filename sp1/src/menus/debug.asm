	include "diag.inc"
	include "macros.inc"
	include "menu.inc"

	global debug_menu

	section code

debug_menu:
		move.b	#0, r_menu_cursor

		moveq	#-$10, d0
		bsr	wait_p1_input
		bsr	wait_frame

	.loop_menu:
		SSA3	fix_clear

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
	MENU_ENTRY ec_dupe_check, d_str_ec_dupe_check, 0
	MENU_ENTRY error_address_test, d_str_error_address_test, 0
	MENU_ENTRY git_hash, d_str_diag_git_hash, 0
	MENU_LIST_END

d_xys_menu_title:		XY_STRING LEFT_MARGIN, 5, "DEBUG MENU"

d_str_ec_dupe_check:		STRING "EC DUPE CHECK"
d_str_error_address_test:	STRING "ERROR ADDRESS TEST"
d_str_diag_git_hash:		STRING "DIAG GIT HASH"
