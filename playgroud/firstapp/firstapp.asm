.segment "HEADER"
.byte "NES"
.byte $1a
.byte $02 ; 2 * 16kb prg rom
.byte $01 ; 1 * 8kb chr rom
.byte %00000000 ; mapper and mirroring 
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00, $00, $00, $00, $00 ; filler bytes

.segment "STARTUP"

.segment "CODE"

RESET:
    SEI
    CLD

    LDX #$40
    STX $4017

    LDX #$FF
    TXS

    INX

    STX $2000    ; disable NMI
    STX $2001    ; disable rendering
    STX $4010    ; disable DMC IRQs

VBLANKWAIT1:
    BIT $2002
    BPL VBLANKWAIT1

CLEARMEM:
    STA $0000, X ; $0000 => $00FF
    STA $0100, X ; $0100 => $01FF
    STA $0300, X
    STA $0400, X
    STA $0500, X
    STA $0600, X
    STA $0700, X
    LDA #$FF
    STA $0300, X
    LDA #$00
    INX
    BNE CLEARMEM

VBLANKWAIT2:
    BIT $2002
    BPL VBLANKWAIT2

    LDA #%00100000
    STA $2001

FOREVER:
    JMP FOREVER

NMI:
    RTI

.segment "VECTORS"
    .word NMI
    .word RESET
    .word 0

.segment "CHARS"
;    .incbin "mario.chr"