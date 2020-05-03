; 68k <-> z80 comm defines

; comm test
COMM_TEST_HELLO			equ $c3		; z80 -> 68k
COMM_TEST_HANDSHAKE		equ $5a		; 68k -> z80
COMM_TEST_ACK			equ $3c		; z80 -> 68k

; z80 -> 68k indicating all tests are complete
COMM_Z80_TESTS_COMPLETE		equ $e7
