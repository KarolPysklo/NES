.segment "HEADER"
.byte "NES"
.byte $1a
.byte $02
.byte $01
.byte %00000000
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00, $00, $00, $00, $00 ; filler byte

.segment "STARTUP"

.segment "ZEROPAGE" ; - 255 bytes of memory 9x00 - 0xff (less cycles)

buttons:
    .res %01, $00

; .segment "RODATA" - the segment used for readonly data

.segment "CODE"

BUTTON_A      = 1 << 7
BUTTON_B      = 1 << 6
BUTTON_SELECT = 1 << 5
BUTTON_START  = 1 << 4
BUTTON_UP     = 1 << 3
BUTTON_DOWN   = 1 << 2
BUTTON_LEFT   = 1 << 1
BUTTON_RIGHT  = 1 << 0


VBLANKWAIT:
    BIT $2002
    BPL VBLANKWAIT
    RTS

ReadController:
    ; latch buttons for both controllers
    LDA #$01
    STA $4016
    LDA #$00
    STA $4016
    LDX #$08
ReadControllerLoop:
    LDA $4016
    LSR A            ; bit0 -> Carry
    ROL buttons     ; bit0 <- Carry
    DEX
    BNE ReadControllerLoop
    RTS

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

    JSR VBLANKWAIT

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

    JSR VBLANKWAIT


    LDA #%00100000
    STA $2001

LoadPalettes:
    ; The palettes start at PPU address $3F00 and $3F10
    ; To set this address, PPU address port $2006 is used.
    ; This post must be written twice, once for high byte then for the low byte

    LDA $2002   ;read PPU status to reset the high/low latch to high
    LDA #$3F
    STA $2006   ; write the high byte of $3F10 address
    LDA #$10
    STA $2006   ; write the low byte of $3F10 address


    LDX #$00
LoadPalettesLoop:
    LDA PaletteData, x
    STA $2007   ; VRAM I/O Register - ; write to PPU
    INX
    CPX #$20
    BNE LoadPalettesLoop

; ; Sprite data - 4 bytes of data 
; ;   1. Y-positon 
; ;   2. Title Number
; ;   3. Attributs - this byte holds color and displaying information
; ;   4. X-position
; ;
; ; e.g. Sprite 0
; ;        LDA #$80
; ;        STA $0200

; ;        LDA #$00
; ;        STA $0201

; ;        LDA #$00
; ;        STA $0202

; ;        LDA #$80
; ;        STA $0203

    LDX #$00
LoadSprites:
    LDA Sprites, x
    STA $0200, x
    INX
    CPX #$10
    BNE LoadSprites

;;;;;

    LDA #%10000000 ; enable NMI, sprites from Pattern Table 0
    STA $2000   ; $2000 PPU Control Register 1 - PPUCTRL ($2000)

    LDA #%00010000 ; no intensify (black background), enable sprites
    STA $2001   ; $2001 PPU Control Register 2 - PPUMASK ($2001)

FOREVER:
    JMP FOREVER

NMI:

    LDA #$00
    STA $2003 ; set the low byte (00) of the RAM address
    LDA #$02
    STA $4014  ; set the high byte (02) of the RAM address, start the transfer


    JSR ReadController
    
    LDA buttons
    AND #BUTTON_A
    ; LDA $4016       ; player one (4016) button A
    ; AND #%00000001  ; first bit
    BEQ ReadADone   ; branch on result zero (button not pressed)
                    ; if button is pressed continue

    LDA $0203       ; load horizontal position of the first sprite
    CLC             ; CLear Carry flag in status register - (usually this should be done before ADC)
    ADC #$01        ; A += 1
    STA $0203       ; save horizontal position of the first sprite

    LDA $0207
    CLC
    ADC #$01
    STA $0207

    LDA $020B
    CLC
    ADC #$01
    STA $020B

    LDA $020F
    CLC
    ADC #$01
    STA $020F
ReadADone:

ReadB:
    LDA buttons
    AND #BUTTON_B
    BEQ ReadBDone

    LDA $0203
    SEC             ; SEt Carry flag in status register (usually this should be done before SBC)
    SBC #$01        ; A -= 1
    STA $0203

    LDA $0207
    SEC
    SBC #$01
    STA $0207

    LDA $020B
    SEC
    SBC #$01
    STA $020B

    LDA $020F
    SEC
    SBC #$01
    STA $020F
ReadBDone:


    RTI

PaletteData:
    .byte $22,$16,$27,$18,$22,$16,$27,$18,$22,$16,$27,$18,$22,$16,$27,$18
    .byte $22,$16,$27,$18,$22,$36,$17,$0f,$22,$30,$21,$0f,$22,$27,$17,$0F  ;background palette data
  ;sprite palette data
;    .byte $0F,$31,$32,$33,$0F,$35,$36,$37,$0F,$39,$3A,$3B,$0F,$3D,$3E,$0F  ;background palette data
;    .byte $0F,$1C,$15,$14,$0F,$02,$38,$3C,$0F,$1C,$15,$14,$0F,$02,$38,$3C  ;sprite palette data

Sprites:
         ;vert tile attr horiz
    .byte $80, $32, $06, $80   ;sprite 0
    .byte $80, $33, $02, $88   ;sprite 1
    .byte $88, $34, $02, $80   ;sprite 2
    .byte $88, $35, $02, $88   ;sprite 3

.segment "VECTORS"
    .word NMI
    .word RESET
    .word 0

.segment "CHARS"
    .incbin "mario.chr"


