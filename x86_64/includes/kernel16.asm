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
        call println16
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
        ; call print16
        ; call println16
        xor ax, ax
        ret

    .equal:
        ; mov si, debugEqual
        ; call print16
        ; call println16
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
        jz .checkRestart

        call handleShutdown
        ret
    
    .checkRestart:
        mov di, restartCmd
        call compareStrings
        test ax, ax
        jz .errorMessage

        jmp handleRestart

    .errorMessage:
        mov si, errorMsg
        call print16
        call println16
        ret

handleEcho:
    mov si, inputBuffer
    add si, 5               ; skip "echo "
    call print16
    call println16
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
    call print16
    call println16
    ret

handleShutdown:
    mov si, shutdownMsg
    call print16
    call println16

    ; Try to shut down using QEMU
    mov ax, 0x5307          ; APM BIOS function
    mov bx, 0x0001          ; device = Power Management
    mov cx, 0x0003          ; command = Power Off
    int 0x15                ; call BIOS

    ; If APM fails, enter infinite halt
    cli
    hlt
    jmp $

handleRestart:
    mov si, rebootMsg
    call print16
    call println16

    ; Send CPU reset
    jmp 0xffff:0x0000       ; Jump to BIOS reset vector

exit:
    cli
    hlt
    jmp $

inputBuffer: times 32 db 0

echoCmd db "echo ", 0
clearCmd db "clear", 0
helpCmd db "help", 0
shutdownCmd db "shutdown", 0
restartCmd db "restart", 0

debugEqual db "Strings match!", 0
debugNotEqual db "Strings do not match!", 0
debug db "debug", 0

errorMsg db "Command not found!", 0
helpMsg db "Commands: echo, clear, help, shutdown, restart", 0
shutdownMsg db "Shutting down...", 0
rebootMsg db "Rebooting...", 0
