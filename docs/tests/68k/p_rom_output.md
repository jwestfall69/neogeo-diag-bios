# P ROM Output Tests

This test requires a custom diag prog board.

The purpose of these tests is to determine if the P roms are outputing data when asked.  Depending on which motherboard type you have the data path between the P roms and the CPU maybe direct or there could be ICs in between.

If an output issue is detected it will result in one of the follow errors:

|  Hex  | Number | Beep Code |  Credit Leds  | Error Text |
| ----: | -----: | --------: | :-----------: | :--------- |
|  0x89 |    137 |       N/A |           N/A | P1 or 245/G0/BUF DEAD OUPUT (LOWER) |
|  0x8a |    138 |       N/A |           N/A | P1 or 245/G0/BUF DEAD OUPUT (UPPER) |
|  0x8b |    139 |       N/A |           N/A | P2 or 245/G0/BUF DEAD OUPUT (LOWER) |
|  0x8c |    140 |       N/A |           N/A | P2 or 245/G0/BUF DEAD OUPUT (UPPER) |
|  0x8d |    141 |       N/A |           N/A | P1 DEAD OUPUT (LOWER) |
|  0x8e |    142 |       N/A |           N/A | P1 DEAD OUPUT (UPPER) |
|  0x8f |    143 |       N/A |           N/A | P2 DEAD OUPUT (LOWER) |
|  0x90 |    144 |       N/A |           N/A | P2 DEAD OUPUT (UPPER) |

The first 4 error messages are indicating whatever is directly connect to the CPU is not outputting any data.

The latter 4 errors are for boards the have a single IC between the P roms and the CPU.  The test will detect when the P rom is not outputing any data.

Additional failure testing is needed to fully understand what happens for boards with multiple IC's between the P roms and CPU.