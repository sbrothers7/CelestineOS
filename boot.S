.global _start
.section .text
.align 4
_start:
    ldr x0, =msgReadChar
    bl uartPrint
    bl uartReadChar
    bl uartEchoChar

    ldr x0, =msgNewline
    bl uartPrint

    ldr x0, =msgReadString
    bl uartPrint
    bl uartReadString

    b haltCPU

// ---------------------- Functions ----------------------
uartReadString:
    mov x4, #0 // Index = 0
    readCharLoop:
        bl uartReadChar

        cmp w3, #13 // Check for carriage return (ASCII 13)
        beq endInput
        cmp w3, #10 // Also check for enter key (ASCII 10)
        beq endInput

        cmp w3, #8 // Handle backspace
        beq handleBackspace
        cmp w3, #127 // Handle delete
        beq handleBackspace

        storeChar:
            ldr x0, =strInputBuffer
            strb w3, [x0, x4] // Store character at buffer[x1]

            bl uartEchoChar
            add x4, x4, #1 // Increment index
            cmp x4, #strInputSize // Check if buffer is full
            b.lt readCharLoop // If not full, continue reading

        handleBackspace:
            cmp x4, #0 // Do nothing if at start of line
            beq readCharLoop

            sub x4, x4, #1 // Move buffer index back
            ldr x0, =msgBackspace // Print backspace
            bl uartPrint
            b readCharLoop

    endInput:
        mov w3, #0
        strb w3, [x0, x1] // Store null terminator at buffer[x1]
        ret

uartReadChar:
    ldr x1, =uartFlag
    waitLoop:
        ldr w2, [x1]
        and w2, w2, #0x10 // Mask bit 4 (RXFE: Receive FIFO Empty)
        cbnz w2, waitLoop // If RXFE == 1 (buffer empty), keep waiting

        ldr x1, =uartData
        ldrb w3, [x1] // Read received character into w3
        ret

uartEchoChar:
    ldr x1, =uartBase
    strb w3, [x1] // Write received character to UART
    ret

uartPrint:
    ldr x1, =uartBase
    printLoop:
        ldrb w2, [x0], #1
        cbz w2, returnPrint
        strb w2, [x1]
        b printLoop
    returnPrint:
        ret

haltCPU: wfi

// --------------------- Data Section ---------------------
.section .data
.align 4
msgNewline: .asciz "\n\0"
msgReadChar: .asciz "Enter character: \0"
msgReadString: .asciz "Enter string: \0"

msgBackspace: .asciz "\b \b"  // Moves cursor back, erases character, moves back again

.section .bss
strInputBuffer: .skip 16 // reserve space
.equ strInputSize, 15 // leave space for null terminator

.equ uartBase,  0x09000000   // UART data register
.equ uartFlag,  0x09000018   // UART flags register
.equ uartData,  0x09000000   // UART receive/transmit register
