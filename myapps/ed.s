    ;; for emacs: -*- MODE: asm; tab-width: 4; -*-
    ;; meminfo - simple memory usage report
    
#include <system.h>
#include <stdio.h>
#include <kerrors.h>


        start_of_code equ $1000

        .org start_of_code
        
        .byte >LNG_MAGIC,   <LNG_MAGIC
        .byte >LNG_VERSION,    <LNG_VERSION
        .byte >(end_of_code-start_of_code+255)
        .byte >start_of_code

        lda  #4
        jsr  lkf_set_zpsize
        
        ldx lk_ipid     ; allocate memory for this
        ldy #$80        ; no I/O
        jsr lkf_spalloc
        bcs err_no_memory

        lda #$00
        sta userzp
        stx userzp+1
        ldy #$20
        
        jsr sreadline
        bcs +
        jsr print_buffer
        jsr sreadline
        bcs +
        jsr print_buffer

    +   ldx userzp+1
        jsr lkf_free    ; free buffer memory
        lda  #0
        rts

err_no_memory:
        jsr  print_newline
        ldx  #stdout
        bit  error_no_memory
        jsr  lkf_strout
        jsr  print_newline
        lda  #1
        rts

print_newline:
        lda  #$0a
        jmp  mputc

print_buffer:
        ldy #$00
    -   lda (userzp),y
        beq +
        jsr mputc
        iny
        jmp -
    +   jmp print_newline


mputc:  
        sec
        ldx  #stdout
        jsr  fputc
        rts



        ;; sreadline
        ;; 
        ;;  < userzp=pointer to buffer
        ;;    Y=length of buffer (up to 255 chars)
        ;; 
        ;;  > c=1 :    A=errorcode (maybe just EOF)
        ;;    c=0 :    Y=length of line
        
sreadline:
        dey
        sty  len_limit
        ldy  #0

    -    sec
        ldx  #stdin
        jsr  fgetc
        bcs  io_error

        cmp  #10                ; newline
        beq  _eol
        cmp  #8                    ; backspace
        beq  _backspc
        cmp  #32
        bcc  -                    ; ignore all <32
        
        cpy  len_limit
        beq  -                    ; skip if buffer is already filled up
        sta  (userzp),y
        sec
        ldx  #stdout
        jsr  fputc
        bcs  catcherr
        iny
        bne  -

_eol:    lda  #0
        sta  (userzp),y
        lda  #10
        sec
        ldx  #stdout
        jsr  fputc
        bcs  catcherr
        rts

io_error:
        cmp  #lerr_eof
        beq  io_eof

catcherr:
        jmp  lkf_catcherr

_backspc:
        cpy  #0
        beq  -                    ; ignore backspaces, when len=0
        sec
        ldx  #stdout
        jsr  fputc
        bcs  catcherr
        dey
        jmp  -
        
io_eof:    tya
        bne  _eol                ; EOF is newline, if line is not empty
        lda  #lerr_eof
        jmp  catcherr

        RELO_END ; no more code to relocate

len_limit:        
        .buf 1

error_no_memory:
        .text "Out of memory",$0a,$00

end_of_code:

