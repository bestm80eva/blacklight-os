;; Blacklight OS standard input functions
;; (c) 2011 Troy Martin
; Blacklight OS is licensed under the Simplified BSD License (see license.txt)
; http://www.opensource.org/licenses/bsd-license.php

; IN: AX=array, BX=maximum number of characters to take
; OUT: AX=string, CX=total characters
direct_input:
	push ax
	push bx
	push dx
	push di

	mov di, ax			; DI is where we'll store input (buffer)
	xor cx, cx			; Character received counter for backspace


.loop:					; Now onto string getting
	mov ah, 10h
	int 16h

	cmp al, 13			; If Enter key pressed, finish
	je .done

	cmp al, 8			; Backspace pressed?
	je .back			; If not, skip following checks
	
	cmp cx, bx			; Are we full?
	je .loop

	jmp .other


.back:
	cmp cx, 0			; Backspace at start of string?
	je .loop			; Ignore it if so

	mov ah, 3
	push cx
	int 10h
	pop cx
	cmp dl, 0
	je .back_lineup

	pusha
	mov ax, 0E08h			; If not, write space and move cursor back
	mov bx, 0007h
	int 10h				; Backspace twice, to clear space
	mov al, ' '
	int 10h
	mov al, 8
	int 10h
	popa

	dec di				; Character position will be overwritten by new
					; character or terminator at end

	dec cx				; Step back counter

	jmp .loop


.back_lineup:
	mov ah, 3
	push cx
	int 10h
	pop cx
	
	dec dh				; Jump back to end of previous line
	mov dl, 79
	mov ah, 2
	push bx
	mov bh, 0
	int 10h
	pop bx
	

	mov al, ' '			; Print space there
	mov ah, 0Eh
	push bx
	mov bx, 0007h
	int 10h
	pop bx

	
	mov ah, 3
	push cx
	int 10h
	pop cx
	
	dec dh
	mov dl, 79			; And jump back before the space
	mov ah, 2
	push bx
	mov bh, 0
	int 10h
	pop bx

	dec di				; Step back position in string
	dec cx				; Step back counter

	jmp .loop


.other:
	pusha
	mov ah, 0Eh			; Output entered, printable character
	mov bx, 0007h
	int 10h
	popa

	stosb				; Store character in designated buffer
	inc cx				; Characters processed += 1

	jmp .loop			; Still room for more


.done:
	mov al, 0
	stosb

	pop di
	pop dx
	pop bx
	pop ax
	ret
