;; Blacklight OS memory management
;; (c) 2011 Troy Martin
; Blacklight OS is licensed under the Simplified BSD License (see license.txt)
; http://www.opensource.org/licenses/bsd-license.php

; Magic numbers:
; 00h = free
; 01h = kernel
; 02h = used
; 0Fh = reserved

section .data

mm_memory_map:					; Base memory map. I will rewrite this at some point.
	db 0Fh,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h	; Mostly free (bit of BIOS shit, suggested avoidance)
	db 01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h	; The kernel is loaded to here
	db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
	db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
	db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
	db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
	db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
	db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
	db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
	db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,0Fh	; TODO: Figure out why I marked this used
	db 0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh	;   [
	db 0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh	;  [
	db 0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh	; [	All used by the BIOS, VGA, and Option ROMs.
	db 0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh	; [
	db 0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh	;  [
	db 0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh	;   [
    
section .text

; IN: DX=segment
; OUT: AL=status
mm_get_segment:
	mov bl,dh
	mov bh,0
	mov si,mm_memory_map
	mov al,byte [gs:si+bx]
	ret

; IN: DX=segment
; OUT: AL=status, 00h if success
mm_allocate_segment:
	mov bl, dh
	mov bh, 0
	push gs
	push cs
	pop gs
	mov si, mm_memory_map
	mov al, byte [gs:si+bx]
	cmp al, 00h
	je .assign
	pop gs
	ret
	
.assign:
	mov byte [gs:si+bx], 02h		; Mark as used
	mov al, 00h
	pop gs
	ret
	
; IN: DX=start segment, CL=number of segments
; OUT: carry set on fail
mm_allocate:
	pusha
	xor ax,ax
	push cx
	push dx
.loop1:	
	pusha					; First we check to see if we CAN allocate this shit
	call mm_get_segment
	cmp al, 00h
	jne .fail
	popa
	inc dx
	dec cx
	jnz .loop1
	
	pop dx
	pop cx
	
	mov dl, dh
	mov dh, 0
	mov di, mm_memory_map
	add di, dx
	mov al, 02h				; Mark as used
	mov ch, 0
	rep stosb

	popa
	ret
	
	
.fail:
	pop dx
	pop cx
	popa
	stc
	ret
	