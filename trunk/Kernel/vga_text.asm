;; Blacklight OS VGA-based text routines
;; (c) 2011 Troy Martin
; Blacklight OS is licensed under the Simplified BSD License (see license.txt)
; http://www.opensource.org/licenses/bsd-license.php

; Enables graphitext support (aka the great BIOS graphics mode kludge)
%define VGA_GRAPHITEXT_ENABLED 0

; Modes
%define VGA_MODE_40x25x16 01h
%define VGA_MODE_80x25x16 03h

%if VGA_GRAPHITEXT_ENABLED == 1
	%define VGA_MODE_80x30x16 12h
%endif


; Direct print
%macro dprint 1+
section .data
	%%string db %1,0
section .text

	pusha
	mov si,%%string
	mov bx,0007h
	call direct_print
	popa
%endmacro

%macro derror 1+
section .data
	%%string db %1,0
section .text

	pusha
	mov si,%%string
	mov bx,004Eh
	call direct_print
	popa
%endmacro

%macro dprinto 1
	pusha
	mov si,%1
	mov bx,0007h
	call direct_print
	popa
%endmacro

%macro dprintc 1
	pusha
	mov ah,0Eh
	mov al,%1
	mov bx,0007h
	int 10h
	popa
%endmacro

; IN: SI=string to print
direct_print:
	pusha
.loop:
	lodsb
	cmp al,0Ah
	je .newline
	cmp al,0
	je .done
	mov ah,09h
	mov cx,1
	int 10h
	mov ah,0Eh
	int 10h
	jmp .loop
.newline:
	mov ah,0Eh
	mov al,0Dh
	int 10h
	mov al,0Ah
	int 10h
	jmp .loop
.done:
	popa
	ret
    
; IN: DX=word to print
direct_print_dec:
	pusha
.printloop:
	mov ax,dx
	cmp ax,0
	je .zero

	mov ax,dx
	call direct_itoa
	push bx
	mov bx, 0007h
	push ds
	push cs
	pop ds
	call direct_print
	pop ds
	pop bx

	popa
	ret
.zero:
	mov ah,0Eh
	mov bx,0007h
	mov al,'0'
	int 10h
	popa
	ret

; IN: DL=byte to print
direct_print_db:
	pusha
	mov al,dl

	push ax
	shr al,4
	mov si,hex_char_table
	mov ah,0
	add si,ax
	mov al,byte [si]
	mov bx,0007h
	mov ah,0Eh
	int 10h
	pop ax

	and al,0Fh
	mov si,hex_char_table
	mov ah,0
	add si,ax
	mov al,byte [si]
	mov bx,0007h
	mov ah,0Eh
	int 10h

	popa
	ret
    
; IN: DX=word to print
direct_print_dw:
	pusha
	push dx
	mov dl,dh
	call direct_print_db
	pop dx
	call direct_print_db
	popa
	ret

    
; Mode switch - may trash some registers
vga_switch_mode:
	push ds
	push es
	push cs
	pop ax
	mov ds,ax
	mov es,ax
	
	cmp al,VGA_MODE_40x25x16
	je .mode1
	cmp al,VGA_MODE_80x25x16
	je .mode3
%if VGA_GRAPHITEXT_ENABLED == 1
	cmp al,VGA_MODE_80x30x16
	je .mode12
%endif
	dprint `vga_switch_mode: Unknown mode specified.\n`
	ret
    
.mode1:
	mov [vga_mode],al
	mov byte [vga_columns],40
	mov byte [vga_rows],25
	mov ah,00h
	int 10h
	jmp .done
    
.mode3:
	mov [vga_mode],al
	mov byte [vga_columns],80
	mov byte [vga_rows],25
	mov ah,00h
	int 10h
	jmp .done
    
%if VGA_GRAPHITEXT_ENABLED == 1
.mode12:
	mov [vga_mode],al
	mov byte [vga_columns],80
	mov byte [vga_rows],30
	mov ah,00h
	int 10h
	jmp .done
%endif
    
.done:
	pop es
	pop ds
	call vga_clear_screen
	ret
    
; Clears the screen
vga_clear_screen:
	pusha
	push ds
	push es
	push cs
	pop ax
	mov ds,ax
	mov es,ax
	
%if VGA_GRAPHITEXT_ENABLED == 1
	mov ah,[vga_mode]
	cmp ah,12h
	je .graphics_clear
	jmp .text_clear
    
.graphics_clear:
	mov ax,0600h
	mov bh,00h
	xor cx,cx
	mov dh,[vga_rows]
	mov dl,[vga_columns]
	int 10h
	jmp .cursor
%endif
    
.text_clear:
	mov ax,0600h
	mov bh,07h
	xor cx,cx
	mov dh,[vga_rows]
	mov dl,[vga_columns]
	int 10h
	jmp .cursor

.cursor:
	mov ah,02h
	mov bh,0
	xor dx,dx
	int 10h
	popa
	ret
    

section .data
	hex_char_table	db "0123456789ABCDEF"
	vga_mode	db 03h
	vga_columns	db 80
	vga_rows	db 25
section .text
