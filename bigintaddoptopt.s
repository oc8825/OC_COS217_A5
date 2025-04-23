//--------------------------------------------------------------------
// bigintaddoptopt.s
// Owen Clarke and Ben Zhou
//--------------------------------------------------------------------

.equ FALSE, 0
.equ TRUE, 1
.equ OADDEND1, 48
.equ ULCARRY, 24
.equ LLENGTH, 0
.equ LDIGITS, 8
.equ SIZELONG, 8
.equ MAX_DIGITS, 32768

//--------------------------------------------------------------------

    .section .rodata

//--------------------------------------------------------------------

    .section .data

//--------------------------------------------------------------------
    
    .section .bss

//--------------------------------------------------------------------
    
    .section .text

.global BigInt_add

.equ ADD_STACK_BYTECOUNT, 64

ULCARRY .req x19
ULSUM .req x20
LINDEX .req x21
LSUMLENGTH .req x22

OADDEND1 .req x23
OADDEND2 .req x24
OSUM .req x25

BigInt_add: 
    // Prolog
    sub sp, sp, ADD_STACK_BYTECOUNT
    str x30, [sp]
    str x19, [sp, 8]
    str x20, [sp, 16]
    str x21, [sp, 24]
    str x22, [sp, 32]
    str x23, [sp, 40]
    str x24, [sp, 48]
    str x25, [sp, 56]
    mov OADDEND1, x0
    mov OADDEND2, x1
    mov OSUM, x2
    
    // lSumLength = BigInt_larger(oAddend1->lLength, oAddend2->lLength)
    add x0, OADDEND1, LLENGTH
    ldr x0, [x0]
    add x1, OADDEND2, LLENGTH
    ldr x1, [x1]
    cmp x0, x1
    ble else1
    mov LSUMLENGTH, x0
    b endif1

else1:
    mov LSUMLENGTH, x1

endif1:
    // if (oSum->lLength <= lSumLength) goto endif2
    ldr x0, [OSUM, LLENGTH]
    cmp x0, LSUMLENGTH
    ble endif2

    // memset(oSum->aulDigits, 0, MAX_DIGITS * sizeof(unsigned long))
    add x0, OSUM, LDIGITS
    mov x1, 0
    mov x4, SIZELONG
    mov x6, MAX_DIGITS
    mul x2, x6, x4
    bl memset

endif2: 
    // lIndex = 0
    mov LINDEX, 0

    // ulCarry = 0
    mov ULCARRY, 0

    // if (lIndex >= lSumLength) goto endloop1
    cmp LINDEX, LSUMLENGTH
    bge endloop1

loop1: 
    // ulSum = ulCarry
    mov ULSUM, ULCARRY

    // ulCarry = 0
    mov ULCARRY, 0

    // ulSum += oAddend1->aulDigits[lIndex]
    add x1, OADDEND1, LDIGITS
    lsl x0, LINDEX, 3
    ldr x2, [x1, x0]
    add ULSUM, ULSUM, x2

    // if (ulSum >= oAddend1->aulDigits[lIndex]) goto endif3
    cmp ULSUM, x2
    bge endif3

    // ulCarry = 1
    mov ULCARRY, 1

endif3:
    // ulSum += oAddend2->aulDigits[lIndex]
    add x1, OADDEND2, LDIGITS
    lsl x0, LINDEX, 3
    ldr x2, [x1, x0]
    add ULSUM, ULSUM, x2

    // if (ulSum >= oAddend2->aulDigits[lIndex]) goto endif4
    cmp ULSUM, x2
    bge endif4

    // ulCarry = 1
    mov ULCARRY, 1

endif4:
    // oSum->aulDigits[lIndex] = ulSum
    add x1, OSUM, LDIGITS
    lsl x0, LINDEX, 3
    str ULSUM, [x1, x0]

    // lIndex++
    add LINDEX, LINDEX, 1
    
    // if (lIndex < lSumLength) goto loop1
    cmp LINDEX, LSUMLENGTH
    blt loop1

endloop1:
    // if(ulCarry != 1) goto endif5
    cmp ULCARRY, 1
    bne endif5

    // if(lSumLength != MAX_DIGITS) goto endif6
    mov x6, MAX_DIGITS
    cmp LSUMLENGTH, x6
    bne endif6

    // epilog and return FALSE
    mov w0, FALSE
    ldr     x30, [sp]
    ldr x19, [sp, 8]
    ldr x20, [sp, 16]
    ldr x21, [sp, 24]
    ldr x22, [sp, 32]
    ldr x23, [sp, 40]
    ldr x24, [sp, 48]
    ldr x25, [sp, 56]
    add     sp, sp, ADD_STACK_BYTECOUNT 
    ret

endif6:
    // oSum->aulDigits[lSumLength] = 1
    add x1, OSUM, LDIGITS
    lsl x0, LSUMLENGTH, 3
    mov x3, 1
    str x3, [x1, x0]

    // lSumLength++
    add LSUMLENGTH, LSUMLENGTH, 1

endif5:
    // oSum->lLength = lSumLength
    str LSUMLENGTH, [OSUM, LLENGTH]

    // epilog and return TRUE
    mov w0, TRUE
    ldr     x30, [sp]
    ldr x19, [sp, 8]
    ldr x20, [sp, 16]
    ldr x21, [sp, 24]
    ldr x22, [sp, 32]
    ldr x23, [sp, 40]
    ldr x24, [sp, 48]
    ldr x25, [sp, 56]
    add     sp, sp, ADD_STACK_BYTECOUNT  
    ret
