; Get number of sectors from AL and drive number DL before execution
diskLoad:
    mov ah, 0x02        ; BIOS read sectors
    mov ch, 0           ; cylinder 0
    mov cl, 0x02        ; sector 2 (bootloader is sector 1)
    mov dh, 0           ; head 0

    int 0x13            ; BIOS disk read
    jc diskError        ; jump if error

    call println16
    mov si, successMsg
    call print16
    ret

diskError:
    ; print error code
    call println16
    mov al, ah          
    call printHex16
    
    mov si, errorMsg
    call print16
    jmp halt

halt:
    cli
    hlt
    jmp halt

errorMsg: db " Disk read error!", 0
successMsg: db "Success!", 0
