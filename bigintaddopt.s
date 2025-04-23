//--------------------------------------------------------------------
// bigintadd.s
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

    // if (lLength1 <= lLength2) goto else1
    ldr x0, [sp, LLENGTH1]
    ldr x1, [sp, LLENGTH2]
    cmp x0, x1
    ble else1

    // lLarger = lLength1
    str x0, [sp, LLARGER]

    // goto endif1
    b endif1

else1: 
    // lLarger = lLength2
    str x1, [sp, LLARGER]

endif1:
    // epilog and return lLarger
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
    
    // lSumLength = BigInt_larger(oAddend1->lLength, oAddend2->lLength)
    ldr x0, [sp, OADDEND1]
    ldr x0, [x0, LLENGTH]
    ldr x1, [sp, OADDEND2]
    ldr x1, [x1, LLENGTH]
    bl BigInt_larger
    str x0, [sp, LSUMLENGTH]

    // if (oSum->lLength <= lSumLength) goto endif2
    ldr x0, [sp, OSUM]
    ldr x0, [x0, LLENGTH]
    ldr x1, [sp, LSUMLENGTH]
    cmp x0, x1
    ble endif2

    // memset(oSum->aulDigits, 0, MAX_DIGITS * sizeof(unsigned long))
    ldr x0, [sp, OSUM]
    add x0, x0, LDIGITS
    mov x1, 0
    mov x4, SIZELONG
    mov x6, MAX_DIGITS
    mul x2, x6, x4
    bl memset 

endif2: 
    // ulCarry = 0
    mov x0, 0
    str x0, [sp, LINDEX]

    lIndex = 0;
    str x0, [sp, ULCARRY]

loop1: 
    // if (lIndex >= lSumLength) goto endloop1
    ldr x0, [sp, LINDEX]
    ldr x1, [sp, LSUMLENGTH]
    cmp x0, x1
    bge endloop1

    // ulSum = ulCarry
    ldr x0, [sp, ULCARRY]
    str x0, [sp, ULSUM]

    // ulCarry = 0
    mov x0, 0
    str x0, [sp, ULCARRY]

    // ulSum += oAddend1->aulDigits[lIndex]
    ldr x1, [sp, OADDEND1]
    add x1, x1, LDIGITS
    ldr x0, [sp, LINDEX]
    lsl x0, x0, 3
    ldr x2, [x1, x0]
    ldr x3, [sp, ULSUM]
    add x3, x3, x2
    str x3, [sp, ULSUM]

    // if (ulSum >= oAddend1->aulDigits[lIndex]) goto endif3
    cmp x3, x2
    bge endif3

    // ulCarry = 1
    mov x2, 1
    str x2, [sp, ULCARRY]

endif3:
    // ulSum += oAddend2->aulDigits[lIndex]
    ldr x1, [sp, OADDEND2]
    add x1, x1, LDIGITS
    ldr x0, [sp, LINDEX]
    lsl x0, x0, 3
    ldr x2, [x1, x0]
    ldr x3, [sp, ULSUM]
    add x3, x3, x2
    str x3, [sp, ULSUM]

    // if (ulSum >= oAddend2->aulDigits[lIndex]) goto endif4
    cmp x3, x2
    bge endif4

    // ulCarry = 1
    mov x2, 1
    str x2, [sp, ULCARRY]

endif4:
    // oSum->aulDigits[lIndex] = ulSum
    ldr x1, [sp, OSUM]
    add x1, x1, LDIGITS
    ldr x0, [sp, LINDEX]
    lsl x0, x0, 3
    add x2, x1, x0
    ldr x3, [sp, ULSUM]
    str x3, [x2]

    // lIndex++
    ldr x0, [sp, LINDEX]
    add x0, x0, 1
    str x0, [sp, LINDEX]
    
    // goto loop1
    b loop1

endloop1:
    // if(ulCarry != 1) goto endif5
    ldr x0, [sp, ULCARRY]
    cmp x0, 1
    bne endif5

    // if(lSumLength != MAX_DIGITS) goto endif6
    ldr x0, [sp, LSUMLENGTH]
    mov x6, MAX_DIGITS
    cmp x0, x6
    bne endif6

    // epilog and return FALSE
    mov w0, FALSE
    ldr     x30, [sp]
    add     sp, sp, ADD_STACK_BYTECOUNT 
    ret

endif6:
    // oSum->aulDigits[lSumLength] = 1
    ldr x0, [sp, OSUM]
    add x0, x0, LDIGITS
    ldr x1, [sp, LSUMLENGTH]
    lsl x1, x1, 3
    add x2, x0, x1
    mov x3, 1
    str x3, [x2]

    // lSumLength++
    ldr x0, [sp, LSUMLENGTH]
    add x0, x0, 1
    str x0, [sp, LSUMLENGTH]

endif5:
    // oSum->lLength = lSumLength
    ldr x0, [sp, OSUM]
    ldr x1, [sp, LSUMLENGTH]
    str x1, [x0]

    // epilog and return TRUE
    mov w0, TRUE
    ldr     x30, [sp]
    add     sp, sp, ADD_STACK_BYTECOUNT  
    ret
