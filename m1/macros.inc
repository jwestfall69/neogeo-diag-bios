        macro PSUB
                ld	hl, \1_psub
                ld	de, .\@
                rst	psub_enter_rst
.\@:
        endm

        macro PSUB_RETURN
                rst	psub_exit_rst
        endm

	macro PSUB_YMWP0
		ld	de, .\@
		rst	psub_enter_ym2610_write_port0_rst
.\@
	endm

	macro STALL
.\@
		jp .\@
	endm

	macro FILLTO
\@:
		blk.b \1 - \@, \2
	endm