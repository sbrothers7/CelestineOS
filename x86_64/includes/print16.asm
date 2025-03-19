print16:
    mov ah, 0x0e    ; BIOS teletype function (prints a character)
    .loop:
        lodsb           ; load next character from SI into AL
        cmp al, 0       ; check for null char
        je .done
        int 0x10        ; call BIOS interrupt to print AL
        jmp .loop
    .done:
        ret

println16:
    mov ah, 0x0e
    mov al, 13      ; carriage Return '\r'
    int 0x10
    mov al, 10      ; line Feed '\n'
    int 0x10
    ret

printHexLower16:
    pusha
    mov cx, 2               ; DL is one byte (two hex digits)
    mov bx, hexBufferLower  ; store hex characters

    .hexLoop:
        rol dl, 4           ; rotate left to extract the high nibble
        mov al, dl
        and al, 0x0F        ; mask lower nibble
        add al, '0'         ; convert to ASCII

        cmp al, '9'         ; if A-F, adjust ASCII conversion
        jle .store
        add al, 7

    .store:
        mov [bx], al
        inc bx
        loop .hexLoop

        mov byte [bx], 0    ; null terminate
        mov si, hexBufferLower
        call print16    ; print the formatted hex string

        popa
        ret

; put values into AX before printing
printHex16:
    pusha
    mov cx, 4               ; 4 hex digits (16-bit value)
    mov bx, hexBuffer       ; store hex characters

    .hexLoop:
        rol si, 4           ; rotate left to extract the high nibble
        mov ax, si          ; copy SI to AX
        shr ax, 8           ; shift right to move high byte into AL
        mov al, ah
        and al, 0x0f        ; mask lower nibble
        add al, '0'         ; convert to ASCII

        cmp al, '9'         ; if A-F, adjust ASCII conversion
        jle .store
        add al, 7

    .store:
        mov [bx], al
        inc bx
        loop .hexLoop

        mov byte [bx], 0    ; null terminate
        mov si, hexBuffer
        call print16    ; print formatted hex string

        popa
        ret

hexBufferLower: db "00", 0
hexBuffer: db "0000", 0