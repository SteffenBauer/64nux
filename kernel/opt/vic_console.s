		;; Hey emacs, look at this: -*- MODE: asm; tab-width: 4; -*-

		;; simple console driver
		;; rewritten to support more than just one screen
		;; (static screens)

#include <console.h>


		;; additional globals needed by
		;; console_init (called at boot-time)
		;; (they will get a "lkf_" prefix there!)

		.global cons_regbuf
		.global cons_home
		.global cons_clear

		;; switch to next virtual console
console_toggle:
#ifdef MULTIPLE_CONSOLES
		beq  do_toggle
		bmi  do_toggle

		cmp  #1
		beq  do_cons1
		cmp  #2
		beq  do_cons2

do_cons1:
		lda  #$04
		sta  VIC_VSCB			; default is console 1 (at $C000)
		lda  #0
		sta  cons_visible
		rts

do_cons2:
		lda  #$14
		sta  VIC_VSCB			; console 2 (at $C400)
		lda  #1
		sta  cons_visible
		rts

do_toggle:
		lda  VIC_VSCB
		eor  #$10
		sta  VIC_VSCB
		lda  cons_visible
		eor  #1
		sta  cons_visible
#endif
		rts
		
		;; clear screen
		;; NOTE:
		;;		better not clear $7f8..$7ff (TODO)
cons_clear:
		jsr  cons_hidecsr
#ifndef HAVE_REU
		ldx  sbase
		stx  loc1
		inx
		stx  loc1+3
		inx
		stx  loc1+6
		inx
		stx  loc1+9	
		lda  #$00
		ldx  #0
		
loc1 equ *+2
	-	sta  screenA_base,x
		sta  screenA_base+$100,x
		sta  screenA_base+$200,x
		sta  screenA_base+$300,x
		inx
		bne  -
		
		lda  #5					; text color
		
	-	sta  $d800,x
		sta  $d900,x
		sta  $da00,x
		sta  $db00,x
		inx
		bne  -
#else
		;; clear screen using REU
		lda  #REUcontr_fixreuadr
		sei						; (must sei until REU command is issued)
		sta  REU_control
		lda  #0					; (lo-byte of screen address)
		sta  REU_intbase
		lda  sbase
		sta  REU_intbase+1
		lda  #$20				; fill with $000420 which is $00 (space)
		sta  REU_reubase
		lda  #$04
		sta  REU_reubase+1
		lda  #$00
		sta  REU_reubase+2
		lda  #$f8
		sta  REU_translen
		lda  #$03
		sta  REU_translen+1
		lda  #REUcmd_reu2int|REUcmd_load|REUcmd_noff00|REUcmd_execute
		sta  REU_command
		lda  #5					; fill with $000405 which is $05 (green)
		sta  REU_reubase
		lda  #>$d800
		sta  REU_intbase+1
		lda  #REUcmd_reu2int|REUcmd_noff00|REUcmd_execute
		sta  REU_command
		cli
#endif
		jmp  cons_showcsr

		;; move cursor to the upper left corner of the screen
cons_home:
		ldx  #0
		ldy  #0

cons_setpos:
		cpx  #size_x
		bcs  +
		cpy  #size_y
		bcs  +					; ignore invalid settings
		stx  csrx
		sty  csry
		;; calculate position in RAM
		clc
		txa
		adc  ypos_table_lo,y
		sta  mapl
		lda  ypos_table_hi,y
		adc  sbase				; start of screen
		sta  maph
	+	rts

cons_csrup:
		ldx  csry
		beq  err				; error
		dex
		stx  csry
		sec
		lda  mapl
		sbc  #size_x
		sta  mapl
		bcs  +
		dec  maph
		clc
	+	rts

err:	sec
		rts
		
cons_csrdown:	
		ldx  csry
		cpx  #size_y-1
		beq  err
		inx
		stx  csry
		clc
		lda  mapl
		adc  #size_x
		sta  mapl
		bcc  +
		inc  maph
		clc
	+	rts

cons_csrleft:
		ldx  csrx
		beq  err				; error
		dex
		stx  csrx
		lda  mapl
		bne  +
		dec  maph
	+	dec  mapl
		clc
		rts

cons_csrright:	
		ldx  csrx
		cpx  #size_x-1
		beq  err
		inx
		stx  csrx
		inc  mapl
		bne  +
		inc  maph
	+	clc
		rts

cons_scroll_up:
#ifndef HAVE_REU
		;; scrolling without REU
		ldy  scrl_y1
		
	-	clc
		lda  ypos_table_lo,y
		sta  scrl_loop+4
		adc  #size_x
		sta  scrl_loop+1
		lda  ypos_table_hi,y
		ora  sbase
		sta  scrl_loop+5
		adc  #0
		sta  scrl_loop+2
		ldx  #size_x-1
scrl_loop:
		lda  .0,x
		sta  .0,x
		dex
		bpl  scrl_loop
		iny
		cpy  scrl_y2
		bne  -

		;; erase the last line
		lda  ypos_table_lo,y
		sta  scrl_loop2+1
		lda  ypos_table_hi,y
		ora  sbase
		sta  scrl_loop2+2
		lda  #$00
		ldx  #size_x-1
scrl_loop2:
		sta  .0,x
		dex
		bpl  scrl_loop2
		rts
#else
		;; scrolling with REU
		ldy  scrl_y1
		lda  ypos_table_lo+1,y
		sei						; (must sei until REU command is issued)
		sta  REU_intbase
		lda  ypos_table_hi+1,y
		ora  sbase
		sta  REU_intbase+1
		lda  #0
		sta  REU_reubase
		sta  REU_reubase+1
		sta  REU_reubase+2
		sta  REU_control		; no fixed addresses
		sec
		lda  scrl_y2
		sbc  scrl_y1
		tay
		lda  ypos_table_lo,y	; (ypos_table holds just y*40 !)
		sta  REU_translen
		lda  ypos_table_hi,y
		sta  REU_translen+1
		lda  #REUcmd_int2reu|REUcmd_load|REUcmd_noff00|REUcmd_execute
		sta  REU_command		; copy portion of screen into REU

		ldy  scrl_y1
		lda  ypos_table_lo,y
		sta  REU_intbase
		lda  ypos_table_hi,y
		ora  sbase				; base of screen
		sta  REU_intbase+1
		lda  #REUcmd_reu2int|REUcmd_noff00|REUcmd_execute
		sta  REU_command		; copy portion back to screen (one line above)

		lda  #$20
		sta  REU_reubase
		lda  #$04				; (reu@$000420 holds $20)
		sta  REU_reubase+1		; (reubase+2 already is $00)
		lda  #40
		sta  REU_translen
		lda  #0
		sta  REU_translen+1
		lda  #REUcontr_fixreuadr
		sta  REU_control
		lda  #REUcmd_reu2int|REUcmd_noff00|REUcmd_execute
		sta  REU_command		; erase lowest line (fill with $20)
		cli
		rts	
#endif

cons_showcsr:
		bit  cflag
		bvs  +					; already shown
		bpl  +					; cursor disabled
		sei
		lda  mapl
		sta  tmpzp
		lda  maph
		sta  tmpzp+1
		ldy  #0
		lda  (tmpzp),y
		sta  buc
		lda  #cursor
		sta  (tmpzp),y
		cli
		lda  #$c0
		sta  cflag
	+	rts

cons_hidecsr:
		bit  cflag
		bvc	 +					; no cursor there
		sei
		lda  mapl
		sta  tmpzp
		lda  maph
		sta  tmpzp+1
		ldy  #0
		lda  buc
		sta  (tmpzp),y
		cli
		lda  cflag
		and  #%10111111
		sta  cflag
	+	rts
				
		;; convert ascii to screencodes
cons_a2p:
        cmp  #$20
        bcc  _ignore
        cmp  #$80
        bcc  _subx20
_ignore:
        lda  #$5f
        sec
        rts
_subx20:
        cmp  #$60
        bcc  +
        bit alt_flag
        bvs  ++
        clc
    +   sbc #$1f
    +   clc
    -   rts

cons1out:
		ldx  #0
		
		;; print char to console, X=number of console
cons_out:
#ifdef MULTIPLE_CONSOLES
		cpx  #2
		bcs  -					; (silently ignore character, when X>1)
		jsr  locktsw			; (this code isn't reentrant!!)
		sta  cchar
		
		cpx  cons_visible
		beq  ++

		lda  #$80
		cpx  #0
		bne  +
		eor  screenB_base+size_x-1	; view action on hidden screen
		sta  screenB_base+size_x-1	
		jmp  ++
		
	+	eor  screenA_base+size_x-1	; view action on hidden screen
		sta  screenA_base+size_x-1

	+	cpx  current_output
		beq  +

		;; load variables of alternate screen
		stx  current_output
		lda  sbase
		eor  #>(screenA_base^screenB_base)
		sta  sbase
		ldx  #8
		
	-	ldy  mapl,x
		lda  cons_regbuf,x
		sta  mapl,x
		tya
		sta  cons_regbuf,x
		dex
		bpl  -
	+
#else
		cpx  #1
		bcs  -					; (silently ignore character, when X>0)		
		jsr  locktsw			; (this code isn't reentrant!!)
		sta  cchar
#endif
		
		jsr  cons_hidecsr
		
		ldx  esc_flag
		bne  jdo_escapes

		;; print normal character
		lda  cchar
		cmp  #$20
		bcc  special_chars
		jsr  cons_a2p
		eor  rvs_flag
		tax
		php						; write character code
		sei						; to char_map
		lda  mapl
		sta  tmpzp
		lda  maph
		sta  tmpzp+1
		ldy  #0
		txa
		sta  (tmpzp),y
		plp
		jsr  cons_csrright
_back:	jsr  cons_showcsr
		jmp  unlocktsw

jdo_escapes:	
		jmp  do_escapes
		
special_chars:

		;; UNIX ascii (default)
		cmp  #$0a
		beq  _crlf
		cmp  #$0d
		beq  _cr
		cmp  #$1b				; escape
		beq  _esc
		cmp  #$09
		beq  _tab
		cmp  #$08
		beq  _del
		cmp  #$07
		beq  _beep
		cmp  #$1e
		beq  _shiftout
		cmp  #$1f
		beq  _shiftin
		jmp  _back

_shiftout:
        lda  #$40
        sta  alt_flag
        jmp  _back

_shiftin:
        lda #$00
        sta  alt_flag
        jmp  _back
        
_crlf:	lda  csry
		cmp  scrl_y2
		bne  +

		jsr  cons_scroll_up
		jmp  _cr

	+	jsr  cons_csrdown

_cr:	ldx  #0
		ldy  csry
		jsr  cons_setpos
		jmp  _back
_esc:	lda  #1
		sta  esc_flag
		jmp  _back

_tab:	lda  csrx				; tab-width=4
		lsr  a
		lsr  a
		clc
		adc  #1
		asl  a
		asl  a
		tax
		ldy  csry
		jsr  cons_setpos		; (only done, if position is valid)
		jmp  _back

_del:	ldx  csrx
		beq  +					; skip if already on left border
		dex
		ldy  csry
		jsr  cons_setpos
		php
		sei
		lda  mapl
		sta  tmpzp
		lda  maph
		sta  tmpzp+1
		lda  #$00
		ldy  #0
		sta  (tmpzp),y
		plp
	+	jmp  _back

_beep:	jsr beep
		jmp _back

do_escapes:
		cpx  #2
		beq  do_esc2			; state2
		lda  cchar
		
		;; waiting for escape command (character)
		cmp  #91
		bne  +

		;; <ESC>[...
		lda  #2
		sta  esc_flag
		lda  #0
		sta  esc_parcnt
		lda  #$ff
		sta  esc_par
		jmp  _back

	+	cmp  #68
		bne  leave_esc
		
		;; <ESC>D
		lda  csry
		cmp  scrl_y2
		beq  +
		jsr  cons_csrdown
		jmp  leave_esc
	+	jsr  cons_scroll_up
		
		;; ignore unknown escapes

leave_esc:
		lda  #0
		sta  esc_flag

		jmp  _back

		;; digit -> add to current parameter
		;; ";"   -> step to next parameter
		;; else  -> command!
do_esc2:
		lda  cchar
		cmp  #";"				; equal to "9"+2 !
		beq  do_esc_nextpar
		bcs  do_esc_command		; most likely a command
		;; most likely a digit
		and  #15
		sta  cchar
		ldx  esc_parcnt
		lda  esc_par,x
		bpl  +
		lda  #0
		beq  ++					; note, that c=0 !
	+	asl  a
		asl  a
		adc  esc_par,x
		asl  a
	+	adc  cchar
		sta  esc_par,x
		jmp  _back				; state doesn't change

do_esc_nextpar:
		ldx  esc_parcnt			; increase par-counter (if possible)
		cmp  #7
		beq  +
		inx
		stx  esc_parcnt
	+	lda  #255				; initialize parameter
		sta  esc_par,x
		jmp  _back				; state doesn't change again

do_esc_command:
		lda  cchar
		cmp  #72        ; $48 -> 'H'
		bne  esc_com2

		;; cursor positioning <ESC>[#y;#xH
		ldy  esc_par
		bpl  +					; parameter defaults to 0
		ldy  #1
	+	dey
		lda  esc_parcnt
		beq  +
		ldx  esc_par+1
		bpl  ++					; parameter defaults to 0
	+	ldx  #1
	+	dex
		jsr  cons_setpos
		jmp  leave_esc

esc_com2:
		cmp  #74        ; $4A -> 'J'
		bne  esc_com3

		;; clear screen <ESC>[2J
		lda  esc_par
		cmp  #2
		bne  +
		jsr  cons_clear
	+	jmp  leave_esc

esc_com3:
		cmp  #75
		bne  esc_com4

		;; erase rest of line <ESC>[K
		lda  esc_par
		cmp  #255
		bne  +
		php
		sei
		lda  mapl
		sta  tmpzp
		lda  maph
		sta  tmpzp+1
		ldy  #0
		ldx  csrx
		lda  #$00
	-	sta  (tmpzp),y
		iny
		inx
		cpx  #size_x
		bne  -
		plp
	+	jmp  leave_esc
		
esc_com4:		
		cmp  #114
		bne  esc_com5
		
		;; change scroll-region <ESC>[#y1;#y2r
		lda  esc_parcnt
		cmp  #1
		bne  +					; skip (illegal parameter)
		ldx  esc_par
		bmi  +
		beq  +
		cmp  #size_y
		bcs  +
		dex
		ldy  esc_par+1
		bmi  +
		cmp  #size_y+1
		bcs  +
		dey
		sty  cchar
		cpx  cchar
		bcs  +
		stx  scrl_y1			; valid !
		sty  scrl_y2
	+	jmp  leave_esc

esc_com5:
		cmp  #109
		bne  esc_com6

		;; change attributes <ESC>[#a1;...m
		ldy  #$ff
	-	iny
		lda  esc_par,y
		bmi  +					; clear all attributes
		beq  +					; clear all attributes
		cmp  #7
		bne  ++					; skip
		lda  #$80				; activate RVS
		SKIP_WORD
	+	lda  #$00				; de-activate RVS
		sta  rvs_flag
	+	cpy  esc_parcnt
		bne  -
		jmp  leave_esc
		
esc_com6:
		cmp  #$41
		bne  esc_com7
		
		;; cursor step up one position <ESC>[A
		lda  esc_par
		cmp  #255
		bne  +
		jsr  cons_csrup
	+	jmp  leave_esc

esc_com7:
		cmp  #$42
		bne  esc_com8
		
		;; cursor step down one position <ESC>[B
		lda  esc_par
		cmp  #255
		bne  +
		jsr  cons_csrdown
	+	jmp  leave_esc

esc_com8:
		cmp  #$43
		bne  esc_com9
		
		;; cursor step forw one position <ESC>[C
		lda  esc_par
		cmp  #255
		bne  +
		jsr  cons_csrright
	+	jmp  leave_esc

esc_com9:
		cmp  #$44
		bne  esc_com10
		
		;; cursor step backw one position <ESC>[D
		lda  esc_par
		cmp  #255
		bne  +
		jsr  cons_csrleft
	+	jmp  leave_esc

esc_com10:		
		;; unknown sequence, just ignore
		jmp  leave_esc

ypos_table_lo:
		.byte <  0, < 40, < 80, <120, <160
		.byte <200, <240, <280, <320, <360
		.byte <400, <440, <480, <520, <560
		.byte <600, <640, <680, <720, <760
		.byte <800, <840, <880, <920, <960
		
ypos_table_hi:
		.byte >  0, > 40, > 80, >120, >160
		.byte >200, >240, >280, >320, >360
		.byte >400, >440, >480, >520, >560
		.byte >600, >640, >680, >720, >760
		.byte >800, >840, >880, >920, >960

		;; zeropage assignments
		
;;; ZEROpage: sbase 1
;;; ZEROpage: cchar 1
;;; ZEROpage: current_output 1
;;; ZEROpage: cons_visible 1
;;; ZEROpage: mapl 1
;;; ZEROpage: maph 1
;;; ZEROpage: csrx 1
;;; ZEROpage: csry 1
;;; ZEROpage: buc 1
;;; ZEROpage: cflag 1
;;; ZEROpage: rvs_flag 1
;;; ZEROpage: alt_flag 1
;;; ZEROpage: scrl_y1 1
;;; ZEROpage: scrl_y2 1
;;; ZEROpage: esc_flag 1
;;; ZEROpage: esc_parcnt 1

		;; the out-commended defines are replaced
		;; by zeropage assignments above
		
;sbase:			.byte 0			; base address of screen (hi byte)
;cchar:			.byte 0
;current_output:	.byte 0
;cons_visible:	.byte 0

		;; variables to store, when switching screens
;mapl:			.byte 0
;maph:			.byte 0
;csrx:			.byte 0
;csry:			.byte 0
;buc:			.byte 0			; byte under cursor
;cflag:			.byte 0			; cursor flag (on/off)
;rvs_flag:		.byte 0			; bit 7 - RVS ON
;alt_flag:      .byte 0         ; ALT Charset ON
;scrl_y1:		.byte 0			; scroll region first line
;scrl_y2:		.byte 0			; scroll region last line

#ifdef MULTIPLE_CONSOLES
		;; room for storing screen-variables
cons_regbuf:	.buf 9
#endif

		;; escape decoding related
;esc_flag:		.byte 0			; escape-statemachine-flag
;esc_parcnt:	.byte 0			; number of parameters read
esc_par:		.buf 8			; room for up to 8 parameters
