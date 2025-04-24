        .text
        .p2align 2
        .global BigInt_add

/* --------------------------------------------------------------------
 *  BigInt_add (oAddend1=x0, oAddend2=x1, oSum=x2)
 *  returns w0 = TRUE(1) on success, FALSE(0) on overflow
 *  Callee-saved: x19–x23, x30
 * ------------------------------------------------------------------ */

        .equ    MAX_DIGITS, 32768
        .equ    LLENGTH,    0      //    long lLength at offset 0
        .equ    LDIGITS,    8      // uint64_t aulDigits[] at offset 8
        .equ    STACKSZ,    64

BigInt_add:
        // ---- prologue ----
        sub     sp, sp, #STACKSZ
        stp     x30, x19, [sp]         // save lr + x19
        stp     x20, x21, [sp, #16]
        stp     x22, x23, [sp, #32]

        mov     x19, x0                // oAddend1
        mov     x20, x1                // oAddend2
        mov     x21, x2                // oSum

        // ---- compute lSumLength = max(o1->lLength, o2->lLength) ----
        ldr     x4, [x19, #LLENGTH]
        ldr     x5, [x20, #LLENGTH]
        cmp     x4, x5
        csel    x22, x4, x5, ge        // x22 ← lSumLength

        // ---- if (oSum->lLength > lSumLength) zero its digits ----
        ldr     x6, [x21, #LLENGTH]
        cmp     x6, x22
        ble     .Lskip_memset
        mov     x0, x21
        add     x0, x0, #LDIGITS
        mov     w1, #0
        // byte-count = MAX_DIGITS*8 = 32768*8 = 262144 = 0x4_0000
        mov     x2, #0x4, lsl #16
        bl      memset
.Lskip_memset:

        // ---- main add loop ----
        mov     x23, #0                // ulCarry = 0
        mov     x24, #0                // lIndex  = 0

.Lloop1:
        cmp     x24, x22
        b.ge    .Lendloop1

        // load limb from oAddend1
        add     x1, x19, #LDIGITS
        lsl     x0, x24, #3
        ldr     x2, [x1, x0]

        // load limb from oAddend2
        add     x1, x20, #LDIGITS
        ldr     x3, [x1, x0]

        // x25 = x2 + x3 + carry-in, set NZCV
        adcs    x25, x2, x3
        cset    x23, cs                // ulCarry = carry-out

        // store sum limb
        add     x1, x21, #LDIGITS
        str     x25, [x1, x0]

        add     x24, x24, #1           // ++lIndex
        b       .Lloop1
.Lendloop1:

        // ---- handle final carry ----
        cbz     x23, .Lsuccess         // if no carry → success

        // now carry==1 → only overflow if lSumLength > MAX_DIGITS
        // compare x22 vs. 32768 in one instruction:
        cmp     x22, #8, lsl #12       // 8<<12 == 32768
        b.hi    .Loverflow             // hi = unsigned > (i.e. x22 > MAX_DIGITS)

        // else (x22 ≤ MAX_DIGITS): store the extra “1” digit
        add     x1, x21, #LDIGITS
        lsl     x0, x22, #3
        mov     x3, #1
        str     x3, [x1, x0]
        add     x22, x22, #1           // ++lSumLength
        b       .Lsuccess

.Loverflow:
        mov     w0, #0                 // FALSE
        b       .Lepilog

.Lsuccess:
        // write back length and return TRUE
        str     x22, [x21, #LLENGTH]
        mov     w0, #1

.Lepilog:
        // ---- restore & return ----
        ldp     x22, x23, [sp, #32]
        ldp     x20, x21, [sp, #16]
        ldp     x30, x19, [sp]
        add     sp, sp, #STACKSZ
        ret
