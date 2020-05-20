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

	; The call instruction uses an absolute address.  This
	; macro adjusts this address for functions that we copied
	; into ram for sm1 tests.
	macro RCALL
		call Z80_RAM_START + (\1 - SM1_TEST_CODE_START)
	endm

	macro STALL
.\@
		jp .\@
	endm