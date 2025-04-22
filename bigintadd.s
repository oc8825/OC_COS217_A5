//--------------------------------------------------------------------
// bigintadd.s
// Owen Clarke and Ben Zhou
//--------------------------------------------------------------------
.equ FALSE, 0
.equ TRUE, 1
.equ OADDEND1, 48
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
.equ LARGER_STACK_BYTECOUNT, 32

.equ LLARGER, 8

.equ LLENGTH1, 16
.equ LLENGTH2, 24





BigInt_larger: 
    // Prolog
    sub sp, sp, LARGER_STACK_BYTECOUNT
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
    add sp, sp, LARGER_STACK_BYTECOUNT
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
    ldr x1, [sp, OADDEND2]
    ldr x1, [x1, 0]
    bl BigInt_larger
    str x0, [sp, LSUMLENGTH]

    ldr x0, [sp, OSUM]
    ldr x0, [x0, 0]
    ldr x1, [sp, LSUMLENGTH]
    cmp x0, x1
    ble endif2
    ldr x0, [sp, OSUM]
    add x0, x0, 8
    mov x1, 0
    move x4, 8
    mul x5, MAX_DIGITS, x4
    mov x2, x5
    bl memset 
endif2: 
    mov x0, 0
    str x0, [sp, LINDEX]
    str x0, [sp, ULCARRY]
loop1: 
    ldr x0, [sp, LINDEX]
    ldr x1, [sp, LSUMLENGTH]
    cmp x0, x1
    bge endloop1
    ldr x0, [sp, ULCARRY]
    str x0, [sp, ULSUM]
    mov x0, 0
    str x0, [sp, ULCARRY]
    ldr x1, [sp, OADDEND1]
    add x1, x1, 8
    ldr x0, [sp, LINDEX]
    lsl x0, x0, 3
    ldr x2, [x1, x0]
    ldr x3, [sp, ULSUM]
    add x3, x3, x2
    str x3, [sp, ULSUM]
    cmp x3, x2
    bge endif3
    mov x2, 1
    str x2, [sp, ULCARRY]
endif3:
    ldr x1, [sp, OADDEND2]
    add x1, x1, 8
    ldr x0, [sp, LINDEX]
    lsl x0, x0, 3
    ldr x2, [x1, x0]
    ldr x3, [sp, ULSUM]
    add x3, x3, x2
    str x3, [sp, ULSUM]
    cmp x3, x2
    bge endif4
    mov x2, 1
    str x2, [sp, ULCARRY]
endif4: 
    ldr x1, [sp, OSUM]
    add x1, x1, 8
    ldr x0, [sp, LINDEX]
    lsl x0, x0, 3
    ldr x2, [x1, x0]
    ldr x3, [sp, ULSUM]
    str x3, [x2]
    ldr x0, [sp, LINDEX]
    add x0, x0, 1
    str x0, [sp, LINDEX]
    b loop1

endloop1:
    // if(ulCarry != 1) goto endif5
    adr x0, ulCarry
    ldr x0, [x0]
    cmp x0, 1
    bne endif5

    // if(lSumLength != MAX_DIGITS) goto endif6
    adr x0, lSumLength
    ldr x0, [x0]
    cmp x0, MAX_DIGITS
    bne endif6

    // return FALSE
    mov w0, FALSE
    ldr     x30, [sp]
    add     sp, sp, ADD_STACK_BYTECOUNT 
    ret

endif6:
    // oSum->aulDigits[lSumLength] = 1
    ldr x0, [sp, OSUM]
    add x0, x0, 8
    ldr x1, [sp, LSUMLENGTH]
    lsl x1, x1, 3
    add x2, x0, x1
    mov x3, 1
    str x3, [x2]

    // lSumLength++
    adr x0, lSumLength
    ldr x1, [x0]
    add x1, x1, 1
    str x1, [x0]

endif5:
    // oSum->lLength = lSumLength
    ldr x0, [sp, OSUM]
    ldr x1, [sp, LSUMLENGTH]
    str x1, [x0]

    // return TRUE
    mov w0, TRUE
    ldr     x30, [sp]
    add     sp, sp, ADD_STACK_BYTECOUNT
    
    ret

    



















