checkA20:
    cli
    xor ax, ax
    mov es, ax
    mov di, 0x0500
    mov al, [es:di]             ; store original value 
    push ax                     ; save to stack

    mov byte [es:di], 0x00      ; write 0x00 to 0x0500

    mov ax, 0x1000
    mov es, ax
    mov byte [es:di], 0xff      ; write 0xff to 0x10500

    xor ax, ax
    mov es, ax
    cmp byte [es:di], 0xff      ; check value at 0x0500 again
    pop ax
    mov [es:di], al             ; restore value
    je a20Enabled               ; jump if memory did not wrap
    
    mov al, 0
    ret

    a20Enabled:
        mov al, 1
        ret
