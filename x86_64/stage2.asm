[bits 16]
[org 0x9000]

start:
    call handleClear

    cli
    mov si, bootMsg
    call print16
    call println16

    call delay
    jmp enableProtectedMode

load16B:
    call handleClear

    mov si, loading16Msg
    call print16
    call println16
    call println16

    call handleClear

    mov si, helloMsg
    call print16
    call println16
    call println16

    .getInput:
        call readInput
        call processCommand 
        jmp .getInput

    jmp exit

delay:
    mov ah, 0x86        ; Wait function
    mov cx, 0x0007      ; Upper 16 bits
    mov dx, 0xA120      ; Lower 16 bits

    ; Duration          CX:DX Value
    ; 500ms             0x0007, 0xA120
    ; 1s                0x000F, 0x4240
    ; 2s                0x001E, 0x8480
    ; 3s                0x002D, 0xC6C0

    int 0x15            ; Call BIOS

    mov ah, 0x01        ; BIOS check keyboard buffer
    int 0x16            ; zero flag (ZF) is set if no key is available
    jnz load16B
    ret

%include "includes/kernel16.asm"    ; includes input handling
%include "includes/print16.asm"

helloMsg db "Welcome to CelestineOS", 0

bootMsg db "Press any key for 16-bit kernel. Booting 32-bit kernel in 3 seconds...", 0
loading16Msg db "Loading 16-bit kernel...", 0
loading32Msg db "Loading 32-bit kernel...", 0

; ====================== Transition to 32 bit ======================

%include "includes/gdt.asm"
enableProtectedMode:
    cli
    lgdt [gdt32_descriptor]   ; load Global Descriptor Table (GDT)

    ; enable Protected Mode
    mov eax, cr0
    or eax, 0x1             ; set PE bit
    mov cr0, eax
    
    jmp CODE32_SEL:init32   ; far jump to 32-bit mode

[bits 32]
init32:
    mov ax, DATA32_SEL      ; update segment registers
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    mov ebp, 0x90000        ; set stack to top of free space
    mov esp, ebp

    jmp kernel

kernel:
    call clearScreen32

    mov esi, welcomeMsg
    call print32
    jmp $

%include "includes/utils32.asm"

welcomeMsg db "Successfully entered 32-bit mode. Attempting to enter long mode.", 0
times 1536 - ($ - $$) db 0
