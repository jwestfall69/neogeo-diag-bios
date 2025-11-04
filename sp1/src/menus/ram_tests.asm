	include "diag.inc"
	include "macros.inc"
	include "menu.inc"
	include "neogeo.inc"

	global ram_tests_menu

	section code

ram_tests_menu:

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
	MENU_ENTRY manual_work_ram_tests, d_str_work_ram_test_loop, 0
	MENU_ENTRY manual_backup_ram_tests, d_str_backup_ram_tests, 1
	MENU_ENTRY manual_palette_ram_tests, d_str_pal_ram_tests, 0
	MENU_ENTRY manual_video_ram_32k_tests, d_str_vram_32k_tests, 0
	MENU_ENTRY manual_video_ram_2k_tests, d_str_vram_2k_tests, 0
	MENU_LIST_END

d_xys_menu_title:		XY_STRING LEFT_MARGIN, 5, "RAM TESTS"

d_str_backup_ram_tests:		STRING "BACKUP RAM TESTS (MVS ONLY)"
d_str_pal_ram_tests:		STRING "PALETTE RAM TESTS"
d_str_vram_2k_tests:		STRING "VRAM 2K TESTS"
d_str_vram_32k_tests:		STRING "VRAM 32K TESTS"
d_str_work_ram_test_loop:	STRING "WORK RAM TESTS"
