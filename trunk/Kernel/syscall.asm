;; Blacklight OS system call table (kernel side)
;; (c) 2011 Troy Martin
; Blacklight OS is licensed under the Simplified BSD License (see license.txt)
; http://www.opensource.org/licenses/bsd-license.php

syscall_direct_print:
	nop					; NOPs serve as handy markers for each syscall when determining where to far call to
	push bx
	mov bx, 0007h				; Terminal colour
	call direct_print
	pop bx
	retf
	
syscall_direct_print_dec:
	nop
	call direct_print_dec
	retf
	
syscall_direct_print_db:
	nop
	push ds
	push cs
	pop ds
	call direct_print_db
	pop ds
	retf
	
syscall_direct_print_dw:
	nop
	push ds
	push cs
	pop ds
	call direct_print_dw
	pop ds
	retf
	
syscall_vga_clear_screen:
	nop
	call vga_clear_screen
	retf
	
syscall_string_chomp:
	nop
	call direct_string_chomp
	retf

syscall_direct_input:
	nop
	call direct_input
	retf
	
syscall_kernel_get_version:
	nop
	mov ax, KERNEL_VERSION_MAJOR
	mov bx, KERNEL_VERSION_MINOR
	mov cx, KERNEL_VERSION_RELEASE
	mov dx, kernel_version			; String pointer!
	retf

syscall_fat12_read_root_dir:
	nop
	push ds
	push es
	push cs
	pop ax
	mov ds, ax
	mov es, ax
	call disk_read_root_dir
	pop es
	pop ds
	retf

syscall_fat12_load_file:
	nop
	push ds
	push es
	push cx
	push ax
	push cs
	pop ax
	mov ds, ax
	mov es, ax
	pop ax
	mov cx, file_buffer
	call fat12_load_file
	jc .error
	
	pop di
	pop es
	mov si, file_buffer
	mov cx, bx
	rep movsb
	pop ds
	retf
	
.error:
	pop cx
	pop es
	pop ds
	retf

syscall_fat12_write_file:
	nop
	push ds
	push es
	push ax
	push cx
	push cs
	pop es
	mov di, file_buffer
	mov si, bx
	rep movsb
	
	pop cx
	pop ax
	push cs
	pop ds
	mov bx, file_buffer
	call fat12_write_file
	pop es
	pop ds
	retf
	
syscall_fat12_file_exists:
	nop
	push ds
	push es
	push ax
	push cs
	pop ax
	mov ds, ax
	mov es, ax
	pop ax
	call fat12_file_exists
	pop es
	pop ds
	retf

syscall_fat12_create_file:
	nop
	push ds
	push es
	push ax
	push cs
	pop ax
	mov ds, ax
	mov es, ax
	pop ax
	call fat12_create_file
	pop es
	pop ds
	retf

syscall_fat12_delete_file:
	nop
	push ds
	push es
	push ax
	push cs
	pop ax
	mov ds, ax
	mov es, ax
	pop ax
	call fat12_delete_file
	pop es
	pop ds
	retf

syscall_fat12_rename_file:
	nop
	push ds
	push es
	push ax
	push cs
	pop ax
	mov ds, ax
	mov es, ax
	pop ax
	call fat12_rename_file
	pop es
	pop ds
	retf

syscall_fat12_get_file_size:
	nop
	push ds
	push es
	push ax
	push cs
	pop ax
	mov ds, ax
	mov es, ax
	pop ax
	call fat12_get_file_size
	pop es
	pop ds
	retf
	
syscall_disk_get_bootdev:
	nop
	push ds
	push cs
	pop ds
	mov dl, byte [bootdev]
	pop ds
	retf
	
syscall_string_tokenize:
	nop
	call direct_string_tokenize
	retf
	
syscall_strcmp:
	nop
	call direct_strcmp
	retf
	
syscall_strncmp:
	nop
	call direct_strncmp
	retf
	
syscall_strlen:
	nop
	call direct_strlen
	retf
	
syscall_strlower:
	nop
	call direct_strlower
	retf
	
syscall_strupper:
	nop
	call direct_strupper
	retf
