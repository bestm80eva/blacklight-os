;; Blacklight OS CPUID family/model mappings
;; 2011 Blacklight
; Blacklight OS is licensed under the Simplified BSD License (see license.txt)
; http://www.opensource.org/licenses/bsd-license.php

%define EXTRA_CPUID

; CPUID vendor strings
%define CPUID_VENDOR_OLDAMD       "AMDisbetter!"
%define CPUID_VENDOR_AMD          "AuthenticAMD"
%define CPUID_VENDOR_INTEL        "GenuineIntel"
%define CPUID_VENDOR_VIA          "CentaurHauls"
%define CPUID_VENDOR_OLDTRANSMETA "TransmetaCPU"
%define CPUID_VENDOR_TRANSMETA    "GenuineTMx86"
%define CPUID_VENDOR_CYRIX        "CyrixInstead"
%define CPUID_VENDOR_CENTAUR      "CentaurHauls"
%define CPUID_VENDOR_NEXGEN       "NexGenDriven"
%define CPUID_VENDOR_UMC          "UMC UMC UMC "
%define CPUID_VENDOR_SIS          "SiS SiS SiS "
%define CPUID_VENDOR_NSC          "Geode by NSC"
%define CPUID_VENDOR_RISE         "RiseRiseRise"

; ZF=0 = not supported
%macro test_cpuid 0
    pushfd
    pop eax
    mov ecx,eax
    xor eax,0x200000
    push eax
    popfd
    pushfd
    pop eax
    xor eax, ecx
    shr eax, 21
    and eax, 1
    push ecx
    popfd
%endmacro


cpuid_map:
    

section .data
cpuid_vendor_string times 13 db 0
cpuid_processor_stepping dd 0
cpuid_processor_model dd 0
cpuid_processor_family dd 0

cpuid_family_pentium asciz "Pentium"
cpuid_model_P5 asciz "P5/54/54CQS"
cpuid_model_P54CS asciz "P54CS"
cpuid_model_P55C asciz "MMX P55C"

section .text
