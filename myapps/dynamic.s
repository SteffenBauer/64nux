#include <system.h>
#include <stdio.h>

        start_of_code equ $1000

        .org start_of_code
        
        .byte >LNG_MAGIC,   <LNG_MAGIC
        .byte >LNG_VERSION,    <LNG_VERSION
        .byte >(end_of_code-start_of_code+255)
        .byte >start_of_code

;;  dynamic linked list library
;;  designed for LUnix ed

;;  Public API:
;;
;;  init                Initialize memory structure
;;  free                Free whole memory structure
;;  print_memory        Print memory structure
;;  insert_element      Insert an element at position X
;;  delete_element      Delete element at position X

;;  Private functions:
;;
;;  _get_element_pos    Get position (byte/page) of element N
;;  _get_next_byte      Get next byte in memory structure
;;  _get_before_byte    Get byte before in memory structure
;;  _get_last_page      Get last memory page in structure
;;  _get_before_page    Get memory page before X
;;  _allocate_page      Allocate a new page at end of memory structure
;;  _clear_page         Fill a page with $00
;;  _delete_page        Deallocate last page in memory strucutre

;;  I/O Helper functions:
;;
;;  _any_key            Wait for keypress
;;  print_hex           Print A in hexadecimal to console
;;  mputc               Print A as raw char to console
;;  print_char          Print A as char to console, only printable characters




;; Zeropage
zp_start_page      equ userzp+0
zp_last_page       equ userzp+1
zp_last_byte       equ userzp+2
zp_page_pointer    equ userzp+3     ;; 16-bit
zp_compare         equ userzp+5
zp_current_page    equ userzp+6
zp_current_byte    equ userzp+7
zp_buffer_pointer  equ userzp+8     ;; 16-bit

;;
PAGESIZE        equ $20
PRINTSIZE       equ $07


        ldx  userzp+1                   ; address of commandline (hi byte)
        jsr  lkf_free                   ; free used memory
                                        ; (commandline not needed any more)
        lda  #$0a
        jsr  lkf_set_zpsize             ; 6 byte of userzp

        jsr  init
        jsr  print_memory
        jsr  _any_key
        
        jsr  _allocate_page
        jsr  print_memory
        jsr  _any_key
        
        jsr  free
        jsr  print_memory
        jsr  _any_key
        
        lda #$00
        rts

        RELO_JMP(init)

;; init
;; Init memory list
;; 
;; > none
;; < userzp = first allocated page
;; < userzp+1 = 0 (last_byte = 0 for fresh page)
;; < lk_memnxt,start_page = #$01 (start_page is last page in page chain)
;; Affects: A,X
init:
        ldx  lk_ipid     ; allocate memory for this process
        ldy  #$80        ; no I/O
        jsr  lkf_spalloc
        bcs  +
        stx  zp_start_page
        stx  zp_last_page
        lda  #$00
        sta  zp_last_byte
        lda  #$01
        sta  lk_memnxt,x
        jsr  _clear_page
        rts
    +   ldx  #stdout
        bit  err_no_memory
        jsr  lkf_strout
        lda  #1
        rts

;; free
;; Free memory list
;;
;; > none
;; < none
;; Affects: A,X
free:
    -   ldx  zp_start_page
        lda  lk_memnxt,x
        cmp  #$01
        beq  +
        sta  zp_start_page
        jsr  lkf_free 
        jmp  -
    +   lda  #$01
        sta  zp_start_page
        sta  zp_last_page
        lda  #$00
        sta  zp_last_byte
        rts


;; print_memory
;;
print_memory:
        ldx  #stdout
        bit  txt_start_page
        jsr  lkf_strout
        lda  zp_start_page
        jsr  print_hex
        lda  #$20
        jsr  mputc

        bit  txt_last_page
        jsr  lkf_strout
        lda  zp_last_page
        jsr  print_hex
        lda  #$0a
        jsr  mputc
        
        bit  txt_last_byte
        jsr  lkf_strout
        lda  zp_last_byte
        jsr  print_hex
        lda  #$0a
        jsr  mputc

        lda  zp_start_page
        sta  zp_current_page
    -   cmp  #$01
        bne  +
        rts

    +   ldx  #stdout
        bit  txt_current_page
        jsr  lkf_strout
        lda  zp_current_page
        jsr  print_hex
        lda  #$20
        jsr  mputc

        bit  txt_next_page
        jsr  lkf_strout
        ldy  zp_current_page
        lda  lk_memnxt,y
        jsr  print_hex
        lda  #$0a
        jsr  mputc

        lda  zp_current_page
        sta  zp_page_pointer+1
        lda  #$00
        sta  zp_page_pointer
        ldy  #$00

    -   lda  (zp_page_pointer),y
        jsr  print_hex
        lda  #$20
        jsr  mputc
        iny
        tya
        and  #PRINTSIZE
        bne -

        tya
        clc
        sbc  #PRINTSIZE
        tay
        
    -   lda  (zp_page_pointer),y
        jsr  print_char
        iny
        tya
        and  #PRINTSIZE
        bne -

        lda  #$0a
        jsr  mputc
        cpy  #PAGESIZE
        bne  --
        
        ldy  zp_current_page
        lda  lk_memnxt,y
        sta  zp_current_page
        jmp ---

;;  insert_element
;;
;;  

insert_element:




;; Internal (private) functions

;; _get_element_pos
;;
;; > X: Element to retrieve
;; < Y: Byte position
;; < X: Page position
;; < Carry=1: Element N does not exist
_get_element_pos:
        lda  #$00
        sta  zp_current_byte
        sta  zp_page_pointer
        lda  zp_start_page
        sta  zp_current_page
    -   lda  zp_current_byte
        cmp  zp_last_byte
        bcc  +
        lda  zp_current_page
        cmp  zp_last_page
        bne  +
        sec
        rts
    +   lda  zp_current_page
        sta  zp_page_pointer+1
        ldy  zp_current_byte
        lda  (zp_page_pointer),y
        clc
        adc  zp_current_byte
        sta  zp_current_byte
        cmp  #PAGESIZE
        bcc  +
        sec
        sbc  #PAGESIZE
        sta  zp_current_byte
        ldy  zp_current_page
        lda  lk_memnxt,y
        sta  zp_current_page
    +   dex
        bne  -
        ldx  zp_current_page
        ldy  zp_current_byte
        rts

;; _allocate_page
;;
;; < Carry=1: Out of memory
_allocate_page:

        ldx  lk_ipid     ; allocate memory for this process
        ldy  #$80        ; no I/O
        jsr  lkf_spalloc
        bcs  +
        lda  #$01
        sta  lk_memnxt,x
        stx  zp_current_page
        stx  zp_last_page
        jsr  _clear_page
        jsr  _get_last_page
        lda  zp_current_page
        sta  lk_memnxt,x
        clc
    +   rts

;; _clear_page
;;
;; > X: Page to be cleared
_clear_page:
        lda  lk_ipid
        cmp  lk_memown,x		; does this page belong to us?
        bne  +
        cpx  lk_tsp+1			; we must not clear our TSP
        beq  +
        stx  zp_page_pointer+1
        lda  #$00
        sta  zp_page_pointer
        ldy  #$00
     -  sta  (zp_page_pointer),y
        iny
        bne  -
        rts
    +   ldx  #stdout
        bit  err_illegal_page
        jsr  lkf_strout
        rts

;; _get_last_page
;;
;; > none
;; < X: last page
;; Affects: X,A
_get_last_page:
        ldx  zp_start_page
        cmp  #$01
        beq  +
    -   lda  lk_memnxt,x
        cmp  #$01
        beq  +
        tax
        jmp  -
    +   rts

;; _get_page_before
;;
;; > X: current page
;; < X: page_before
;; < Carry=1: No page before
;; Affects: Y,A
_get_page_before:
        stx  zp_compare
        ldy  zp_start_page
        cmp  #$01
        sec
        beq  +
    -   lda  lk_memnxt,x
        cmp  zp_compare
        beq  +
        jmp  -
        tax
        clc
    +   rts

;; _get_next_byte
;;
;; < Y: next_byte
;; < X: next_page
;;
;; > Y: current_byte
;; > X: current_page
;; Affects: A
_get_next_byte:
        iny
        cpy  #PAGESIZE
        beq  +
        rts
        ldy  #$00
    +   lda  lk_memnxt,x
        tax
        rts

;; _get_before_byte
;;
;; < Y: before_byte
;; < X: before_page
;;
;; > Y: current_byte
;; > X: current_page
;; Affects: A
_get_before_byte:
        cpy  #$00
        bne  +
        jsr  _get_page_before
        ldy  #PAGESIZE
    +   dey
        rts



;;
;;----------------------------
;;  Helper functions (mainly I/O)
;;----------------------------
;;
_any_key:
        ldx  #stdout
        bit  txt_press_any_key
        jsr  lkf_strout
        ldx  #stdin
        sec
        jsr  fgetc
        rts

mputc:  
        sec
        ldx  #stdout
        jsr  fputc
        rts

print_char:
        cmp  #$20
        bcs  +
        lda  #"."
    +   sec
        ldx  #stdout
        jsr  fputc
        rts

print_hex:
        pha
        jsr  __print_upper_hex
        pla
        jmp  __print_lower_hex

__print_upper_hex:
        lsr a 
        lsr a
        lsr a
        lsr a
        tax
        lda  hextab,x
        jmp  mputc

__print_lower_hex:
        and  #$0f
        tax  
        lda  hextab,x
        jmp  mputc

        RELO_END ; no more code to relocate

hextab:
        .text "0123456789ABCDEF"

err_no_memory:
        .text "Out of memory",$0a,$00
err_illegal_page:
        .text "Error: Clearing illegal page ", $0a, $00

txt_press_any_key:
        .text "Press any key", $0a,$00
txt_current_page:
        .text "Current page: ",$00
txt_start_page:
        .text "Start page:   ",$00
txt_last_page:
        .text "Last page:   ",$00
txt_last_byte:
        .text "Last byte: ",$00
txt_next_page:
        .text "Next page: ",$00

end_of_code:

