[org 0x7c00] ; offset origin for display
mov bp, 0x8000 ; offset so that base stack is away from BIOS
mov sp, bp

mov bx, hello ; set bx to address of hello
mov dx, 1 ; set dx to 1
call print

mov bx, newline ; print just a newline
call print

; mov cx, 0x1fb6
; call print_hex

mov bx, goodbye

print: ; Uses bx and dx as parameters. If dx is 1, a newline will be printed.
    pusha
    mov ah, 0x0e ; tele-type mode
    .print_char:
        mov al, [bx] ; set al to value at bx
        int 0x10 ; print character
        add bx, 1 ; next character
        cmp al, 0 ; if at end of string
        je .check_newline ; return
        jmp .print_char ; loop
    .check_newline:
        cmp dx, 1 ; if dx is not equal to 1
        jne .end ; jump to end
        ; else 
        mov al, 0xa ; newline
        int 0x10
        mov al, 0xd ; carriage return
        int 0x10
        jmp .end
    .end:
        popa
        ret ; return

print_hex: ; allows printing as hex, gets hexadecimal from cx
    
    mov bx, hex_output
    call print


; data
hello:
    db "Hello World!", 0 ; null termination for strings

goodbye:
    db "Goodbye!", 0

newline:
    db 0

hex_output:
    db "0x0000", 0

jmp $ ; hang

; boot
times 510 - ($ - $$) db 0
dw 0xaa55