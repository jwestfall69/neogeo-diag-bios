MEMORY {
	VECTORS: org=0xc00000, len=0x80
	ROM: org=0xc00080, len=0x7f7b
	FOOTER: org=0xc07ffb, len=0x5 
}

SECTIONS {
	.vectors: {
		*(vectors)
	} >VECTORS

	.rom: {
		*(text)
	} >ROM

	.footer: {
		*(footer)
	} >FOOTER
}
