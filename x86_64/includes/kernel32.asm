clearScreen32:
    mov edi, 0xb8000        ; VGA memory address
    mov eax, 0x07200720     ; space (' ') with color attribute 0x07
    mov ecx, 2000           ; 80x25 screen (2000 characters)
    rep stosd               ; fill VGA memory
    ret