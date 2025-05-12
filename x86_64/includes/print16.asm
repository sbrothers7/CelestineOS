; prints characters from memory address at SI using BIOS
print16:
    mov ah, 0x0e            ; BIOS teletype function (prints a character)
    .loop:
        lodsb               ; load next character from SI into AL
        cmp al, 0           ; check for null char
        je .done
        int 0x10            ; call BIOS interrupt to print AL
        jmp .loop
    .done:
        ret

println16:
    mov ah, 0x0e
    mov al, 13              ; carriage Return '\r'
    int 0x10
    mov al, 10              ; line Feed '\n'
    int 0x10
    ret

; put values into AX before printing
printHex16:
    pusha
    
    ; print prefix
    mov al, '0'
    int 0x10
    mov al, 'x'
    int 0x10

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

        mov si, hexBuffer
        call print16        ; print formatted hex string

        popa
        ret

hexBuffer: db "0000", 0
