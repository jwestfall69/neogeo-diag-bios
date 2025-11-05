	include "diag.inc"
	include "macros.inc"
	include "menu.inc"

	global main_menu

	section code

main_menu:
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

		cmp.b	#MENU_EXIT, d0
		beq	main_menu
		bra	.loop_menu

	section data
	align 1

d_menu_list:
	MENU_ENTRY controller_tests, d_str_controller_tests, 0
	MENU_ENTRY graphics_viewer_menu, d_str_graphics_viewer, 0
	MENU_ENTRY memcard_tests, d_str_memcard_tests, 0
	MENU_ENTRY memory_viewer_menu, d_str_memory_viewer, 0
	MENU_ENTRY misc_tests_menu, d_str_misc_tests, 0
	MENU_ENTRY prog_rom_bus_tests, d_str_prog_rom_bus_tests, 0
	MENU_ENTRY ram_tests_menu, d_str_ram_tests, 0
	MENU_ENTRY video_tests_menu, d_str_video_tests, 0
	MENU_ENTRY debug_menu, d_str_debug_menu, 0
	MENU_LIST_END

d_xys_menu_title:		XY_STRING LEFT_MARGIN, 5, "MAIN MENU"

d_str_controller_tests:		STRING "CONTROLLER TESTS"
d_str_debug_menu:		STRING "DEBUG MENU"
d_str_graphics_viewer:		STRING "GRAPHICS VIEWER"
d_str_memcard_tests:		STRING "MEMORY CARD TESTS"
d_str_memory_viewer:		STRING "MEMORY VIEWER"
d_str_misc_tests:		STRING "MISC TESTS"
d_str_prog_rom_bus_tests:	STRING "PROG ROM BUS TESTS (CUSTOM CART)"
d_str_ram_tests:		STRING "RAM TESTS"
d_str_video_tests:		STRING "VIDEO TESTS"
