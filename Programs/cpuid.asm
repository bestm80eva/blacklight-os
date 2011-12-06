; ------------------------------------------------------------------
; Extended CPUID for Blacklight OS
; Written by Troy Martin
; ------------------------------------------------------------------


	%include "header.asm"
	
%macro print 1+					; It's not lazy, it's just good use of NASM's macro features.
	section .data
		%%string db %1, 0
	section .text


	mov si,%%string
	call direct_print
%endmacro


start:
	print 'Extended CPUID - written by Troy Martin', 0Ah, 0Ah
	
cpuid_get_vendor_string:
	xor eax, eax				; Get the 12-byte processor vendor string.
	cpuid					; This function is present on all CPUID-enabled processors.

	mov [cpuid_vendor_string], ebx		; Store it in the string buffer.
	mov [cpuid_vendor_string+4], edx
	mov [cpuid_vendor_string+8], ecx

cpuid_get_processor_fms:
	mov eax, 1				; Get the processor features and CPU signature (family info)
	cpuid
	
	mov [cpuid_processor_features], edx	; Save the processor feature DWORD - we'll parse this later.

	push eax				; Get the stepping.
	and eax, 000Fh
	mov [cpuid_processor_stepping], eax
	pop eax
	
	push eax				; Get the model.
	and eax, 00F0h
	shr eax, 4
	mov [cpuid_processor_model], eax
	pop eax
	
	push eax				; Get the family.
	and eax, 0F00h
	shr eax, 8
	mov [cpuid_processor_family], eax
	pop eax
	
cpuid_show_info:
	print '    CPU vendor string: '
	mov si, cpuid_vendor_string
	call direct_print
	print 0Ah
	
	mov eax, 80000000h			; Request the highest extended CPUID function number.
	cpuid
	
	cmp eax, 80000004h			; Can we call 80000002h through 80000004h?
	jl .nostring				; If not, skip this section.
	
	mov di, cpuid_processor_string		; Throw the destination buffer into DI
	
	mov eax, 80000002h			; Get the first sixteen bytes of the processor ID string
	cpuid
	stosd					; Store EAX
	mov eax, ebx
	stosd					; Store EBX
	mov eax, ecx
	stosd					; Store ECX
	mov eax, edx
	stosd					; Store EDX
	
	mov eax, 80000003h			; Get the middle sixteen bytes of the processor ID string
	cpuid
	stosd					; Store EAX
	mov eax, ebx
	stosd					; Store EBX
	mov eax, ecx
	stosd					; Store ECX
	mov eax, edx
	stosd					; Store EDX
	
	mov eax, 80000004h			; Get the last sixteen bytes of the processor ID string
	cpuid
	stosd					; Store EAX
	mov eax, ebx
	stosd					; Store EBX
	mov eax, ecx
	stosd					; Store ECX
	mov eax, edx
	stosd					; Store EDX
	
	print '    CPU name:     '
	
	mov ax, cpuid_processor_string		; Intel seems to have leading spaces to pad the whole
	call string_chomp			; thing out to 48 bytes. This is the case on the i7.
	
	mov si, cpuid_processor_string		; Finally, output the processor ID string.
	call direct_print
	print 0Ah
	
	
.nostring:
	print '    CPU family:   '
	mov edx, [cpuid_processor_family]	; high word of EAX should be zeroes anyways.
	call direct_print_dec
	print 0Ah
	
	print '        model:    '
	mov edx, [cpuid_processor_model]	; high word of EAX should be zeroes anyways.
	call direct_print_dec
	print 0Ah
	
	print '        stepping: '
	mov edx, [cpuid_processor_stepping]	; high word of EAX should be zeroes anyways.
	call direct_print_dec
	print 0Ah
	
cpuid_show_features:				; This is where things get boring.
	mov edx, [cpuid_processor_features]	; Load up the processor features we stored earlier.
	print '    CPU features: '
	
.fpu:
	bt edx, 0
	jnc .vme
	print 'fpu '

.vme:
	bt edx, 1
	jnc .de
	print 'vme '
	
.de:
	bt edx, 2
	jnc .pse
	print 'de '

.pse:
	bt edx, 3
	jnc .tsc
	print 'pse '
	
.tsc:
	bt edx, 4
	jnc .msr
	print 'tsc '
	
.msr:
	bt edx, 5
	jnc .pae
	print 'msr '

.pae:
	bt edx, 6
	jnc .mce
	print 'pae '
	
.mce:
	bt edx, 7
	jnc .cx8
	print 'mce '
	
.cx8:
	bt edx, 8
	jnc .apic
	print 'cx8 '
	
.apic:
	bt edx, 9
	jnc .sep
	print 'apic '
	
.sep:
	bt edx, 11
	jnc .mtrr
	print 'sep '
	
.mtrr:
	bt edx, 12
	jnc .pge
	print 'mtrr '
	
.pge:
	bt edx, 13
	jnc .mca
	print 'pge '
	
.mca:
	bt edx, 14
	jnc .cmov
	print 'mca '
	
.cmov:
	bt edx, 15
	jnc .pat
	print 'cmov '
	
.pat:
	bt edx, 16
	jnc .pse36
	print 'pat '
	
.pse36:
	bt edx, 17
	jnc .pn
	print 'pse36 '
	
.pn:
	bt edx, 18
	jnc .clflush
	print 'pn '
	
.clflush:
	bt edx, 19
	jnc .dts
	print 'clflush '
	
.dts:
	bt edx, 21
	jnc .acpi
	print 'dts '
	
.acpi:
	bt edx, 22
	jnc .mmx
	print 'acpi '
	
.mmx:
	bt edx, 23
	jnc .fxsr
	print 'mmx '
	
.fxsr:
	bt edx, 24
	jnc .sse
	print 'fxsr '
	
.sse:
	bt edx, 25
	jnc .sse2
	print 'sse '
	
.sse2:
	bt edx, 26
	jnc .ss
	print 'sse2 '
	
.ss:
	bt edx, 27
	jnc .ht
	print 'ss '
	
.ht:
	bt edx, 28
	jnc .tm
	print 'ht '
	
.tm:
	bt edx, 29
	jnc .ia64
	print 'tm '
	
.ia64:
	bt edx, 30
	jnc .pbe
	print 'ia64 '
	
.pbe:
	bt edx, 31
	jnc .done
	print 'pbe '
	
	
.done:
cpuid_check_itanium:
	mov edx, [cpuid_processor_features]
	bt edx, 29
	jnc bios_test
	print 0Ah
	print 'MikeOS is running on an Itanium emulating x86!', 0Dh, 0Ah
	
bios_test:
	jmp program_end				; BIOS detection is bugged to hell and back.
.amibios:					; American Megatrends AMI BIOS
	mov ax, 0DB04h				; AMI BIOS - Get BIOS Revision
	int 15h
	jc .sunvbox
	print 'Running on a system with an AMI BIOS.', 0Dh, 0Ah
	jmp program_end
	
.sunvbox:					; Sun xVM VirtualBox BIOS
	push es
	mov ax, 0F000h				; Load up the BIOS segment
	mov es, ax
	
	mov bx, 0FF00h				; VBox stores its BIOS string here usually
	mov eax, dword [es:bx]			; Grab first DWORD of string
	pop es					; Restore DS from the stack
	cmp eax, " nuS"				; BIOS string starts with "Sun "
	jne .oraclevbox
	print 'Running on Sun xVM VirtualBox.', 0Dh, 0Ah
	jmp program_end
	
.oraclevbox:					; Oracle VM VirtualBox BIOS
	push es
	mov ax, 0F000h				; Load up the BIOS segment
	mov es, ax
	
	mov bx, 0FF00h				; VBox stores its BIOS string here usually
	mov eax, dword [es:bx]			; Grab first DWORD of string
	pop es					; Restore DS from the stack
	cmp eax, "carO"				; BIOS string starts with "carO"
	jne .oraclevbox
	print 'Running on Oracle VM VirtualBox.', 0Dh, 0Ah
	
	
program_end:
	print 0Ah, 0Ah
	retf
	

	cpuid_vendor_string		times 13 db 0
	cpuid_processor_string		times 49 db 0
	cpuid_processor_stepping	dd 0
	cpuid_processor_model		dd 0
	cpuid_processor_family		dd 0
	cpuid_processor_features	dd 0


; ------------------------------------------------------------------

