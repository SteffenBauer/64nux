
#include <system.h>
#include <stdio.h>

        start_of_code equ $1000

        .org start_of_code
        
        .byte >LNG_MAGIC,   <LNG_MAGIC
        .byte >LNG_VERSION,    <LNG_VERSION
        .byte >(end_of_code-start_of_code+255)
        .byte >start_of_code

    ;; print memory map
        lda userzp+1
        sta mempage_pointer+2
        ldy  #0
    -   jsr  print_space
        tya
        jsr  print_upper_hex
        jsr  print_space
mempage_pointer:
    -   lda $F000,y
        jsr mputc
;;        jsr print_hex
        iny
        tya
        and  #$0f
        bne  -
        jsr print_newline
        tya
        bne  --

        rts

mputc:  
        cmp #$20
        bcs +
        cmp #$0a:
        beq +
        lda #"."
    +   sec
        ldx  #stdout
        jsr  fputc
        rts

print_hex:
        pha
        jsr print_upper_hex
        pla
        jmp print_lower_hex

print_upper_hex:
        lsr a 
        lsr a
        lsr a
        lsr a
        tax
        lda  hextab,x
        jmp  mputc

print_lower_hex:
        and  #$0f
        tax  
        lda  hextab,x
        jmp  mputc

print_space:
        lda  #" "
        jmp  mputc

print_newline:
        lda  #$0a
        jmp  mputc

        RELO_END ; no more code to relocate

hextab:
        .text "0123456789ABCDEF"


end_of_code:

