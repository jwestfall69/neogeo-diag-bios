	include "diag.inc"
	include "macros.inc"
	include "menu.inc"
	include "neogeo.inc"

	global graphics_viewer_menu

	section code

graphics_viewer_menu:

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
	MENU_ENTRY fix_tile_viewer, d_str_fix_tile_viewer, 0
	;MENU_ENTRY sprite_viewer, d_str_sprite_viewer, 0
	MENU_LIST_END

d_xys_menu_title:		XY_STRING LEFT_MARGIN, 5, "GRAPHICS VIEWER"

d_str_fix_tile_viewer:		STRING "FIX TILE VIEWER"
;d_str_sprite_viewer:		STRING "SPRITE VIEWER"
