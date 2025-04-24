/* bigintadd_a64.s — AArch64 assembly for BigInt_add()
 * Mirrors the given professor’s C implementation exactly,
 * using the same labels / flow as your original ASM.
 */

        .text
        .p2align 2
        .global BigInt_add
BigInt_add:
        // Prologue: save callee-saved regs and lr
        sub     sp, sp, #64
        stp     x30, x19, [sp, #0]
        stp     x20, x21, [sp, #16]
        stp     x22, x23, [sp, #32]

        // x0=oAddend1, x1=oAddend2, x2=oSum
        mov     x19, x0         // save oAddend1
        mov     x20, x1         // save oAddend2
        mov     x21, x2         // save oSum

        // Constants / struct offsets
        .equ    MAX_DIGITS, 32768
        .equ    LLENGTH,    0       // offset of lLength in BigInt
        .equ    LDIGITS,    8       // offset of aulDigits[] in BigInt

        // 1) Determine lSumLength = max(oAddend1->lLength, oAddend2->lLength)
        ldr     x4,  [x19, #LLENGTH]
        ldr     x5,  [x20, #LLENGTH]
        cmp     x4,  x5
        csel    x22, x4, x5, ge     // x22 ← lSumLength

        // 2) Clear oSum’s digits if needed
        ldr     x6,  [x21, #LLENGTH]
        cmp     x6,  x22
        ble     .Lmemset_done
        // memset(oSum->aulDigits, 0, MAX_DIGITS * 8);
        mov     x0,  x21
        add     x0,  x0,  #LDIGITS
        mov     w1,  #0
        // bytes = MAX_DIGITS*8 = 32768*8 = 262144 = 0x4_0000
        movz    x2,  #0x4, lsl #16
        bl      memset
.Lmemset_done:

        // 3) Main add loop: ulCarry=0, for lIndex=0..lSumLength-1
        mov     x10, #0         // x10 ⇐ ulCarry
        mov     x23, #0         // x23 ⇐ lIndex

.Lloop1:
        cmp     x23, x22        // if lIndex >= lSumLength, break
        b.ge    .Lendloop1

        // load oAddend1->aulDigits[lIndex] → x2
        add     x1,  x19, #LDIGITS
        lsl     x0,  x23, #3
        ldr     x2, [x1, x0]

        // load oAddend2->aulDigits[lIndex] → x3
        add     x1,  x20, #LDIGITS
        ldr     x3, [x1, x0]

        // sum: x4 = x2 + x3 + carry-in
        adcs    x4,  x2, x3
        cset    x10, cs          // x10 = new carry

        // store x4 into oSum->aulDigits[lIndex]
        add     x1,  x21, #LDIGITS
        str     x4,  [x1, x0]

        // lIndex++
        add     x23, x23, #1
        b       .Lloop1
.Lendloop1:

        // 4) Handle final carry-out
        cbz     x10, .Lno_carry  // if (ulCarry==0) skip carry-handler

        // if (lSumLength == MAX_DIGITS) return FALSE
        mov     w6, #MAX_DIGITS
        cmp     x22, x6
        b.ne    .Lstore_carry

        // overflow case:
        mov     w0, #0          // FALSE
        b       .Lepilog

.Lstore_carry:
        // oSum->aulDigits[lSumLength] = 1
        add     x1,  x21, #LDIGITS
        lsl     x0,  x22, #3
        mov     x4,  #1
        str     x4,  [x1, x0]

        // bump lSumLength
        add     x22, x22, #1

.Lno_carry:
        // 5) Write back oSum->lLength = lSumLength, return TRUE
        str     x22, [x21, #LLENGTH]
        mov     w0,  #1          // TRUE

.Lepilog:
        // restore callee-saved regs and return
        ldp     x22, x23, [sp, #32]
        ldp     x20, x21, [sp, #16]
        ldp     x30, x19, [sp, #0]
        add     sp, sp, #64
        ret


