/* --------------------------------------------------------------------
 *  BigInt_add (oAddend1=x0, oAddend2=x1, oSum=x2)
 *  Callee-saved: x19-x25, x30
 *  Scratch:      x3-x18
 * ------------------------------------------------------------------ */

        .equ    FALSE,      0
        .equ    TRUE,       1
        .equ    MAX_DIGITS, 32768           // 0x8000

        /* struct BigInt { long lLength; uint64_t aulDigits[] } */
        .equ    LLENGTH,    0               // lLength at offset 0
        .equ    LDIGITS,    8               // aulDigits[] at offset 8

        .equ    ADD_STACK_BYTECOUNT,  64    // space for callee-saved regs

        .text
        .p2align 2
        .global  BigInt_add
BigInt_add:
        /* ------------------------ prologue ------------------------ */
        sub     sp,   sp,  ADD_STACK_BYTECOUNT
        stp     x30,  x19, [sp]            // save lr + x19
        stp     x20,  x21, [sp, #16]
        stp     x22,  x23, [sp, #32]
        stp     x24,  x25, [sp, #48]

        mov     x19, x0      // OADDEND1
        mov     x20, x1      // OADDEND2
        mov     x21, x2      // OSUM

        /* lSumLength = max(oAddend1->lLength, oAddend2->lLength) */
        ldr     x4,  [x19, #LLENGTH]
        ldr     x5,  [x20, #LLENGTH]
        cmp     x4,  x5
        csel    x22, x4, x5, ge     // x22 = lSumLength

        /* if (oSum->lLength <= lSumLength) skip zeroing */
        ldr     x6,  [x21, #LLENGTH]
        cmp     x6,  x22
        ble     .memset_done
        /* memset(oSum->aulDigits,0,MAX_DIGITS*8) */
        mov     x0,  x21
        add     x0,  x0,  #LDIGITS
        mov     w1,  #0
        mov     x2,  #(MAX_DIGITS * 8)
        bl      memset
.memset_done:

        /* ------------------ limb-by-limb add loop ------------------ */
        mov     x23, #0     // ulCarry
        mov     x24, #0     // lIndex

.loop1:
        cmp     x24, x22
        b.ge    .endloop1

        /* load limb1 into x2 */
        add     x1, x19, #LDIGITS
        lsl     x0, x24, #3
        ldr     x2, [x1, x0]

        /* load limb2 into x3 */
        add     x1, x20, #LDIGITS
        ldr     x3, [x1, x0]

        /* add with carry: x25 = x2 + x3 + C_in */
        adcs    x25, x2, x3
        cset    x23, cs       // x23 = new ulCarry

        /* store result */
        add     x1, x21, #LDIGITS
        str     x25, [x1, x0]

        add     x24, x24, #1  // ++lIndex
        b       .loop1
.endloop1:

        /* --------- handle final carry --------- */
        cbz     x23, .success    // if no carry → success

        /* carry == 1: only overflow if at max length */
        mov     w6, #MAX_DIGITS    // immediate 32768
        cmp     x22, x6
        b.ne    .store_carry      // if room, go store

        /* overflow: return FALSE */
.overflow:
        mov     w0, #FALSE
        b      .epilog

        /* store the “1” limb and bump length */
.store_carry:
        add     x1, x21, #LDIGITS
        lsl     x0, x22, #3
        mov     x3, #1
        str     x3, [x1, x0]
        add     x22, x22, #1

        /* fall through to success */

.success:
        /* write back lLength and return TRUE */
        str     x22, [x21, #LLENGTH]
        mov     w0, #TRUE

.epilog:
        /* restore and return */
        ldp     x30, x19, [sp]
        ldp     x20, x21, [sp, #16]
        ldp     x22, x23, [sp, #32]
        ldp     x24, x25, [sp, #48]
        add     sp,  sp,  ADD_STACK_BYTECOUNT
        ret

