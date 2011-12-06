;; Blacklight OS math/integer stuff
;; (c) 2011 Troy Martin
; Blacklight OS is licensed under the Simplified BSD License (see license.txt)
; http://www.opensource.org/licenses/bsd-license.php

; Borrowed from MikeOS' os_string_to_int - needs rewrite + optimizations
; See mikeos-license.txt for details.
; IN: SI=string to convert
; OUT: AX=integer
direct_atoi:
	pusha

	call direct_strlen
	add si,ax			; Work from rightmost char in string
	dec si

	mov cx,ax			; Use string length as counter

	mov bx,0			; BX will be the final number
	mov ax,0

	mov word [.multiplier], 1	; Start with multiples of 1

.loop:
	mov ax, 0
	mov byte al, [si]		; Get character
	sub al, 48			; Convert from ASCII to real number

	mul word [.multiplier]		; Multiply by our multiplier

	add bx, ax			; Add it to BX

	push ax				; Multiply our multiplier by 10 for next char
	mov word ax, [.multiplier]
	mov dx, 10
	mul dx
	mov word [.multiplier], ax
	pop ax

	dec cx				; Any more chars?
	cmp cx, 0
	je .finish
	dec si				; Move back a char in the string
	jmp .loop

.finish:
	mov word [.tmp], bx
	popa
	mov word ax, [.tmp]

	ret


.multiplier dw 0
.tmp dw 0

; Borrowed from MikeOS' os_int_to_string. Needs rewrite + optimizations.
; See mikeos-license.txt for details.
; IN: AX=integer
; OUT: SI=string location
direct_itoa:
	pusha
	push es
	push cs
	pop es

	mov cx, 0
	mov bx, 10			; Set BX 10, for division and mod
	mov di, .t			; Get our pointer ready

.push:
	mov dx, 0
	div bx				; Remainder in DX, quotient in AX
	inc cx                          ; Increase pop loop counter
	push dx				; Push remainder, so as to reverse order when popping
	test ax, ax			; Is quotient zero?
	jnz .push			; If not, loop again
.pop:
	pop dx				; Pop off values in reverse order, and add 48 to make them digits
	add dl, '0'			; And save them in the string, increasing the pointer each time
	mov [es:di], dl
	inc di
	dec cx
	jnz .pop

	mov byte [es:di], 0		; Zero-terminate string

	pop es
	popa
	mov si, .t			; Return location of string
	ret

	.t times 7 db 0

; IN: SI=string
; OUT: AX=length
direct_strlen:
	push si
	push cx
	xor cx, cx

.loop:
	lodsb
	cmp al, 0
	je .done
	inc cx
	jmp .loop

.done:
	mov ax, cx
	pop cx
	pop si
	ret

; ------------------------------------------------------------------
; direct_string_chomp -- Strip leading and trailing spaces from a string
; IN: AX = string location

direct_string_chomp:
	pusha

	mov dx, ax			; Save string location

	mov di, ax			; Put location into DI
	mov cx, 0			; Space counter

.keepcounting:				; Get number of leading spaces into BX
	cmp byte [di], ' '
	jne .counted
	inc cx
	inc di
	jmp .keepcounting

.counted:
	cmp cx, 0			; No leading spaces?
	je .finished_copy

	mov si, di			; Address of first non-space character
	mov di, dx			; DI = original string start

.keep_copying:
	mov al, [si]			; Copy SI into DI
	mov [di], al			; Including terminator
	cmp al, 0
	je .finished_copy
	inc si
	inc di
	jmp .keep_copying

.finished_copy:
	mov ax, dx			; AX = original string start

	call direct_strlen
	cmp ax, 0			; If empty or all blank, done, return 'null'
	je .done

	mov si, dx
	add si, ax			; Move to end of string

.more:
	dec si
	cmp byte [si], ' '
	jne .done
	mov byte [si], 0		; Fill end spaces with 0s
	jmp .more			; (First 0 will be the string terminator)

.done:
	popa
	ret

; IN: EAX=seed, 0 for random seed
direct_srand:
	pusha
	cmp eax,0
	jne .make_seed

	int 1Ah
	add dx,cx
	mov ax,dx
	add ax,ax
	ror ax,7
	and ax,8086h
	add ax,cx
	ror ax,13
	rol eax,16
	add ax,ax
	push eax
	xor ax,ax
	int 1Ah
	pop eax
	add dx,cx
	sub dx,ax
	add eax,edx      ; Thoroughly randomized.
    
.make_seed:
	mov dword [direct_seed],eax
	popa
	ret
    
; OUT: EAX=random number
direct_rand:
	pusha

	mov eax, dword [direct_seed]
	rol eax,12
	add ax,ax
	ror ax,7
	and ax,386h
	push ax
	xor ax,ax
	int 1Ah
	pop ax
	add ax,cx
	ror ax,13
	rol eax,16
	add ax,ax
	push eax
	xor ax,ax
	int 1Ah
	pop eax
	add dx,cx
	sub dx,ax
	ror eax,21
	add eax,edx      ; Thoroughly randomized.

	mov dword [.temp],eax    
	popa
	mov eax, dword [.temp]
	ret

.temp dd 0

direct_strupper:
	pusha

	mov si, ax			; Use SI to access string

.more:
	cmp byte [si], 0		; Zero-termination of string?
	je .done			; If so, quit

	cmp byte [si], 'a'		; In the lower case A to Z range?
	jb .noatoz
	cmp byte [si], 'z'
	ja .noatoz

	sub byte [si], 20h		; If so, convert input char to upper case

	inc si
	jmp .more

.noatoz:
	inc si
	jmp .more

.done:
	popa
	ret
	
direct_strlower:
	pusha

	mov si, ax			; Use SI to access string

.more:
	cmp byte [si], 0		; Zero-termination of string?
	je .done			; If so, quit

	cmp byte [si], 'A'		; In the upper case A to Z range?
	jb .noatoz
	cmp byte [si], 'Z'
	ja .noatoz

	add byte [si], 20h		; If so, convert input char to lower case

	inc si
	jmp .more

.noatoz:
	inc si
	jmp .more

.done:
	popa
	ret

direct_strcmp:
	pusha

.more:
	mov al, [si]			; Retrieve string contents
	mov bl, [di]

	cmp al, bl			; Compare characters at current location
	jne .not_same

	cmp al, 0			; End of first string? Must also be end of second
	je .terminated

	inc si
	inc di
	jmp .more


.not_same:				; If unequal lengths with same beginning, the byte
	popa				; comparison fails at shortest string terminator
	clc				; Clear carry flag
	ret


.terminated:				; Both strings terminated at the same position
	popa
	stc				; Set carry flag
	ret
	
	
; ------------------------------------------------------------------
; direct_strncmp -- See if two strings match up to set number of chars
; IN: SI = string one, DI = string two, CL = chars to check
; OUT: carry set if same, clear if different

direct_strncmp:
	pusha

.more:
	mov al, [si]			; Retrieve string contents
	mov bl, [di]

	cmp al, bl			; Compare characters at current location
	jne .not_same

	cmp al, 0			; End of first string? Must also be end of second
	je .terminated

	inc si
	inc di

	dec cl				; If we've lasted through our char count
	cmp cl, 0			; Then the bits of the string match!
	je .terminated

	jmp .more


.not_same:				; If unequal lengths with same beginning, the byte
	popa				; comparison fails at shortest string terminator
	clc				; Clear carry flag
	ret


.terminated:				; Both strings terminated at the same position
	popa
	stc				; Set carry flag
	ret
	
; ------------------------------------------------------------------
; direct_string_tokenize -- Reads tokens separated by specified char from
; a string. Returns pointer to next token, or 0 if none left
; IN: AL = separator char, SI = beginning; OUT: DI = next token or 0 if none

direct_string_tokenize:
	push si

.next_char:
	cmp byte [si], al
	je .return_token
	cmp byte [si], 0
	jz .no_more
	inc si
	jmp .next_char

.return_token:
	mov byte [si], 0
	inc si
	mov di, si
	pop si
	ret

.no_more:
	mov di, 0
	pop si
	ret

section .data
    direct_seed dd 0
section .text
