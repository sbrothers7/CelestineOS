; 32-bit GDT
gdt32_start:  dq 0
    dq 0x00CF9A000000FFFF  ; flat code
    dq 0x00CF92000000FFFF  ; flat data
gdt32_end:
gdt32_descriptor:
    dw gdt32_end - gdt32_start - 1
    dd gdt32_start

; 64‑bit GDT: same descriptors, but with long mode flags
gdt64_start:  
    dq 0
    dq 0x00AF9A000000FFFF  ; long code
    dq 0x00AF92000000FFFF  ; long data
gdt64_end:
gdt64_descriptor:
    dw gdt64_end - gdt64_start - 1
    dd gdt64_start

; (identity‑mapped 2 MiB pages go here)
; pml4_table, pdpt_table, pd_table …

CODE32_SEL equ 0x08
DATA32_SEL equ 0x10
CODE64_SEL equ 0x08        ; first non‑null in 64‑bit GDT
