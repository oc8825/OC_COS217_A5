/* --------------------------------------------------------------------
 *  BigInt_add (oAddend1=x0, oAddend2=x1, oSum=x2)
 *  Callee-saved: x19-x25, x30
 *  Scratch:      x3-x18
 * ------------------------------------------------------------------ */

        .equ    FALSE,      0
        .equ    TRUE,       1
        .equ    MAX_DIGITS, 32768           // 0x8000

        /* structure offsets (uint64_t aulDigits[], long lLength) */
        .equ    LDIGITS,    0
        .equ    LLENGTH,    8

        .equ    ADD_STACK_BYTECOUNT,  64    // space for callee-saved regs

        .text
        .p2align 2
        .global  BigInt_add
BigInt_add:
        /* -------------------------------- prologue ---------------- */
        sub     sp,  sp,  ADD_STACK_BYTECOUNT
        stp     x20, x21, [sp, 16]
        stp     x22, x23, [sp, 32]
        stp     x24, x25, [sp, 48]
        stp     x30, x19, [sp]               // save lr + a spare

        mov     x19, x0          // OADDEND1
        mov     x20, x1          // OADDEND2
        mov     x21, x2          // OSUM

        /* ---- lSumLength = max(a1->lLength, a2->lLength) ---------- */
        ldr     x4,  [x19, LLENGTH]
        ldr     x5,  [x20, LLENGTH]
        cmp     x4,  x5
        csel    x22, x4, x5, ge          // x22 = lSumLength  (LSUMLENGTH)

        /* if (oSum->lLength > lSumLength) zero the digits             */
        ldr     x6,  [x21, LLENGTH]
        cmp     x6,  x22
        ble     memset_done
        /* memset(oSum->aulDigits, 0, MAX_DIGITS*sizeof(uint64_t))     */
        mov     x0,  x21                    // void *dst
        add     x0,  x0,  LDIGITS
        mov     w1,  #0                     // value
        mov     x2,  #(MAX_DIGITS * 8)      // byte count
        bl      memset
memset_done:

        /* ---------------- main limb-wise add loop ------------------ */
        mov     x23, #0                 // ulCarry  (x23)
        mov     x24, #0                 // lIndex   (LINDEX)

loop1:
        cmp     x24, x22                // while (lIndex < lSumLength)
        b.ge    endloop1

        /* load oAddend1->aulDigits[lIndex]  -> x2 */
        add     x1,  x19,  LDIGITS
        lsl     x0,  x24,  #3
        ldr     x2, [x1, x0]

        /* load oAddend2->aulDigits[lIndex]  -> x3 */
        add     x1,  x20,  LDIGITS
        ldr     x3, [x1, x0]

        /* ulSum = x2 + x3 + carry-in */
        adcs    x25, x2, x3             // x25 = ulSum
        cset    x23, cs                 // x23 = ulCarry (1|0)

        /* store ulSum to oSum->aulDigits[lIndex] */
        add     x1,  x21,  LDIGITS
        str     x25, [x1, x0]

        add     x24, x24, #1            // ++lIndex
        b       loop1
endloop1:

        /* ---------------- carry-out handler ------------------------ */
        cbz     x23, success            // if (!ulCarry) -> success

        /* ulCarry == 1: if (lSumLength == MAX_DIGITS) overflow */
        mov     w6, #MAX_DIGITS          // *** immediate load, no segfault **
        cmp     x22, x6
        b.ne    store_carry             // room for one more limb

overflow:
        mov     w0,  #FALSE
        b       epilog

store_carry:
        /* oSum->aulDigits[lSumLength] = 1 */
        add     x1,  x21,  LDIGITS
        lsl     x0,  x22, #3
        mov     x3,  #1
        str     x3,  [x1, x0]

        add     x22, x22, #1            // ++lSumLength

success:
        /* oSum->lLength = lSumLength */
        str     x22, [x21, LLENGTH]
        mov     w0,  #TRUE

epilog:
        ldp     x30, x19, [sp]
        ldp     x20, x21, [sp, 16]
        ldp     x22, x23, [sp, 32]
        ldp     x24, x25, [sp, 48]
        add     sp, sp,  ADD_STACK_BYTECOUNT
        ret
