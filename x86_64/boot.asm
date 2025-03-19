ORG 0x7c00              ; BIOS loads the bootloader at 0x7c00
BITS 16                 ; 16-bit real mode

start:
    mov [bootDrive], dl
    
    mov si, bootMsg
    call printString

    mov ah, 0x0e
    mov al, 2           ; number of sectors to load
    mov dl, [bootDrive] ; driver number to load (0 = boot disk)

    ; ES:BX (address:offset)
    mov bx, 0x9000
    mov es, bx
    mov bx, 0

    call diskLoad

    call printNewline
    ; mov si, bootJumpMsg
    ; call printString
    call printNewline

    cli
    mov ax, 0x9000
    mov ds, ax
    mov es, ax
    ; mov ax, 0x7000  ; Move stack lower
    ; mov ss, ax
    ; mov sp, 0xfff0
    sti

    jmp 0x9000:0000

%include "includes/print.asm"
%include "includes/diskLoad.asm"

bootMsg: db "Loading CelestineOS...", 0
bootJumpMsg: db "Jumping...", 0
bootDrive: db 0

times 510 - ($ - $$) db 0   ; Pad to 510 bytes
dw 0xaa55                   ; Boot signature (required for BIOS boot)