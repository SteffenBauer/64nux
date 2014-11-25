	;; for vi:  ex: set shiftwidth=4:
	;; helloworld

#include <system.h>
#include <stdio.h>

		start_of_code equ $1000

		.org start_of_code

		.byte >LNG_MAGIC,   <LNG_MAGIC
		.byte >LNG_VERSION,	<LNG_VERSION
		.byte >(end_of_code-start_of_code+255)
		.byte >start_of_code

		;; print helloworld
		ldx  #stdout
		bit  txt_hello
		jsr  lkf_strout
        jmp waitforkey
        
        RELO_JMP(txt_hello_end)
txt_hello:
		.text "Hello, World, with a jump",$0a,0
txt_hello_end:

		;; Wait for any key
waitforkey:
		ldx  #stdin
		sec
		jsr  fgetc

		;; Exit normally
		lda  #0
		rts

		RELO_END ; no more code to relocate

end_of_code:

