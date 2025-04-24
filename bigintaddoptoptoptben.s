//--------------------------------------------------------------------
// bigintaddoptopt.s
// Owen Clarke and Ben Zhou
//--------------------------------------------------------------------

.equ FALSE, 0
.equ TRUE, 1

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

ULSUM .req x20
LINDEX .req x21
LSUMLENGTH .req x22

OADDEND1 .req x23
OADDEND2 .req x24
OSUM .req x25

.equ LLENGTH, 0
.equ LDIGITS, 8

BigInt_add: 
    // Prolog
    sub sp, sp, ADD_STACK_BYTECOUNT
    str x30, [sp]
    str x20, [sp, 16]
    str x21, [sp, 24]
    str x22, [sp, 32]
    str x23, [sp, 40]
    str x24, [sp, 48]
    str x25, [sp, 56]
    mov OADDEND1, x0
    mov OADDEND2, x1
    mov OSUM, x2
    
    // Inline larger function
    // get oAddend1's length in x0
    add x0, OADDEND1, LLENGTH
    ldr x0, [x0]
    // get oAddend2's length in x1
    add x1, OADDEND2, LLENGTH
    ldr x1, [x1]
    // branch to else1 if oAddend1's length is less than or equal
    // to oAddend2's length
    cmp x0, x1
    ble else1
    // set lSumLength to oAddend1's length
    mov LSUMLENGTH, x0
    b endif1

else1:
    // set lSumLength to oAddend2's length
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

    // if (lIndex >= lSumLength) goto endloop1
    cmp LINDEX, LSUMLENGTH
    bge endloop1

    // Clear carry
    adds xzr, xzr, xzr

loop1: 
    // store oAddend1->aulDigits[lIndex] at x2
    add x1, OADDEND1, LDIGITS
    lsl x0, LINDEX, 3
    ldr x2, [x1, x0]

    // store oAddend2->aulDigits[lIndex] at x3
    add x1, OADDEND2, LDIGITS
    lsl x0, LINDEX, 3
    ldr x3, [x1, x0]

    // add oAddend1->aulDigits[lIndex] and oAddend2->aulDigits[lIndex]
    // to ulSum, along with carry
    adcs ULSUM, x2, x3

    // store if there was a carry in x10
    cset x10, cs

    // oSum->aulDigits[lIndex] = ulSum
    add x1, OSUM, LDIGITS
    lsl x0, LINDEX, 3
    str ULSUM, [x1, x0]

    // lIndex++
    add LINDEX, LINDEX, 1

    // x9 = LINDEX - LSUMLENGTH
    sub x9, LINDEX, LSUMLENGTH

    // branch back to loop1 if negative (lIndex < lSumLength) by
    // checking the sign bit
    tbnz x9, 63, loop1

endloop1:
    // branch if didn't carry, info for this stored in x10
    cbz x10, endif5

    // if(lSumLength != MAX_DIGITS) goto endif6
    ldr x6, MAX_DIGITS
    cmp LSUMLENGTH, x6
    b.ne endif6

    // epilog and return
    mov w0, FALSE
    ldr x30, [sp]
    ldr x20, [sp, 16]
    ldr x21, [sp, 24]
    ldr x22, [sp, 32]
    ldr x23, [sp, 40]
    ldr x24, [sp, 48]
    ldr x25, [sp, 56]
    add sp, sp, ADD_STACK_BYTECOUNT 
    ret

endif6:
    // oSum->aulDigits[lSumLength] = 1
    add x1, OSUM, LDIGITS
    lsl x0, LSUMLENGTH, 3
    str xzr, [x1, x0]
    mov x3, 1
    str x3, [x1, x0]

    // lSumLength++
    add LSUMLENGTH, LSUMLENGTH, 1

endif5:
    // oSum->lLength = lSumLength
    str LSUMLENGTH, [OSUM, LLENGTH]

    // epilog and return TRUE
    mov w0, TRUE
    ldr x30, [sp]
    ldr x20, [sp, 16]
    ldr x21, [sp, 24]
    ldr x22, [sp, 32]
    ldr x23, [sp, 40]
    ldr x24, [sp, 48]
    ldr x25, [sp, 56]
    add sp, sp, ADD_STACK_BYTECOUNT  
    ret
