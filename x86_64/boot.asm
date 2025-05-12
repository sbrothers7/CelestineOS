[org 0x7c00]            ; BIOS loads the bootloader at 0x7c00
[bits 16]               ; 16-bit real mode

start:
    mov [bootDrive], dl
    
    mov si, bootMsg
    call print16

    mov ah, 0x0e
    mov al, 0x02        ; number of sectors to load
    mov dl, [bootDrive] ; driver number to load (0 = boot disk)

    mov bp, 0x8000      ; set the stack somwhere safe
    mov sp, bp

    mov bx, 0x9000      ; es:bx = 0x0000:0x9000 = 0x09000
    call diskLoad

    call println16
    mov si, bootJumpMsg
    call print16

    jmp 0:0x9000

%include "includes/print16.asm"
%include "includes/diskLoad.asm"

bootMsg: db "Loading second stage bootloader...", 0
bootJumpMsg: db "Jumping...", 0
bootDrive: db 0

times 510 - ($ - $$) db 0   ; Pad to 510 bytes
dw 0xaa55                   ; Boot signature (required for BIOS boot)
