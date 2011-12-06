;; Blacklight OS common disk drive routines and macros
;; (c) 2011 Troy Martin
; Blacklight OS is licensed under the Simplified BSD License (see license.txt)
; http://www.opensource.org/licenses/bsd-license.php

%define DISK_NUM_TRIES 5

; reset_disk drive
%macro reset_disk 1
    mov ah,0
    mov dl,%1
    int 13h
%endmacro

%macro reset_disk_loop 1
    push cx
    mov cx,DISK_NUM_TRIES
%%derp:
    mov ah,0
    mov dl,%1
    int 13h
    jnc %%donederp
    loop %%derp
    pop cx
    derror `reset_disk_loop: Too many failed tries! Halting.`
    cli
    hlt
%%donederp:
    pop cx
%endmacro
    
    

; LOGICAL BLOCK ADDRESSING AND INT13H EXTENSIONS

; lba_structure lba buffer_segment buffer_offset count
; Probably doesn't work.
%macro lba_structure 4
    .size db 10h
    .reserved db 0
    .count dw %4
    .off dw %3
    .seg dw %2
    .lba dd %1
    .upper16 dd 0
%endmacro

; lba_read struct lba buffer_segment buffer_offset count drive
%macro lba_read 6
    mov dword [%1.lba],%2   ; LBA address of first sector
    mov word [%1.seg],%3    ; Buffer segment
    mov word [%1.off],%4    ; Buffer offset
    mov word [%1.count],%5  ; Sector count
    
    mov ah,42h
    mov dl,%6
    mov si,%1
    int 10h
%endmacro
    
; Check for the presence of int 13h extensions - most post-1990 BIOSes
; will indeed have them built in, but it's best to check anyways.
%macro int13_check 1
    mov ah,41h
    mov bx,55AAh
    mov dl,%1
    int 13h
%endmacro

int13_no_extensions:
    derror `int13_no_extensions: int 13h extensions could not be found. Halting.`
    cli
    hlt
    
lba_to_chs_00h:
	push bx
	push ax

	mov bx, ax			; Save logical sector

	mov dx, 0			; First the sector
	div word [dev00h_spt]
	add dl, 01h			; Physical sectors start at 1
	mov cl, dl			; Sectors belong in CL for int 13h
	mov ax, bx

	mov dx, 0			; Now calculate the head
	div word [dev00h_spt]
	mov dx, 0
	div word [dev00h_sides]
	mov dh, dl			; Head/side
	mov ch, al			; Track

	pop ax
	pop bx

	ret
    
lba_to_chs_01h:
	push bx
	push ax

	mov bx, ax			; Save logical sector

	mov dx, 0			; First the sector
	div word [dev01h_spt]
	add dl, 01h			; Physical sectors start at 1
	mov cl, dl			; Sectors belong in CL for int 13h
	mov ax, bx

	mov dx, 0			; Now calculate the head
	div word [dev01h_spt]
	mov dx, 0
	div word [dev01h_sides]
	mov dh, dl			; Head/side
	mov ch, al			; Track

	pop ax
	pop bx

	ret
    
; General disk read function
; disk_read drive sector count buffer_segment buffer_offset
;%macro disk_read 5
    
section .data
lbast1:
    .size db 10h
    .reserved db 0
    .count dw 0
    .off dw 0
    .seg dw 0
    .lba dd 0
    .upper16 dd 0
section .text
