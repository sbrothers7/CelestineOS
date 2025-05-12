.global _start
.section .text

_start:
    ldr x0, =msgReadChar
    bl uartPrint

    ldr x29, =stack_top   // x29 is just a temporary here
    mov sp, x29          // SP now points to a safe area
      
    bl uartReadChar
    bl uartEchoChar

    ldr x0, =msgNewline
    bl uartPrint

    ldr x0, =msgReadString
    bl uartPrint
    bl uartReadString
    
    afterInput:
        bl _start
// ---------------------- Functions ----------------------
uartPrint: // prints strings with address stored in x0
    ldr x1, =uartBase
    printLoop:
        ldrb w2, [x0], #1
        cbz w2, returnPrint
        strb w2, [x1]
        b printLoop
    returnPrint:
        ret

uartReadChar: // reads character and stores in x3
    ldr x1, =uartFlag

    waitLoop:
        ldr w2, [x1]
        and w2, w2, #0x10 // Mask bit 4 (RXFE: Receive FIFO Empty)
        cbnz w2, waitLoop // If RXFE == 1 (buffer empty), keep waiting
        
        ldr x1, =uartData
        ldrb w3, [x1] // Read received character into w3
        ret

uartEchoChar: // echoes character stored in x3
    ldr x1, =uartBase
    strb w3, [x1] // Write received character to UART
    ret

uartReadString: // stores string into inputBuffer
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
            ldr x5, =inputBuffer
            strb w3, [x5, x4] // Store character at inputBuffer[x4]

            bl uartEchoChar
            add x4, x4, #1 // Increment index
            cmp x4, #inputSize // Check if buffer is full
            b.ge endInput // If not full, continue reading
            b readCharLoop

        handleBackspace:
            cmp x4, #0 // Do nothing if at start of line
            beq readCharLoop

            sub x4, x4, #1 // Move buffer index back
            ldr x0, =msgBackspace
            bl uartPrint
            b readCharLoop

    endInput:
        ldr x5, =inputBuffer
        strb wzr, [x5, x4] 
        ldr x0, =msgNewline
        bl uartPrint
        b afterInput
        // ret

uartReadCmd:
    ldr x0, =inputBuffer
    bl uartReadString
    bl processCmd
    processCmd:
        ldr x1, =strHelp
        bl strComp
        cbnz w0, cmdHelp
        
        ldr x1, =strClear
        bl strComp
        cbnz w0, cmdClear

        ldr x1, =strEcho
        bl strComp
        cbnz w0, cmdEcho
    ret

strComp:
    // ldr x0, =inputBuffer
    ldrb w1, [x0], #1 // load byte in buffer
    ldrb w2, [x1], #1
    cmp w1, w2
    bne strNotEqual
    cbz w1, strEqual
    b strComp

    strNotEqual:
        mov w0, #0
        ret 

    strEqual:
        mov w0, #1
        ret

cmdHelp: 
cmdClear: 
cmdEcho: 
haltCPU: wfi
// --------------------- Data Section ---------------------
.section .data
.align 4
msgNewline: .asciz "\n"
msgReadChar: .asciz "Enter character: "
msgReadString: .asciz "Enter string: "
msgDebug: .asciz "debug"

msgBeforeWait: .asciz "Waiting for UART input...\n"
msgAfterWait:  .asciz "Character received!\n"
msgReceivedChar: .asciz "Processing input...\n"

msgBackspace: .asciz "\b \b"  // Moves cursor back, erases character, moves back again

strHelp: .asciz "help"
strClear: .asciz "clear"
strEcho: .asciz "echo"

.section .bss
inputBuffer: .skip 128 // reserve space
.equ inputSize, 127 // leave space for null terminator
hexBuffer: .skip 17  // 16 hex digits + null terminator

stack:      .skip 4096      // 4 KiB scratch stack
stack_top:                  // label *after* the buffer

.equ uartBase,  0x09000000   // UART data register
.equ uartFlag,  0x09000018   // UART flags register
.equ uartData,  0x09000000   // UART receive/transmit register
