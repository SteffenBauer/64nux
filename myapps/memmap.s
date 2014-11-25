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
        jsr  print_newline
        jsr  print_newline

    ;; print memory map
        ldy  #0
    -   jsr  print_space
        tya
        jsr  print_upper_hex
        jsr  print_space

    -   lda  lk_memown,y
        jsr  print_owner

        iny
        tya
        and  #$0f
        bne  -
        jsr print_explanation
;;      jsr print_newline
        tya
        bne  --

;;        jsr  print_newline
;;        ldx  #stdout
;;        bit  explanation
;;        jsr  lkf_strout
        jsr  print_newline
        
        lda  #0
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


		;; Prints the owner/usage of a single memory page
		;; < A = memown
		;; < Y = page
		;; changes: X,A
print_owner:
        cmp  #$20
        bcc  p_task
        cmp  #memown_smb
        beq  p_smb
        cmp  #memown_cache
        beq  p_cache
        cmp  #memown_sys
        beq  p_sys
        cmp  #memown_modul
        beq  p_modul
        cmp  #memown_scr
        beq  p_scr
        cmp  #memown_netbuf
        beq  p_netbuf
        cmp  #memown_none
        beq  p_none

        lda  #"?"
        jmp  mputc
p_task:    
        lda  #"T"
        jmp  mputc
p_smb:    
        lda  #"B"
        jmp  mputc
p_cache:
        lda  #"C"
        jmp  mputc
p_sys:    
        lda  #"K"
        jmp  mputc
p_modul:
        lda  #"M"
        jmp  mputc
p_scr:    
        lda  #"S"
        jmp  mputc
p_netbuf:    
        lda  #"N"
        jmp  mputc
p_none:
        tya
        pha
        and  #$07
        tax
        tya
        lsr a
        lsr a
        lsr a
        tay
        lda  lk_memmap,y
        cpx  #$00
        beq +
    -   asl a
        dex
        bne -
    +   asl a
        pla 
        tay
        bcc  p_reserved
        lda  #"."
        jmp  mputc
p_reserved:
        lda  #"X"
        jmp  mputc

print_explanation:
        jsr print_space
        jsr print_space
        jsr print_space
        tya
        pha
        lsr a
        lsr a
        lsr a
        lsr a
        tax
        ldy #$00
        dex
explanation_loop:
        cpx #$00
        beq exp_output
        lda explanation,y
        cmp #$FF
        beq end_exp_output
        cmp #$00
        bne +
        dex
    +   iny
        jmp explanation_loop
exp_output:
        lda explanation,y
        beq end_exp_output
        cmp #$FF
        beq end_exp_output
        jsr mputc
        iny
        jmp exp_output
end_exp_output:
        pla
        tay
        jmp print_newline


        RELO_END ; no more code to relocate

hextab:
        .text "0123456789ABCDEF"

explanation:
        .text "X = System",    $00
        .text "S = Screen",    $00
        .text "K = Kernel",    $00
        .text "B = SMB",       $00
        .text "C = Cache",     $00
        .text "N = Netbuffer", $00
        .text "T = Task",      $00
        .text "? = Unknown",   $00
        .text ". = Free",      $00
        .byte $FF

;;        .text " X = System,    S = Screen, K = Kernel", $0a
;;        .text " B = SMB,       C = Cache,  M = Module", $0a
;;        .text " N = Netbuffer, T = Task,   ? = Unknown",$0a,$00

end_of_code:

