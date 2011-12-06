;; Blacklight OS kernel defines and includes
;; (c) 2011 Troy Martin
; Blacklight OS is licensed under the Simplified BSD License (see license.txt)
; http://www.opensource.org/licenses/bsd-license.php

; Kernel version data
%define KERNEL_VERSION_MAJOR 0
%define KERNEL_VERSION_MINOR 0
%define KERNEL_VERSION_RELEASE 2
%define KERNEL_VERSION_STRING "0.0.2"
%define KERNEL_NAME "Blacklight OS"

; BIOS error codes
%define BIOS_ERROR_NOT_SUPPORTED 86h

; Macros

%macro asciz 1+
    db %1,0
%endmacro

section .data
    hex_char_table db "0123456789ABCDEF"
section .text
