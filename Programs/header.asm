;; Blacklight OS system call table and program defines
;; (c) 2011 Troy Martin
; Blacklight OS is licensed under the Simplified BSD License (see license.txt)
; http://www.opensource.org/licenses/bsd-license.php

;; Include this file at the beginning of your program's source code.

bits 16
org 0

%macro dprint 1+
	section .data
		%%string db %1, 0
	section .text


	mov si,%%string
	call direct_print
%endmacro

; Disk constants
disk_buffer			equ 24576	; Internal disk buffer
file_buffer			equ 32768	; Internal file loading buffer

; Direct screen output
%define direct_print		1000h:0004h
%define direct_print_dec	1000h:000Eh
%define direct_print_db		1000h:0013h
%define direct_print_dw		1000h:001Ch

; Video functions
%define vga_clear_screen	1000h:0025h

; String and math functions
%define string_chomp		1000h:002Ah
%define string_tokenize		1000h:00EEh
%define string_strcmp		1000h:00F3h
%define string_strncmp		1000h:00F8h
%define string_strlen		1000h:00FDh
%define string_strlower		1000h:0102h
%define string_strupper		1000h:0107h

; Keyboard functions
%define direct_input		1000h:002Fh

; Misc. kernel functions
%define kernel_get_version	1000h:0034h

; FAT12 routines - Make sure to set FS to CS before using!
%define fat12_read_root_dir	1000h:0042h
%define fat12_load_file		1000h:0051h
%define fat12_write_file	1000h:0074h
%define fat12_file_exists	1000h:008Fh
%define fat12_create_file	1000h:00A0h
%define fat12_delete_file	1000h:00B1h
%define fat12_rename_file	1000h:00C2h
%define fat12_get_file_size	1000h:00D3h
%define disk_get_bootdev	1000h:00E4h