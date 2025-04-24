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

/*------------------------------------------------------------------*/
/*  Register map                                                    */
/*------------------------------------------------------------------*/
.equ ADD_STACK_BYTECOUNT, 80        // *** CHANGED *** 64 → 80

ULSUM        .req x20
LINDEX       .req x21
LSUMLENGTH   .req x22

OADDEND1     .req x23
OADDEND2     .req x24
OSUM         .req x25

CARRYFLAG    .req x26               // *** NEW ***  – saved copy of C flag
SAVED_X27    .req x27               // *** NEW ***  – dummy, keeps SP 16-byte aligned

LEN1         .req x14               // *** NEW ***  – oAddend1->lLength
LEN2         .req x15               // *** NEW ***  – oAddend2->lLength
LMASK        .req x12               // Scratch for “mask-or-zero” trick

.equ LLENGTH, 0
.equ LDIGITS, 8

/*------------------------------------------------------------------*/

BigInt_add:
    /*---------------- Prolog -------------------------------------*/
    sub     sp, sp, ADD_STACK_BYTECOUNT
    str     x30, [sp]
    str     x20, [sp, 16]
    str     x21, [sp, 24]
    str     x22, [sp, 32]
    str     x23, [sp, 40]
    str     x24, [sp, 48]
    str     x25, [sp, 56]
    str     x26, [sp, 64]           // *** NEW ***
    str     x27, [sp, 72]           // *** NEW ***

    mov     OADDEND1, x0
    mov     OADDEND2, x1
    mov     OSUM,     x2

    /*---------------- Find both lengths --------------------------*/
    add     x0, OADDEND1, LLENGTH
    ldr     x0, [x0]                // x0 = len1
    add     x1, OADDEND2, LLENGTH
    ldr     x1, [x1]                // x1 = len2

    mov     LEN1, x0                // *** NEW ***
    mov     LEN2, x1                // *** NEW ***

    /* lSumLength = max(len1,len2)  (unchanged code) */
    cmp     x0, x1
    ble     else1
    mov     LSUMLENGTH, x0
    b       endif1
else1:
    mov     LSUMLENGTH, x1
endif1:

    /* Clear oSum if it used to be longer (unchanged) */
    ldr     x0, [OSUM, LLENGTH]
    cmp     x0, LSUMLENGTH
    ble     endif2

    add     x0, OSUM, LDIGITS
    mov     x1, 0
    mov     x4, SIZELONG
    mov     x6, MAX_DIGITS
    mul     x2, x6, x4
    bl      memset
endif2:

    /*---------------- Addition loop ------------------------------*/
    mov     LINDEX, 0
    adds    xzr, xzr, xzr           // Clear carry before first ADCS

    /* main loop: repeat while LINDEX < lSumLength */
loop1:
    cmp     LINDEX, LSUMLENGTH
    bge     endloop1

    /* ---- load digit from addend1, or 0 if past its length ---- */
    cmp     LINDEX, LEN1            // LINDEX < LEN1 ?
    csetm   LMASK,  lt              // LMASK = −1 if true, 0 if false
    add     x1, OADDEND1, LDIGITS
    lsl     x0, LINDEX, 3
    ldr     x2, [x1, x0]
    and     x2, x2, LMASK           // zero if out-of-range

    /* ---- load digit from addend2, or 0 if past its length ---- */
    cmp     LINDEX, LEN2
    csetm   LMASK,  lt
    add     x1, OADDEND2, LDIGITS
    lsl     x0, LINDEX, 3
    ldr     x3, [x1, x0]
    and     x3, x3, LMASK

    /* ---- add with carry -------------------------------------- */
    adcs    ULSUM, x2, x3
    cset    CARRYFLAG, cs           // *** NEW *** save carry-out

    /* store result digit */
    add     x1, OSUM, LDIGITS
    lsl     x0, LINDEX, 3
    str     ULSUM, [x1, x0]

    /* ++lIndex and loop again */
    add     LINDEX, LINDEX, 1
    b       loop1

endloop1:

    /*---------------- Handle final carry ------------------------*/
    cbz     CARRYFLAG, endif5       // *** CHANGED *** test saved flag

    /* if (lSumLength == MAX_DIGITS) overflow */
    mov     x6, MAX_DIGITS
    cmp     LSUMLENGTH, x6
    bne     endif6

    /* ---- overflow return FALSE ---- */
    mov     w0, FALSE
    ldr     x30, [sp]
    ldr     x20, [sp, 16]
    ldr     x21, [sp, 24]
    ldr     x22, [sp, 32]
    ldr     x23, [sp, 40]
    ldr     x24, [sp, 48]
    ldr     x25, [sp, 56]
    ldr     x26, [sp, 64]           // *** NEW ***
    ldr     x27, [sp, 72]           // *** NEW ***
    add     sp,  sp,  ADD_STACK_BYTECOUNT
    ret

endif6:
    /* append carry digit */
    add     x1, OSUM, LDIGITS
    lsl     x0, LSUMLENGTH, 3
    mov     x3, 1
    str     x3, [x1, x0]
    add     LSUMLENGTH, LSUMLENGTH, 1

endif5:
    /* store new length */
    str     LSUMLENGTH, [OSUM, LLENGTH]

    /* ---- normal return TRUE ---- */
    mov     w0, TRUE
    ldr     x30, [sp]
    ldr     x20, [sp, 16]
    ldr     x21, [sp, 24]
    ldr     x22, [sp, 32]
    ldr     x23, [sp, 40]
    ldr     x24, [sp, 48]
    ldr     x25, [sp, 56]
    ldr     x26, [sp, 64]           // *** NEW ***
    ldr     x27, [sp, 72]           // *** NEW ***
    add     sp,  sp,  ADD_STACK_BYTECOUNT
    ret
