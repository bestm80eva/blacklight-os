;; Blacklight OS Advanced Power Management routines
;; 2011 Blacklight
; Blacklight OS is licensed under the Simplified BSD License (see license.txt)
; http://www.opensource.org/licenses/bsd-license.php

%define EXTRA_APM

; Error codes.
%define APM_ERROR_DISABLED 01h
%define APM_ERROR_CONNECTED 02h
%define APM_ERROR_NOT_CONNECTED 03h
%define APM_ERROR_RMODE_NOT_CONNECTED 04h
%define APM_ERROR_BAD_DEVICE_ID 09h
%define APM_ERROR_INVALID_CX 0Ah
%define APM_ERROR_NOT_PRESENT 86h

apm_check_exist:
    mov ax,5300h
    xor bx,bx
    int 15h
    jc .done
    mov [apm_flags],cx
    mov [apm_version_major],ah
    mov [apm_version_minor],al
.done:
    ret
    
apm_connect:
    mov ax,5301h
    xor bx,bx
    int 15h
    ret
    
apm_disconnect:
    mov ax,5304h
    xor bx,bx
    int 15h
    ret
    
apm_get_power_status:
    mov ax,530Ah
    mov bx,0001h
    int 15h
    jc .done
    mov [apm_ac_status],bh
    mov [apm_battery_status],bl
    mov [apm_battery_percent],cl
.done:
    ret
    
apm_power_off:
    cmp byte [apm_version_minor],02h
    jge .go
    stc
    ret

.go:
    mov ax,5307h
    mov bx,0001h
    mov cx,0003h
    int 15h
    clc     ; Clear carry in case of failure.
    ret     ; It really shouldn't return...

section .data
    apm_flags dw 0
    apm_version_major db 0
    apm_version_minor db 0
    apm_support_major db 01h
    apm_support_minor db 00h
    apm_ac_status db 0
    apm_battery_status db 0
    apm_battery_percent db 0
section .text
