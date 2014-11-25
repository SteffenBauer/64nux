
#include <system.h>
#include <stdio.h>

        start_of_code equ $1000

        .org start_of_code
        
        .byte >LNG_MAGIC,   <LNG_MAGIC
        .byte >LNG_VERSION, <LNG_VERSION
        .byte >(end_of_code-start_of_code+255)
        .byte >start_of_code

; char[] version_string = "Task info v0.0.5 ";
; printf("%s\n",version_string);
; printf("My internal PID: %2x\n", lk_ipid); // IPID of current process
; printf("My Task super page: %2x%2x\n", lk_tsp+1, lk_tsp); // 16-bit address of Task Super Page
; printf("My memory pages: ");
; for (y=0;y<0x100;y++) {
;     if (lk_memown[y] == lk_ipid) {
;         printf("%2x ", y);
;     }
; }
; printf("\n");
; printf("My zeropage size: %2x\n",lk_tsp[tsp_zpsize]);
; printf("My zeropage content: ");
; zpsize = lk_tsp[tsp_zpsize];
; for (x=0;x<zpsize;x++) {
;     p = x; // fputc changes x-register, save the value
;     printf("%2x ", userzp[x]);  // Zero-page addressing
;     x = p;
; }
; printf("\n");
; return 0;

        ldx  #stdout        ; printf("%s\n",version_string);
        bit t_version
        jsr lkf_strout
        jsr print_newline

        ldx  #stdout        ; printf("My internal PID: ");
        bit t_ipid
        jsr lkf_strout

        lda lk_ipid         ; printf("%2x\n", lk_ipid); // IPID of current process
        jsr print_hex
        jsr print_newline

        ldx  #stdout        ; printf("My Task super page: ");
        bit t_tsp
        jsr lkf_strout

        lda lk_tsp+1        ; printf("%2x%2x\n", lk_tsp+1, lk_tsp); // 16-bit address of Task Super Page
        jsr print_hex
        lda lk_tsp
        jsr print_hex
        jsr print_newline

        ldx  #stdout        ; printf("My memory pages: ");
        bit t_memown
        jsr lkf_strout

        ldy #$00            ; 
    -   lda lk_memown,y     ; for (y=0;y<0x100;y++) {
        cmp lk_ipid         ; 
        bne +               ;     if (lk_memown[y] == lk_ipid) {
        tya                 ;         printf("%2x ", y);
        jsr print_hex       ;     }
        jsr print_space     ; 
    +   iny                 ;
        bne -               ; }
        jsr print_newline   ; printf("\n");

        ldx  #stdout        ; printf("My zeropage size: ");
        bit t_zp
        jsr lkf_strout

        ldy #tsp_zpsize     ; a = lk_tsp[tsp_zpsize];
        lda (lk_tsp),y
        jsr print_hex       ; printf("%2x\n",a);
        jsr print_newline

        ldx  #stdout        ; printf("My zeropage content: ");
        bit t_zp_content
        jsr lkf_strout

        ldy #tsp_zpsize     ; zpsize = lk_tsp[tsp_zpsize];
        lda (lk_tsp),y      ;
        sta count_to+1      ; 
        ldx #$00            ;
    -   txa                 ; for (x=0;x<zpsize;x++) {
        pha                 ;     p = x; // fputc changes x-register, save the value
        lda userzp,x        ;     printf("%2x ", userzp[x]);  // Zero-page addressing
        jsr print_hex       ;
        jsr print_space     ;
        pla                 ;     x = p;
        tax                 ;
        inx                 ;   
count_to:
        cpx #$00            ; 
        bne -               ; }
        jsr print_newline   ; printf("\n");

        ldx  #stdout        ; printf("Memnxt chain: ");
        bit t_memnxt
        jsr lkf_strout

        ldy userzp+1
;        lda lk_memnxt,y
        lda lk_memnxt+$F1
        jsr print_hex
        jsr print_space
        jsr print_newline


        lda #$00
        rts                 ; return 0;

mputc:  
        sec
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
        jmp +
print_lower_hex:
        and  #$0f
    +   tax
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
        
t_version:    .text "Task info v0.0.5 ", $00
t_ipid:       .text "My internal PID: ", $00
t_tsp:        .text "My Task super page: ", $00
t_memown:     .text "My memory pages: ", $00
t_zp:         .text "My zeropage size: ", $00
t_zp_content: .text "My zeropage content: ", $00
t_memnxt:     .text "Memnxt chain: ", $00

end_of_code:

