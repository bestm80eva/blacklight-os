%include "header.asm"

mov si, message
call direct_print
retf

message db "Hello from user space!", 0Ah, 0