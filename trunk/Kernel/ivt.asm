;; Blacklight OS interrupt vector table stuff
;; (c) 2011 Troy Martin
; Blacklight OS is licensed under the Simplified BSD License (see license.txt)
; http://www.opensource.org/licenses/bsd-license.php

; ISR in CX, segment in BX, offset in DX
interrupt_set_gate:
	pusha
	;mov word [.seg],dx
	;mov word [.off],bx
	cli
	push es
	xor ax,ax
	mov es,ax
	mov ax,cx
	mov cl,4
	mul cl
	mov bx,ax
	;mov dx,word [.seg]
	mov word [es:bx],1000h
	add bx,2
	;mov bx,word [.off]
	mov word [es:bx],dx
	pop es
	sti
	popa
	ret
.seg dw 0
.off dw 0

; ISR in CX, returns segment in BX, offset in DX
interrupt_get_gate:
	cli
	push es
	xor ax,ax
	mov es,ax
	mov ax,cx
	mov cl,4
	mul cl
	mov bx,ax
	mov cx,word [es:bx]
	add bx,2
	mov dx,word [es:bx]
	mov bx,cx
	pop es
	sti
	ret

interrupt_isr_00h:
	; TO-DO task handling
	mov ax,1000h
	mov ds,ax
	derror `Divide error. System halted.`
	cli
	hlt
    
interrupt_isr_06h:
	; TO-DO task handling
	mov ax,1000h
	mov ds,ax
	derror `Invalid opcode. System halted.`
	cli
	hlt
