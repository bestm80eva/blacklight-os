;; Blacklight OS main kernel file
;; (c) 2011 Troy Martin
; Blacklight OS is licensed under the Simplified BSD License (see license.txt)
; http://www.opensource.org/licenses/bsd-license.php

	bits 16
	org 0

%ifndef target
	%warning "No target specified, defaulting to 586 (Pentium)."
	%define target 5
	CPU 586
%endif

%if target == 0
	%fatal "Cannot target 8086: Use 3(86) or higher."
%elif target == 1
	%fatal "Cannot target 186: Use 3(86) or higher."
%elif target == 2
	%fatal "Cannot target 286: Use 3(86) or higher."
%elif target == 3
	CPU 386
%elif target == 4
	CPU 486
%elif target == 5
	CPU 586
%elif target == 6
	CPU 686
%else
	%warning "Unknown target, defaulting to 586 (Pentium)."
%endif


%include "defs.asm"				; Include base defines

kernel_entry:
; Ignore the module code.
	jmp kernel_go

; System call stuff
	%include "syscall.asm"			; System call table - MOVING THIS FUCKS PROGRAMS

; Built-in kernel modules go here
	%include "vga_text.asm"			; Direct VGA output
	%include "keyboard.asm"			; Direct keyboard input

	%include "math.asm"			; Math/string functions
	%include "mm.asm"			; Memory management (segment allocation)
	%include "ivt.asm"			; Interrupts

	%include "ddcommon.asm"			; Common disk functions - dunno if used
	%include "fdd.asm"			; Common floppy functions - dunno if used

	%include "fs/fat12.asm"			; FAT12 floppy support

	%include "extras/apm.asm"		; Advanced Power Management - shutdown, restart (standby NYI)

%if target >= 5
	%include "extras/cpuid.asm"		; Basic CPUID stuff
%endif


kernel_go:					; Initialize the kernel
.setup_stack:					; We need to set up a stack first.
	cli
	xor ax, ax
	mov ss, ax
	mov sp, 0F000h
	sti

.setup_segments:				; Initialize kernel data segments
	push cs
	pop ax					; We should now be back at SP=0F000h

	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov word [kernel_segment], ax		; Store the kernel segment for emergency reloading


; Kernel proper
kernel_main:
	dprint KERNEL_NAME,` `,KERNEL_VERSION_STRING,`\nKernel loaded.\n\n`

; At this point, the boot sector is still fresh in memory. Let's exploit it.
.update_dev00:
	mov ax,07C0h
	mov ds,ax
	mov si,18h
	mov di,dev00h_spt
	movsw
	mov si,1Ah
	mov di,dev00h_sides
	movsw
	mov ax,1000h
	mov ds,ax

; Grab some info from CPUID
.get_cpuid:
%ifdef EXTRA_CPUID
	xor eax,eax
	cpuid

	mov [cpuid_vendor_string],ebx
	mov [cpuid_vendor_string+8],ecx
	mov [cpuid_vendor_string+4],edx

	mov eax,1
	cpuid

	push eax
	and eax,1111b
	mov [cpuid_processor_stepping],eax
	pop eax
	push eax
	and eax,11110000b
	shr eax,4
	mov [cpuid_processor_model],eax
	pop eax
	push eax
	and eax,111100000000b
	shr eax,8
	mov [cpuid_processor_family],eax
	pop eax

	dprint `Running on `
	dprinto cpuid_vendor_string
	dprint `, family: `
	mov edx,[cpuid_processor_family]
	call direct_print_dec
	dprint `, model: `
	mov edx,[cpuid_processor_model]
	call direct_print_dec
	dprint `, stepping: `
	mov edx,[cpuid_processor_stepping]
	call direct_print_dec
%endif

.install_interrupts:
	dprint `.\n\nInstalling interrupts: `

	xor cx,cx
	mov dx,interrupt_isr_00h
	;mov dx,1000h
	call interrupt_set_gate

	dprint `00h `

	; ...

	dprint `...Done!\n`

.install_apm:
%ifdef EXTRA_APM
	call apm_check_exist
	jc .noapm
	call apm_connect
	jc .apmfail
	dprint `apm_connect: Advanced Power Management `

	mov dh,0
	mov dl,byte [apm_version_major]
	call direct_print_dec

	dprintc '.'

	mov dh,0
	mov dl,byte [apm_version_minor]
	call direct_print_dec

	dprint ` interface connected.\n`
	jmp .noapm

.apmfail:
	derror `apm_connect: Could not connect to APM interface.\n`

.noapm:
%endif

.find_shell:
	mov ax, shellname			; Check to see if the shell exists
	call fat12_file_exists
	jnc .load_shell
	
	dprint `\nCould not find/load a shell. Enter filename of a shell to execute: `
	mov ax, shellname
	mov bx, 12
	call direct_input
	jmp .find_shell

.load_shell:
	mov ax, shellname
	mov cx, file_buffer
	call fat12_load_file
	jc .find_shell

	mov ax, 2000h
	mov es, ax
	mov si, file_buffer
	xor di, di
	mov cx, bx
	rep movsb

	mov ax, 2000h
	mov ds, ax
	mov es, ax
	mov fs, ax

	xor ax, ax
	mov bx, ax
	mov cx, ax
	mov dx, ax
	mov si, ax
	mov di, ax

	call 2000h:0000h

	push cs
	pop ax
	mov ds, ax
	mov es, ax
	mov fs, ax

	jmp .find_shell

shutdown:
%ifdef EXTRA_APM
	dprint `\n\nPress any key to shut down...`
	xor ax,ax
	int 16h
	call apm_power_off
	derror `apm_power_off: Could not power off computer via APM. Halted.`
%endif


kernel_emergency_halt:				; We really shouldn't get to here.
	cli
	hlt					; Hit the button so we don't execute strings and garbage.

	
kernel_core_data:				; This is the core kernel data section. It's always just before .data.
	kernel_segment	dw 1000h		; Defaults to 1000h - good for sanity
	kernel_version	db KERNEL_VERSION_STRING, 0
	

section .data
	shellname db "UVSH.BIN", 0, 0, 0, 0, 0
