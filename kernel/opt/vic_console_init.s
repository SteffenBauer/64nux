;; for emacs: -*- MODE: asm; tab-width: 4; -*-
	
#include <console.h>

	-	jmp  lkf_panic

		;; initialise console driver
		;; (and set lk_consmax value)

console_init:
		;; allocate memory at $c000-$c3ff
		jsr  lkf_locktsw
		lda  lk_memmap+$18		; check if memory is unused
		and  #$f0
		cmp  #$f0
		bne  -					; (if not, panic)
		lda  #4					; number of pages
		ldx  #>screenA_base		; start page
		ldy  #memown_scr		; usage ID
		sta  tmpzp
		stx  tmpzp+3
		sty  tmpzp+4
		jsr  lkf__raw_alloc		; (does unlocktsw)

#ifdef MULTIPLE_CONSOLES
		;; try to allocate second console at $c400-$c7ff
		jsr  lkf_locktsw
		lda  lk_memmap+$18		; check if memory is unused
		and  #$0f
		cmp  #$0f
		bne  -					; (if not, panic)
		lda  #4					; number of pages
		ldx  #>screenB_base		; start page
		ldy  #memown_scr		; usage ID
		sta  tmpzp
		stx  tmpzp+3
		sty  tmpzp+4
		jsr  lkf__raw_alloc		; (does unlocktsw)

		lda #0				; initialize fs_cons stuff
		sta usage_map

		lda  #MAX_CONSOLES			; we have 2 consoles
#else
		lda  #1					; we have just 1 console		
#endif
		sta  lk_consmax

        ;; copy charrom
        sei                     ; disable interrupts while we copy
        ldx #$03                ; we loop 4 times (8*$80 = 4*$100)
        lda #$03                ; make the CPU see the Character Generator ROM...
        sta $01                 ; ...at $D000 by storing %00110011 into location $01
        lda #>charmap           ; load high byte of charmap
        sta tmpzp+1             ; store it in a free location we use as vector
        lda #<charmap
        sta tmpzp
        lda #$d0                ; Copy normal charmap to $D000
        sta tmpzp+3
        lda #$d4                ; Copy inverse charmap to $D400
        sta tmpzp+5
        ldy #$00                ; init counter with 0
        sty tmpzp+2             ; store it as low byte in the $FB/$FC vector
        sty tmpzp+4
     -  lda (tmpzp),y           ; read byte from vector stored in charmap
        sta (tmpzp+2),y         ; write to the RAM under ROM at same position
        eor #$FF                ; inverse it
        sta (tmpzp+4),y         ; and write the inverse charmap
        iny                     ; do this 255 times...
        bne -                   ; ..for low byte $00 to $FF
        inc tmpzp+1             ; when we passed $FF increase high byte...
        inc tmpzp+3
        inc tmpzp+5
        dex                     ; ... and decrease X by one before restart
        bpl -                   ; We repeat this until X becomes Zero

;        ldx #$07
;    -   lda backslash,x
;        sta $d000+$3f8,x
;        lda curlleft,x
;        sta $d000+$398,x
;        lda curlright,x
;        sta $d000+$358,x
;        dex
;        bpl -

        lda #$05    ; switch in I/O mapped registers again...
        sta $01     ; ... with %00110111 so CPU can see them
        cli



		lda #0				; initialize fs_cons stuff
		sta usage_count

		;; initialize VIC
		lda  CIA2_PRA
		and  #$FC
		sta  CIA2_PRA			; select bank 3
		lda  #0
		sta  VIC_SE				; disable all sprites
		lda  #$9b
		sta  VIC_YSCL			
		lda  #$08
		sta  VIC_XSCL
		lda  #0
		sta  VIC_CLOCK

#ifdef MULTIPLE_CONSOLES
		lda  #>screenA_base
		sta  sbase

		lda  #0
		sta  current_output		; output goes to first console
		lda  #1					; default is console 1 (at $0400)
		jsr  lkf_console_toggle		; (replaces "jsr  do_cons1")
#else
		lda  #$04
		sta  VIC_VSCB			; make console visible		
#endif

		;; set 'desktop' color
		lda  #0
		sta  VIC_BC				; border color
		lda  #11
		sta  VIC_GC0			; background color

		lda  #$80
		sta  cflag				; cursor enabled (not yet drawn)
		lda  #0
		sta  esc_flag
		sta  rvs_flag
		sta  scrl_y1
		lda  #24
		sta  scrl_y2
		jsr  lkf_cons_home

#ifdef MULTIPLE_CONSOLES
		;; clone screen-status (mapl/(h), csrx/y, cflag, scrl_y1/2)
		ldx  #8
	-	lda  mapl,x
		sta  lkf_cons_regbuf,x
		dex
		bpl  -

		lda  #>screenB_base
		sta  sbase
		sta  maph
		sta  lkf_cons_regbuf+1				; (maph!)
		jsr  lkf_cons_clear		; clear second console

		lda  #>screenA_base
		sta  sbase
		sta  maph
#endif

		jsr  lkf_cons_clear		; clear first console

		;; print startup message
		ldx  #0
	-	lda  start_text,x
		beq  +
		jsr  lkf_printk
		inx
		bne  -

	+	rts

start_text:
#ifdef MULTIPLE_CONSOLES
		.text "VIC consoles (v1.1) @ $C000,$C400",$0a,0
#else
		.text "VIC console (v1.1) @ $400",$0a,0
#endif

charmap:    .byte $00,$00,$00,$00,$00,$00,$00,$00  ; Space
            .byte $18,$18,$18,$18,$00,$00,$18,$00  ; !
            .byte $66,$66,$66,$00,$00,$00,$00,$00  ; "
            .byte $66,$66,$ff,$66,$ff,$66,$66,$00  ; #
            .byte $18,$3e,$60,$3c,$06,$7c,$18,$00  ; $
            .byte $62,$66,$0c,$18,$30,$66,$46,$00  ; %
            .byte $3c,$66,$3c,$38,$67,$66,$3f,$00  ; &
            .byte $18,$18,$18,$00,$00,$00,$00,$00  ; '
            .byte $0c,$18,$30,$30,$30,$18,$0c,$00  ; (
            .byte $30,$18,$0c,$0c,$0c,$18,$30,$00  ; )
            .byte $00,$66,$3c,$ff,$3c,$66,$00,$00  ; *
            .byte $00,$18,$18,$7e,$18,$18,$00,$00  ; +
            .byte $00,$00,$00,$00,$00,$18,$18,$30  ; ,
            .byte $00,$00,$00,$7e,$00,$00,$00,$00  ; -
            .byte $00,$00,$00,$00,$00,$18,$18,$00  ; .
            .byte $00,$03,$06,$0c,$18,$30,$60,$00  ; /

            .byte $3c,$66,$6e,$76,$66,$66,$3c,$00  ; 0
            .byte $18,$18,$38,$18,$18,$18,$7e,$00  ; 1
            .byte $3c,$66,$06,$0c,$30,$60,$7e,$00  ; 2
            .byte $3c,$66,$06,$1c,$06,$66,$3c,$00  ; 3
            .byte $06,$0e,$1e,$66,$7f,$06,$06,$00  ; 4
            .byte $7e,$60,$7c,$06,$06,$66,$3c,$00  ; 5
            .byte $3c,$66,$60,$7c,$66,$66,$3c,$00  ; 6
            .byte $7e,$66,$0c,$18,$18,$18,$18,$00  ; 7
            .byte $3c,$66,$66,$3c,$66,$66,$3c,$00  ; 8
            .byte $3c,$66,$66,$3e,$06,$66,$3c,$00  ; 9
            .byte $00,$00,$18,$00,$00,$18,$00,$00  ; :
            .byte $00,$00,$18,$00,$00,$18,$18,$30  ; ;
            .byte $0e,$18,$30,$60,$30,$18,$0e,$00  ; <
            .byte $00,$00,$7e,$00,$7e,$00,$00,$00  ; =
            .byte $70,$18,$0c,$06,$0c,$18,$70,$00  ; >
            .byte $3c,$66,$06,$0c,$18,$00,$18,$00  ; ?
            
            .byte $3c,$66,$6e,$6e,$60,$62,$3c,$00  ; @
            .byte $18,$3c,$66,$7e,$66,$66,$66,$00  ; A
            .byte $7c,$66,$66,$7c,$66,$66,$7c,$00  ; B
            .byte $3c,$66,$60,$60,$60,$66,$3c,$00  ; C
            .byte $78,$6c,$66,$66,$66,$6c,$78,$00  ; D
            .byte $7e,$60,$60,$78,$60,$60,$7e,$00  ; E
            .byte $7e,$60,$60,$78,$60,$60,$60,$00  ; F
            .byte $3c,$66,$60,$6e,$66,$66,$3c,$00  ; G
            .byte $66,$66,$66,$7e,$66,$66,$66,$00  ; H
            .byte $3c,$18,$18,$18,$18,$18,$3c,$00  ; I
            .byte $1e,$0c,$0c,$0c,$0c,$6c,$38,$00  ; J
            .byte $66,$6c,$78,$70,$78,$6c,$66,$00  ; K
            .byte $60,$60,$60,$60,$60,$60,$7e,$00  ; L
            .byte $63,$77,$7f,$6b,$63,$63,$63,$00  ; M
            .byte $66,$76,$7e,$7e,$6e,$66,$66,$00  ; N
            .byte $3c,$66,$66,$66,$66,$66,$3c,$00  ; O

            .byte $7c,$66,$66,$7c,$60,$60,$60,$00  ; P
            .byte $3c,$66,$66,$66,$66,$3c,$0e,$00  ; Q
            .byte $7c,$66,$66,$7c,$78,$6c,$66,$00  ; R
            .byte $3c,$66,$60,$3c,$06,$66,$3c,$00  ; S
            .byte $7e,$18,$18,$18,$18,$18,$18,$00  ; T
            .byte $66,$66,$66,$66,$66,$66,$3c,$00  ; U
            .byte $66,$66,$66,$66,$66,$3c,$18,$00  ; V
            .byte $63,$63,$63,$6b,$7f,$77,$63,$00  ; W
            .byte $66,$66,$3c,$18,$3c,$66,$66,$00  ; X
            .byte $66,$66,$66,$3c,$18,$18,$18,$00  ; Y
            .byte $7e,$06,$0c,$18,$30,$60,$7e,$00  ; Z
            .byte $3c,$30,$30,$30,$30,$30,$3c,$00  ; [
            .byte $00,$60,$30,$18,$0C,$06,$03,$00  ; Backslash
            .byte $3c,$0c,$0c,$0c,$0c,$0c,$3c,$00  ; ]
            .byte $18,$3c,$66,$00,$00,$00,$00,$00  ; ^
            .byte $00,$00,$00,$00,$00,$00,$00,$ff  ; _
            
            .byte $60,$30,$18,$00,$00,$00,$00,$00  ; `
            .byte $00,$00,$3c,$06,$3e,$66,$3e,$00  ; a
            .byte $00,$60,$60,$7c,$66,$66,$7c,$00  ; b
            .byte $00,$00,$3c,$60,$60,$60,$3c,$00  ; c
            .byte $00,$06,$06,$3e,$66,$66,$3e,$00  ; d
            .byte $00,$00,$3c,$66,$7e,$60,$3c,$00  ; e
            .byte $00,$0e,$18,$3e,$18,$18,$18,$00  ; f
            .byte $00,$00,$3e,$66,$66,$3e,$06,$7c  ; g
            .byte $00,$60,$60,$7c,$66,$66,$66,$00  ; h
            .byte $00,$18,$00,$38,$18,$18,$3c,$00  ; i
            .byte $00,$06,$00,$06,$06,$06,$06,$3c  ; j
            .byte $00,$60,$60,$6c,$78,$6c,$66,$00  ; k
            .byte $00,$38,$18,$18,$18,$18,$3c,$00  ; l
            .byte $00,$00,$66,$7f,$7f,$6b,$63,$00  ; m
            .byte $00,$00,$7c,$66,$66,$66,$66,$00  ; n
            .byte $00,$00,$3c,$66,$66,$66,$3c,$00  ; o

            .byte $00,$00,$7c,$66,$66,$7c,$60,$60  ; p
            .byte $00,$00,$3e,$66,$66,$3e,$06,$06  ; q
            .byte $00,$00,$7c,$66,$60,$60,$60,$00  ; r
            .byte $00,$00,$3e,$60,$3c,$06,$7c,$00  ; s
            .byte $00,$18,$7e,$18,$18,$18,$0e,$00  ; t
            .byte $00,$00,$66,$66,$66,$66,$3e,$00  ; u
            .byte $00,$00,$66,$66,$66,$3c,$18,$00  ; v
            .byte $00,$00,$63,$6b,$7f,$3e,$36,$00  ; w
            .byte $00,$00,$66,$3c,$18,$3c,$66,$00  ; x
            .byte $00,$00,$66,$66,$66,$3e,$0c,$78  ; y
            .byte $00,$00,$7e,$0c,$18,$30,$7e,$00  ; z
            .byte $1c,$30,$30,$60,$30,$30,$1c,$00  ; {
            .byte $18,$18,$18,$18,$18,$18,$18,$00  ; |
            .byte $38,$0c,$0c,$06,$0c,$0c,$38,$00  ; }
            .byte $00,$00,$00,$76,$dc,$00,$00,$00  ; ~
            .byte $cc,$cc,$33,$33,$cc,$cc,$33,$33  ; ▒

            .byte $10,$38,$7c,$fe,$7c,$38,$10,$00  ; Diamond
            .byte $aa,$55,$aa,$55,$aa,$55,$aa,$55  ; Checkerboard
            .byte $00,$00,$00,$00,$f0,$f0,$f0,$f0  ; Block left/bottom
            .byte $00,$00,$00,$00,$0f,$0f,$0f,$0f  ; Block right/bottom
            .byte $f0,$f0,$f0,$f0,$00,$00,$00,$00  ; Block left/top
            .byte $0f,$0f,$0f,$0f,$00,$00,$00,$00  ; Block right/top
            .byte $3c,$66,$66,$3c,$00,$00,$00,$00  ; Degree sign
            .byte $18,$18,$7e,$18,$18,$00,$7e,$00  ; Plus/Minus
            .byte $ff,$ff,$ff,$ff,$00,$00,$00,$00  ; Block top
            .byte $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f  ; Block right
            .byte $18,$18,$18,$f8,$f8,$00,$00,$00  ; Corner right/bottom
            .byte $00,$00,$00,$f8,$f8,$18,$18,$18  ; Corner right/top
            .byte $00,$00,$00,$1f,$1f,$18,$18,$18  ; Corner left/top
            .byte $18,$18,$18,$1f,$1f,$00,$00,$00  ; Corner left/bottom
            .byte $18,$18,$18,$ff,$ff,$18,$18,$18  ; Crossing lines
            .byte $00,$ff,$ff,$00,$00,$00,$00,$00  ; Scan line 1
            
            .byte $00,$00,$ff,$ff,$00,$00,$00,$00  ; Scan line 3
            .byte $00,$00,$00,$ff,$ff,$00,$00,$00  ; Scan line 5 / Horizontal line
            .byte $00,$00,$00,$00,$ff,$ff,$00,$00  ; Scan line 7
            .byte $00,$00,$00,$00,$00,$ff,$ff,$00  ; Scan line 9
            .byte $18,$18,$18,$1f,$1f,$18,$18,$18  ; T corner left
            .byte $18,$18,$18,$f8,$f8,$18,$18,$18  ; T corner right
            .byte $18,$18,$18,$ff,$ff,$00,$00,$00  ; T corner bottom
            .byte $00,$00,$00,$ff,$ff,$18,$18,$18  ; T corner top
            .byte $18,$18,$18,$18,$18,$18,$18,$18  ; Vertical line
            .byte $18,$30,$60,$30,$18,$00,$7e,$00  ; Smaller/equal sign
            .byte $18,$0c,$06,$0c,$18,$00,$7e,$00  ; Greater/equal sign
            .byte $00,$00,$03,$3e,$76,$36,$36,$00  ; Pi symbol
            .byte $00,$00,$0c,$7e,$18,$7e,$30,$00  ; Not equal sign
            .byte $0c,$12,$30,$7c,$30,$62,$fc,$00  ; Pound sign
            .byte $00,$00,$18,$3c,$3c,$18,$00,$00  ; Centered dot
            .byte $f0,$f0,$f0,$f0,$0f,$0f,$0f,$0f  ; Block left/top right/bottom

