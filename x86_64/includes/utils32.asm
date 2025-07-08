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

clearScreen32:
    pusha
    cld
    mov edi, 0xb8000        ; VGA memory address
    mov eax, 0x0720         ; space (' ') with color attribute 0x07
    mov ecx, 80 * 25        ; 80x25 screen
    rep stosw               ; fill VGA memory
    popa
    ret
