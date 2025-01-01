MEMORY {
	ROM: org=0x0000, len=0x800
	RAM: org=0xf800, len=0x800
}

SECTIONS {
	.vectors 0x0: {
		*(vectors)
	} > ROM
	.code 0x80: {
		*(code)
	} > ROM
	.rodata: {
		*(data)
	} > ROM
	.footer 0x07fb: {
		*(footer)
	} > ROM
	.bss (NOLOAD): {
		*(bss)
	} > RAM
}
