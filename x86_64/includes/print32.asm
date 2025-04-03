print32:
    pusha
    mov edi, 0xb8000        ; VGA memory address

    .loop:
        lodsb               ; load next character from [esi] into AL
        movzx eax, al       ; Zero-extend AL for correct null check
        cmp eax, 0
        je .done
        mov ah, 0x07        ; attribute (white text on black background)
        stosw               ; store character + attribute in VGA memory
        jmp .loop

    .done:
        popa
        ret