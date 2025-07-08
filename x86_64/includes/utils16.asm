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
    
    mov ah, 0x0e

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

; Get number of sectors from AL and drive number DL before execution
diskLoad:
    mov ah, 0x02        ; BIOS read sectors
    mov ch, 0           ; cylinder 0
    mov cl, 0x02        ; sector 2 (bootloader is sector 1)
    mov dh, 0           ; head 0

    int 0x13            ; BIOS disk read
    jc diskError        ; jump if error

    call println16
    mov si, diskSuccessMsg
    call print16
    ret

diskError:
    ; print error code
    call println16
    mov al, ah          
    call printHex16
    
    mov si, diskErrorMsg
    call print16
    jmp halt

halt:
    cli
    hlt
    jmp halt


diskErrorMsg: db " Disk read error!", 0
diskSuccessMsg: db "Success!", 0
hexBuffer: db "0000", 0
