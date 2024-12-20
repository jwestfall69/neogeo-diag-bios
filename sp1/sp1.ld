MEMORY {
	ROM: org=0xc00000, len=0x8000
	RAM: org=0x100000, len=0x10000
}

SECTIONS {
	.vectors 0xc00000: {
		*(vectors)
	} > ROM
	.code 0xc00080: {
		*(code)
	} > ROM
	.data: {
		*(data)
	} > ROM
	.error_addresses 0xc06000: {
		*(error_addresses)
	} > ROM
	.footer 0xc07ffb: {
		*(footer)
	} > ROM
	.bss (NOLOAD): {
		*(bss)
	} > RAM
}
