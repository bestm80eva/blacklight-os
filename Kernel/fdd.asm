;; Blacklight OS floppy drive routines
;; (c) 2011 Troy Martin
; Blacklight OS is licensed under the Simplified BSD License (see license.txt)
; http://www.opensource.org/licenses/bsd-license.php

; fdd_read_chs drive count cyl head sec seg off
%macro fdd_read_chs 7
%%go:
    reset_disk_loop %1
    mov ah,02h
    mov al,%2
    mov ch,%3
    mov cl,%5
    mov dh,%4
    mov dl,%1
    push es
    push ax
    mov ax,%6
    mov es,ax
    pop ax
    mov bx,%7
    int 13h
    pop es
    jnc %%done
    derror `fdd_read_chs: Read failed.`
    jmp %%go
%%done:
%endmacro

; fdd_read_lba drive count lba seg off
%macro fdd_read_lba 5
%%go:
    reset_disk_loop %1
    mov ax,%3
    call lba_to_chs_%1
    mov ax,%2
    mov ah,02h
    mov dl,%1
    push es
    push ax
    mov ax,%6
    mov es,ax
    pop ax
    mov bx,%7
    int 13h
    pop es
    jnc %%done
    derror `fdd_read_lba: Read failed.`
    jmp %%go
%%done:
%endmacro
    
section .data
fdd_single_sector_buffer times 512 db 0
dev00h_spt dw 0
dev00h_sides dw 0
dev01h_spt dw 0
dev01h_sides dw 0
section .text
