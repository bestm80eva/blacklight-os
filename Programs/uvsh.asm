;; Blacklight OS uvShell
;; (c) 2011 Troy Martin
; Blacklight OS is licensed under the Simplified BSD License (see license.txt)
; http://www.opensource.org/licenses/bsd-license.php

; Small snippets of code borrowed from MikeOS-4.2 cli.asm.

%include "header.asm"				; Blacklight OS API calls
%include "../Kernel/defs.asm"			; Kernel defines - macros only!

%define UVSHELL_VERSION "0.0.1"

main:
	dprint `uvShell `, UVSHELL_VERSION, ` compiled for `, KERNEL_NAME, ` `, KERNEL_VERSION_STRING, `\n\n`
	
command_loop:
	
	mov di, input_buffer			; Clear input buffer each time
	mov al, 0
	mov cx, 256
	rep stosb

	mov di, command_buffer			; And single command buffer
	mov al, 0
	mov cx, 40
	rep stosb
	
	call disk_get_bootdev			; Display the prompt
	call direct_print_db
	dprint `/>`
	
	call shell_get_input			; Get input from the user
	dprint `\n`
	
	mov ax, input_buffer			; Take out any prefixed and trailing spaces
	call string_chomp

	mov si, input_buffer			; If just enter pressed, prompt again
	cmp byte [si], 0
	je command_loop

	mov si, input_buffer			; Separate out the individual command
	mov al, ' '
	call string_tokenize

	mov word [param_list], di		; Prepare parameters for passing a la MikeOS
	
	mov si, input_buffer			; Copy the command itself for later use.
	mov di, command_buffer
	mov cx, 31
	rep movsb
	
	mov ax, command_buffer			; Lowercase the command buffer
	call string_strlower
	
	mov si, command_buffer
	
	mov di, cmd_exit			; "exit"
	call string_strcmp
	jc do_exit
	
	mov di, cmd_ls				; "ls"
	call string_strcmp
	jc do_ls
	
	
	mov ax, command_buffer			; Okay, it wasn't an internal command they wanted
	call string_strupper			; Uppercase JUST the command
	
	mov si, input_buffer
	call direct_print
	dprint `\n`
	mov si, command_buffer
	call direct_print
	dprint `\n`
	
	mov si, command_buffer
	call string_strlen			; Return its length in AX

search_for_extension:
	mov si, command_buffer
	call string_strlen
	
	mov si, command_buffer			; Start searching for an extension
	add si, ax

	sub si, 4

	mov di, bin_extension			; Is there a .BIN extension?
	call string_strcmp
	jc found_file

	jmp no_extension
	
found_file:
	push es
	mov ax, 3000h
	mov es, ax
	mov ax, command_buffer
	mov cx, 0
	call fat12_load_file
	pop es
	jc total_fail

execute_bin:
	mov ax, 3000h				; Set up segments.
	mov ds, ax
	mov es, ax
	mov fs, ax

	mov ax, 0				; Clear all registers
	mov bx, 0
	mov cx, 0
	mov dx, 0
	mov word si, [param_list]		; Except for the one we're going to pass the parameter list in
	mov di, 0

	call 3000h:0000h			; Call the external program
	
	push cs
	pop ax
	mov ds, ax
	mov es, ax
	mov fs, ax
	
	dprint `\n`
	jmp command_loop			; When program has finished, start again


no_extension:
	mov si, command_buffer
	call string_strlen

	mov si, command_buffer
	add si, ax

	mov byte [si], '.'
	mov byte [si+1], 'B'
	mov byte [si+2], 'I'
	mov byte [si+3], 'N'
	mov byte [si+4], 0

	jmp found_file

total_fail:
	dprint `Could not find, load or execute "`
	mov si, command_buffer
	call direct_print
	dprint `".\n`
	jmp command_loop
	
	
; Internal commands

do_exit:
	dprint `\n\n`
	retf
	
do_ls:
	call fat12_read_root_dir	; Load the root directory into disk_buffer
	jc .disk_error			; Carry is set on error - inform the user if there's a disk error

	push ds
	mov ax, 1000h
	mov ds, ax
	mov si, disk_buffer
	
.repeat:
	push si
	
	mov al, [si+11]			; File attributes for entry
	cmp al, 0Fh			; Windows marker, skip it
	je .skip

	test al, 18h			; Is this a directory entry or volume label?
	jnz .skip			; Yes, ignore it

	mov al, [si]
	cmp al, 229			; If we read 229 = deleted filename
	je .skip

	cmp al, 0			; 1st byte = entry never used
	je .done
	
	mov al, 0			; Make sure tmp_string is zeroed out sufficently
	mov di, tmp_string
	mov cx, 14
	rep stosb
	
	mov di, tmp_string		; Now we need to copy the filename over
	mov cx, 11
	rep movsb
	
	mov di, tmp_string		; Locate the last character in the extension
	add di, 10
	
	mov al, [di]			; Move it right once.
	mov [di+1], al
	dec di				; Go back a step.
	
	mov al, [di]			; Do it again.
	mov [di+1], al
	dec di				; Back again.
	
	mov al, [di]			; Move it right once more.
	mov [di+1], al
	mov byte [di], ' '
	
	
	push cs
	pop ds
	mov si, tmp_string		; And finally, display the formatted filename.
	call direct_print
	
	mov si, .spaces			; Align everything up.
	call direct_print
	
	pop si				; Get the beginning of the entry again
	push si				; And store it for safe-keeping.
	mov ax, 1000h
	mov ds, ax
	
	mov dx, [si+28]			; Get the file's size.
	call direct_print_dec		; Print it.
	push cs
	pop ds
	dprint `\n`
	mov ax, 1000h
	mov ds, ax
	
.skip:
	pop si
	add si, 32			; Skip to the next directory entry
	jmp .repeat

.disk_error:
	mov si, .errmsg			; Uh oh, something went wrong with reading the disk!
	call direct_print		; Tell the user.
	jmp command_loop		; Bail out!
	
.done:
	pop si				; Unbreak the stack.
	pop ds					; Return registers.
	dprint `\n`
	jmp command_loop
	
.errmsg		db 'Disk error.', 0Ah ,0
.spaces		db '    ', 0
	
; Shell-specific custom input function
shell_get_input:
	mov ax, input_buffer
	mov bx, 255
	
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
	
	
cmd_exit	db "exit", 0
cmd_ls		db "ls", 0

bin_extension	db ".BIN", 0
	
input_buffer	times 256 db 0
command_buffer	times 48 db 0
param_list	dw 0

tmp_string	times 64 db 0			; Generic temporary string.
