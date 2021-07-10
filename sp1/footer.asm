        section footer,data

        	; these get filled in by gen-crc-mirror
		dc.b 	$00			; bios mirror, $00 is running copy, $01 1st copy, $02 2nd, $03 3rd
		dc.b 	$00,$00,$00,$00		; bios crc32 value calculated from bios_start to $c07ffb
