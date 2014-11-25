    ;; for emacs: -*- MODE: asm; tab-width: 4; -*-
    ;; meminfo - simple memory usage report
    
#include <system.h>
#include <stdio.h>

        start_of_code equ $1000

        .org start_of_code
        
        .byte >LNG_MAGIC,   <LNG_MAGIC
        .byte >LNG_VERSION,    <LNG_VERSION
        .byte >(end_of_code-start_of_code+255)
        .byte >start_of_code


    ;; print lower nybble info line
        jsr  print_newline
        jsr  print_space
        jsr  print_space
        jsr  print_space
        ldy  #$F0
    -   tya
        jsr  print_lower_hex
        iny
        bne -
        jsr  print_space
        jsr  print_space
        jsr  print_space
        ldy  #$F0
    -   tya
        jsr  print_lower_hex
        iny
        bne -
        jsr  print_newline
        jsr  print_newline

    ;; print in-shifted char map
        ldy  #$20
    -   lda  #$1f       ; shift in
        jsr  mputc
        jsr  print_space
        tya
        jsr  print_upper_hex
        jsr  print_space

        jsr print_chars

        tya
        clc
        sbc #$0f
        tay

        jsr  print_space
        jsr  print_space
        jsr  print_space
        jsr  activate_reverse
        jsr print_chars
        jsr  deactivate_reverse
        jsr  print_newline
        tya
        cmp  #$80
        bne  -

        jsr  print_newline

    ;; print out-shifted char map
        ldy  #$20
    -   lda  #$1f       ; shift in
        jsr  mputc
        jsr  print_space
        tya
        jsr  print_upper_hex
        jsr  print_space

        lda  #$1e       ; shift out
        jsr  mputc
        jsr print_chars
        tya
        clc
        sbc #$0f
        tay

        jsr  print_space
        jsr  print_space
        jsr  print_space
        jsr  activate_reverse
        jsr  print_chars
        jsr  deactivate_reverse

        jsr print_newline
        tya
        cmp  #$80
        bne  -

        jsr  print_newline

        lda  #$1f       ; restore console
        jsr  mputc
        jsr  deactivate_reverse
        lda  #0
        rts

print_chars:
    -   tya
        jsr  mputc
        iny
        tya
        and  #$0f
        bne  -
        rts

mputc:  
        sec
        ldx  #stdout
        jsr  fputc
        rts

print_upper_hex:
        and  #$f0
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

activate_reverse:
        lda #$1b ; ESC
        jsr mputc
        lda #$5b ; [
        jsr mputc
        lda #$07 ; Parameter 7
        jsr mputc
        lda #$6d ; m
        jmp mputc

deactivate_reverse:
        lda #$1b ; ESC
        jsr mputc
        lda #$5b ; [
        jsr mputc
        lda #$6d ; m
        jmp mputc


        RELO_END ; no more code to relocate
        
hextab:
        .text "0123456789ABCDEF"

end_of_code:

