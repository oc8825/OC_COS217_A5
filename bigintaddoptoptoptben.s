//--------------------------------------------------------------------
// bigintadd_fixed.s
// Owen Clarke · Ben Zhou · (2025-04-23 patch by <you>)
//--------------------------------------------------------------------

        .equ FALSE,              0
        .equ TRUE,               1

        .equ SIZELONG,           8
        .equ MAX_DIGITS,     32768

//--------------------------------------------------------------------
        .section .text
        .global BigInt_add
//--------------------------------------------------------------------

/* Callee-saved scratch registers */
ULSUM       .req x20            // running “digit” sum
LINDEX      .req x21            // loop index
LSUMLENGTH  .req x22            // max(aLen,bLen) → tentative sum length

OADDEND1    .req x23            // struct * a
OADDEND2    .req x24            // struct * b
OSUM        .req x25            // struct * sum

        .equ LLENGTH,           0       // offset: unsigned long lLength
        .equ LDIGITS,           8       // offset: unsigned long aulDigits[0]

// Reserve space for lr + x20–x25 (7 × 8 = 56) → keep 16-byte alignment.
        .equ ADD_STACK_BYTECOUNT, 64

//--------------------------------------------------------------------

BigInt_add:
        //── prolog ───────────────────────────────────────────────────
        sub     sp, sp, ADD_STACK_BYTECOUNT
        stp     x30, x20, [sp]           // save lr, x20
        stp     x21, x22, [sp, 16]       // save x21–x22
        stp     x23, x24, [sp, 32]       // save x23–x24
        str     x25,       [sp, 48]      // save x25

        mov     OADDEND1, x0
        mov     OADDEND2, x1
        mov     OSUM,     x2

        //── find individual operand lengths ─────────────────────────
        ldr     x0, [OADDEND1, LLENGTH]  // aLen
        ldr     x1, [OADDEND2, LLENGTH]  // bLen

        // LSUMLENGTH = max(aLen, bLen)
        cmp     x0, x1
        csel    LSUMLENGTH, x0, x1, hi   // x0>x1 ? x0 : x1

        //── clear stale digits in oSum, *iff* its previous length was longer
        ldr     x3, [OSUM, LLENGTH]      // oldSumLen
        cmp     x3, LSUMLENGTH
        ble     1f                       // oldLen ≤ newLen ⇒ nothing to wipe

        // memset(oSum->digits, 0, MAX_DIGITS*sizeof(unsigned long));
        add     x0, OSUM, LDIGITS        // dst
        mov     x1, 0                    // value
        mov     x4, SIZELONG
        mov     x6, MAX_DIGITS
        mul     x2, x6, x4               // count
        bl      memset
1:

        //── main addition loop ──────────────────────────────────────
        mov     LINDEX, 0
        adds    xzr, xzr, xzr            // clear carry flag

loop:
        cmp     LINDEX, LSUMLENGTH
        bge     end_loop

        // ---- digit from addend 1 (x2) ----
        ldr     x3, [OADDEND1, LLENGTH]  // aLen (reload each pass)
        cmp     LINDEX, x3
        bge     2f                       // past the end → use 0
        add     x4, OADDEND1, LDIGITS
        lsl     x5, LINDEX, 3
        ldr     x2, [x4, x5]
        b       3f
2:      mov     x2, 0
3:
        // ---- digit from addend 2 (x3) ----
        ldr     x6, [OADDEND2, LLENGTH]  // bLen
        cmp     LINDEX, x6
        bge     4f
        add     x7, OADDEND2, LDIGITS
        lsl     x8, LINDEX, 3
        ldr     x3, [x7, x8]
        b       5f
4:      mov     x3, 0
5:
        // ulSum = digit1 + digit2 + carry
        adcs    ULSUM, x2, x3
        cset    x10, cs                  // remember carry-out

        // store result digit
        add     x9, OSUM, LDIGITS
        lsl     x11, LINDEX, 3
        str     ULSUM, [x9, x11]

        add     LINDEX, LINDEX, 1
        b       loop

end_loop:
        //── handle final carry ──────────────────────────────────────
        cbz     x10, 6f                  // no carry → skip

        cmp     LSUMLENGTH, MAX_DIGITS
        beq     fail_full                // overflow – not enough room

        // oSum->digits[LSUMLENGTH] = 1;
        add     x0, OSUM, LDIGITS
        lsl     x1, LSUMLENGTH, 3
        mov     x2, 1
        str     x2, [x0, x1]

        add     LSUMLENGTH, LSUMLENGTH, 1
6:
        //── write back length and return TRUE ───────────────────────
        str     LSUMLENGTH, [OSUM, LLENGTH]

success:
        mov     w0, TRUE
        b       epilog

fail_full:
        mov     w0, FALSE

epilog:
        ldp     x30, x20, [sp]
        ldp     x21, x22, [sp, 16]
        ldp     x23, x24, [sp, 32]
        ldr     x25,       [sp, 48]
        add     sp, sp, ADD_STACK_BYTECOUNT
        ret
