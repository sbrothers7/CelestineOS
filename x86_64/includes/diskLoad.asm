; Get number of sectors from AL and drive number DL before execution
diskLoad:
    mov ah, 0x02        ; BIOS Read Sectors
    mov ch, 0           ; Cylinder 0
    mov cl, 2           ; Sector 2 (Bootloader is sector 1)
    mov dh, 0           ; Head 0

    int 0x13            ; BIOS disk read
    jc diskError        ; If error, jump to diskError

    call println16
    mov si, successMsg
    call print16
    ret

diskError:
    call println16
    mov al, ah          ; Print BIOS error code
    call printHexLower16
    
    mov si, errorMsg
    call print16
    jmp halt

halt:
    cli
    hlt
    jmp halt

errorMsg: db " Disk read error!", 0
successMsg: db "Success!", 0