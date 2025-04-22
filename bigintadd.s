//--------------------------------------------------------------------
// bigintadd.s
// Owen Clarke and Ben Zhou
//--------------------------------------------------------------------
.equ FALSE, 0
.equ TRUE, 1
.equ 0ADDEND1, 48
.equ ULCARRY, 24
.equ LLENGTH, 0
//--------------------------------------------------------------------
    .section .rodata
//--------------------------------------------------------------------
    .section .data
//--------------------------------------------------------------------
    .section .bss
//--------------------------------------------------------------------
    .section .text
.equ MAIN_STACK_BYTECOUNT, 32

.equ LLARGER, 8

.equ LLENGTH1, 16
.equ LLENGTH2, 24





BigInt_larger: 
    // Prolog
    sub sp, sp, MAIN_STACK_BYTECOUNT
    str x30, [sp]
    str x0, [sp, LLENGTH1]
    str x1, [sp, LLENGTH2]

    ldr x0, [sp, LLENGTH1]
    ldr x1, [sp, LLENGTH2]
    cmp x0, x1
    ble else1
    str x0, [sp, LLARGER]
    b endif1
else1: 
    str x1, [sp, LLARGER]
endif1: 
    ldr x0, [sp, LLARGER]
    ldr x30, [sp]
    add sp, sp, GCD_STACK_BYTECOUNT
    ret

.size   BigInt_larger, .-BigInt_larger
.global BigInt_add

.equ ADD_STACK_BYTECOUNT, 64

.equ ULCARRY, 8
.equ ULSUM, 16
.equ LINDEX, 24
.equ LSUMLENGTH, 32

.equ OADDEND1, 40
.equ OADDEND2, 48
.equ OSUM, 56

BigInt_add: 
    // Prolog
    sub sp, sp, ADD_STACK_BYTECOUNT
    str x30, [sp]
    str x0, [sp, OADDEND1]
    str x1, [sp, OADDEND2]
    str x2, [sp, OSUM]
    
    ldr x0, [sp, OADDEND1]
    ldr x0, [x0, 0]
    ldr x1, [sp, OADDEND1]
    ldr x1, [x1, 0]
    bl BigInt_larger
    str x0, [sp, LSUMLENGTH]

    ldr x0, [sp, OSUM]
    ldr x0, [x0, 0]
    ldr x1, [sp LSUMLENGTH]
    cmp x0, x1
    ble endif1
    ldr x0, [sp, OSUM]
    add x0, x0, 8
    mov x1, 0
    mov x2, (MAX_DIGITS * 8)
    bl memset 
endif1: 
    str 0, [sp, ULCARRY]
    str 0, [sp, LINDEX]
loop1: 
    ldr x0, [sp, LINDEX]
    ldr x1, [sp, LSUMLENGTH]
    cmp x0, x1
    bge endloop1
    ldr x0, [sp, ULCARRY]
    str x0, [sp, ULSUM]
    mov x0, 0
    str x0, [sp, ULCARRY]













