MEMORY {
	VECTORS: org=0xc00000, len=0x80
	ROM: org=0xc00080, len=0x5f80
	ERR: org=0xc06000, len=0x1ffb
	FOOTER: org=0xc07ffb, len=0x5 
}

SECTIONS {
	.vectors: {
		*(vectors)
	} >VECTORS

	.rom: {
		*(text)
	} >ROM

	.error_addresses: {
		*(error_addresses)
	} >ERR

	.footer: {
		*(footer)
	} >FOOTER
}
