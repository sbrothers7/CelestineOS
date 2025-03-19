BITS 16

start:
    cli

    mov si, bootMsg
    call printString
    call printNewline

    call setPIT
    call wait3s
    
    .noInput:
        call handleClear
        jmp enableProtectedMode

load16B:
    call handleClear

    mov si, loading16Msg
    call printString
    call printNewline
    call printNewline

    mov si, helloMsg
    call printString
    call printNewline
    call printNewline

    .getInput:
        call readInput
        call processCommand 
        jmp .getInput

    jmp exit

setPIT:
    mov al, 0x36            ; Mode 2 (Rate Generator)
    out 0x43, al            ; Send mode command to PIT

    mov ax, 1000000         ; ??? 
    out 0x40, al            ; Send low byte
    mov al, ah
    out 0x40, al            ; Send high byte

    ret

wait3s:
    mov cx, 17000
    .waitLoop:
        ; space
        mov al, ' '
        int 0x10

        ; backspace
        mov al, 8
        int 0x10
        mov al, ' '
        int 0x10
        mov al, 8
        int 0x10

        mov ah, 0x01        ; BIOS check keyboard buffer
        int 0x16            ; zero flag (ZF) is set if no key is available
        jnz load16B

        in al, 0x40         ; read PIT counter
        loop .waitLoop      ; decrease CX, loop if not 0

        ret

%include "includes/print.asm"
readInput:
    mov di, inputBuffer     ; point to inputBuffer
    xor cx, cx              ; track input length
    .loop:
        mov ah, 0x00        ; BIOS: Wait for keypress
        int 0x16            ; AL = ASCII, AH = Scan code

        cmp al, 13          ; compare with enter (ASCII 13)
        je .return

        cmp al, 8           ; compare with backspace (ASCII 8)
        je .backspace
        cmp al, 127         ; in some cases, QEMU treats backspace as delete
        je .backspace

        stosb               ; store al to buffer at [di], di++
        inc cx

        mov ah, 0x0e        ; BIOS: Print character in AL
        int 0x10
        jmp .loop
    .backspace:
        cmp cx, 0           ; do nothing if buffer is empty
        je .loop

        dec di              ; decrease di by 1
        dec cx              ; reduce length by 1
        mov byte [di], 0

        mov al, 8           ; move cursor back
        int 0x10
        mov al, ' '         ; print a space to erase character
        int 0x10
        mov al, 8           ; move cursor back again to correct position
        int 0x10
        jmp .loop
    .return:
        xor al, al
        stosb               ; null terminate the buffer
        call printNewline
        ret

compareStrings:
    .loop:
        mov al, [si]    
        mov bl, [di]

        cmp bl, 0           ; check null terminator at end of string
        je .equal
        cmp al, bl          ; compare AL with BL
        jne .notEqual

        inc si
        inc di

        jmp .loop           ; otherwise, keep comparing
    .notEqual:
        ; mov si, debugNotEqual
        ; call printString
        ; call printNewline
        xor ax, ax
        ret

    .equal:
        ; mov si, debugEqual
        ; call printString
        ; call printNewline
        mov ax, 1
        ret

processCommand:
    mov si, inputBuffer
    .checkEcho:
        mov di, echoCmd
        call compareStrings
        test ax, ax
        jz .checkClear

        call handleEcho
        ret

    .checkClear:
        mov di, clearCmd
        call compareStrings
        test ax, ax
        jz .checkHelp

        call handleClear
        ret

    .checkHelp:
        mov di, helpCmd
        call compareStrings
        test ax, ax
        jz .checkShutdown

        call handleHelp
        ret

    .checkShutdown:
        mov di, shutdownCmd
        call compareStrings
        test ax, ax
        jz .checkReboot

        call handleShutdown
        ret

    .checkReboot:
        mov di, rebootCmd
        call compareStrings
        test ax, ax
        jz .checkRestart

        call handleReboot
        ret
    
    .checkRestart:
        mov di, rebootCmdAlt
        call compareStrings
        test ax, ax
        jz .errorMessage

        call handleReboot
        ret

    .errorMessage:
        mov si, errorMsg
        call printString
        call printNewline
        ret

handleEcho:
    mov si, inputBuffer
    add si, 5               ; skip "echo "
    call printString
    call printNewline
    ret

handleClear:
    ; clear screen using BIOS function 0x06
    mov ah, 0x06
    mov al, 0               ; clear entire screen
    mov bh, 0x07            ; text attribute (white on black)
    mov cx, 0               ; upper-left corner
    mov dx, 0x184f          ; lower-right corner (80x25 screen)
    int 0x10                ; BIOS video interrupt

    ; move cursor to top-left corner (0,0)
    mov ah, 0x02            ; set cursor position
    mov bh, 0               ; page number
    mov dh, 0               ; row (Y = 0)
    mov dl, 0               ; column (X = 0)
    int 0x10                ; BIOS video interrupt

    ret

handleHelp:
    mov si, helpMsg
    call printString
    call printNewline
    ret

handleShutdown:
    mov si, shutdownMsg
    call printString
    call printNewline

    ; Try to shut down using QEMU
    mov ax, 0x5307          ; APM BIOS function
    mov bx, 0x0001          ; device = Power Management
    mov cx, 0x0003          ; command = Power Off
    int 0x15                ; call BIOS

    ; If APM fails, enter infinite halt
    cli
    hlt
    jmp $

handleReboot:
    mov si, rebootMsg
    call printString
    call printNewline

    ; Send CPU reset
    jmp 0xffff:0x0000  ; Jump to BIOS reset vector

exit:
    jmp exit

enableProtectedMode:
    mov si, loading32Msg
    call printString
    call printNewline

inputBuffer: times 32 db 0

echoCmd db "echo", 0
clearCmd db "clear", 0
helpCmd db "help", 0
shutdownCmd db "shutdown", 0
rebootCmd db "reboot", 0
rebootCmdAlt db "restart", 0

debugEqual db "Strings match!", 0
debugNotEqual db "Strings do not match!", 0
debug db "debug", 0

errorMsg db "Command not found!", 0
helpMsg db "Commands: echo, clear, help, shutdown, reboot (restart)", 0
shutdownMsg db "Shutting down...", 0
rebootMsg db "Rebooting...", 0
helloMsg db "Welcome to CelestineOS", 0

bootMsg db "Press any key for 16-bit Kernel. Booting 32-bit in 3 seconds...", 0
loading16Msg db "Loading 16-bit kernel...", 0
loading32Msg db "Loading 32-bit kernel...", 0

times 1024 - ($ - $$) db 0