checkA20:
    pushf
    push ds
    push es
    push di
    push si

    cli

    xor ax, ax ; ax = 0
    mov es, ax

    not ax ; ax = 0xFFFF
    mov ds, ax

    mov di, 0x0500
    mov si, 0x0510

    mov al, byte [es:di]
    push ax

    mov al, byte [ds:si]
    push ax

    mov byte [es:di], 0x00
    mov byte [ds:si], 0xFF

    cmp byte [es:di], 0xFF

    pop ax
    mov byte [ds:si], al

    pop ax
    mov byte [es:di], al

    mov ax, 0
    je .exit

    mov ax, 1

    .exit:
        pop si
        pop di
        pop es
        pop ds
        popf

        ret

enableA20:
	pusha
    cli

    .int15h:
        ; using BIOS

        mov ax, 0x2403              ; A20 gate support
        int 15h
        jb .error                   ; INT 15h is not supported
        cmp al, 0
        jnz .error                  ; also not supported

        mov ax, 0x2402              ; status 
        int 15h
        jb .error                   ; could not get status
        cmp al, 0
        jnz .error

        cmp al, 1
        jz .done                    ; already activated

        mov ax, 0x2401              ; activate
        int 15h
        jb .error                   ; couldn't activate gate
        cmp al, 0
        jnz .done

    .fastGate: 
        ; fast A20 Gate
        ; who uses machines before IBM PS/2 nowadays

        in al, 0x92
        test al, 2
        jnz .done

        or al, 2
        and al, 0xfe
        out 0x92, al

        call checkA20
        test ax, ax
        jnz .done
    
    .error:
        mov ah, 0x0e
        mov al, 'e'
        int 0x10

    .done:
        sti
        popa
        ret
