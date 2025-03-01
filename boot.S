.global _start
.section .text
.align 4
_start:
    ldr x0, =msgBeforeRead  // Print message before reading
    bl uartPrint
    
    bl uartReadChar         // Read a character
    bl uartEchoChar         // Echo character back

    b haltCPU               // Halt execution

// ---------------- UART READ CHARACTER FUNCTION ----------------
uartReadChar:
    ldr x1, =uartFlag       // Load UART flags register address

waitLoop:
    ldr w2, [x1]            // Read UART flags register
    and w2, w2, #0x10       // Mask bit 4 (RXFE: Receive FIFO Empty)
    cbnz w2, waitLoop       // If RXFE == 1 (buffer empty), keep waiting

    ldr x1, =uartData       // Load UART data register
    ldrb w3, [x1]           // Read received character into w0

    ret

// ---------------- UART ECHO FUNCTION ----------------
uartEchoChar:
    ldr x1, =uartBase       // Load UART base address
    strb w3, [x1]           // Write received character to UART

// ---------------- UART PRINT FUNCTION ----------------
uartPrint:
    ldr x1, =uartBase
printLoop:
    ldrb w2, [x0], #1
    cbz w2, returnPrint
    strb w2, [x1]
    b printLoop
returnPrint:
    ret

// ---------------- HALT FUNCTION ----------------
haltCPU:
    wfi

// ---------------- DATA SECTION ----------------
.section .data
.algin 4
msgBeforeRead: .asciz "Enter text: \n"


.section .bss
.equ uartBase,  0x09000000   // UART data register
.equ uartFlag,  0x09000018   // UART flags register
.equ uartData,  0x09000000   // UART receive/transmit register
