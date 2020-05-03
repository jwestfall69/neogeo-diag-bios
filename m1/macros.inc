        macro PSUB
                ld	hl, \1_psub
                ld	de, .\@
                rst	RST_PSUB_ENTER
.\@:
        endm

        macro PSUB_RETURN
                rst	RST_PSUB_EXIT
        endm

	macro PSUB_YMWP0
		ld	de, .\@
		rst	RST_PSUB_YM2610_WRITE_PORT0
.\@
	endm

	macro STALL
.\@
		jp .\@
	endm