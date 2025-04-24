        .text
        .p2align    2
        .global     BigInt_add

/* Constants and struct offsets */
        .equ    MAX_DIGITS, 32768        // from bigintprivate.h
        .equ    LLENGTH,    0            // offset of lLength
        .equ    LDIGITS,    8            // offset of aulDigits[]
        .equ    STACKSZ,    64

BigInt_add:
        // — Prologue: save callee-saved regs + LR —
        sub     sp, sp, #STACKSZ
        stp     x30, x19, [sp, #0]
        stp     x20, x21, [sp, #16]
        stp     x22, x23, [sp, #32]

        // x0 = oAddend1, x1 = oAddend2, x2 = oSum
        mov     x19, x0       // oAddend1
        mov     x20, x1       // oAddend2
        mov     x21, x2       // oSum

        // 1) lSumLength = max(o1->lLength, o2->lLength)
        ldr     x4,  [x19, #LLENGTH]
        ldr     x5,  [x20, #LLENGTH]
        cmp     x4,  x5
        csel    x22, x4, x5, ge    // x22 ← lSumLength

        // 2) if (oSum->lLength > lSumLength) zero its digits
        ldr     x6,  [x21, #LLENGTH]
        cmp     x6,  x22
        ble     skip_memset
        mov     x0,  x21
        add     x0,  x0,  #LDIGITS
        mov     w1,  #0
        // byte count = MAX_DIGITS*8 = 32768*8 = 0x4_0000
        movz    x2,  #0x4, lsl #16
        bl      memset
skip_memset:

        // 3) Main add loop: ulCarry=0; for lIndex=0..lSumLength-1
        mov     x23, #0       // ulCarry
        mov     x24, #0       // lIndex

loop1:
        cmp     x24, x22
        b.ge    endloop1

        // load oAddend1->aulDigits[lIndex] → x2
        add     x1, x19, #LDIGITS
        lsl     x0, x24, #3
        ldr     x2, [x1, x0]

        // load oAddend2->aulDigits[lIndex] → x3
        add     x1, x20, #LDIGITS
        ldr     x3, [x1, x0]

        // x25 = x2 + x3 + carry-in; flags updated
        adcs    x25, x2, x3
        cset    x23, cs      // ulCarry = carry-out

        // store sum limb
        add     x1, x21, #LDIGITS
        str     x25, [x1, x0]

        add     x24, x24, #1
        b       loop1
endloop1:

        // 4) Handle final carry
        cbz     x23, success    // if ulCarry==0 → success

        // if lSumLength == MAX_DIGITS → overflow
        movz    w6, #0x8000     // 32768 in w6
        cmp     x22, x6, lsl #0 // explicit compare reg-reg
        b.ne    store_carry

overflow:
        mov     w0, #0         // FALSE
        b       epilog

store_carry:
        // carry==1 && lSumLength < MAX_DIGITS
        add     x1, x21, #LDIGITS
        lsl     x0, x22, #3
        mov     x3, #1
        str     x3, [x1, x0]
        add     x22, x22, #1   // ++lSumLength
        b       success

success:
        // oSum->lLength = lSumLength; return TRUE
        str     x22, [x21, #LLENGTH]
        mov     w0, #1

epilog:
        // — restore callee-saved regs + LR & return —
        ldp     x22, x23, [sp, #32]
        ldp     x20, x21, [sp, #16]
        ldp     x30, x19, [sp, #0]
        add     sp, sp, #STACKSZ
        ret


