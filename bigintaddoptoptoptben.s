    .equ FALSE,           0
    .equ TRUE,            1

    .equ SIZELONG,        8
    .equ MAX_DIGITS,      32768

    .equ ADD_STACK_BYTECOUNT, 72       // CHANGED: was 64, now 72 to save one more register

    ULSUM      .req x20
    LINDEX     .req x21
    LSUMLENGTH .req x22

    OADDEND1   .req x23
    OADDEND2   .req x24
    OSUM       .req x25

    CARRYFLAG  .req x26               // CHANGED: new register for saving carry-out

    .equ LLENGTH,       0
    .equ LDIGITS,       8

    .global BigInt_add

BigInt_add:
    // Prolog
    sub    sp, sp, ADD_STACK_BYTECOUNT
    str    x30, [sp]
    str    x20, [sp, 16]
    str    x21, [sp, 24]
    str    x22, [sp, 32]
    str    x23, [sp, 40]
    str    x24, [sp, 48]
    str    x25, [sp, 56]
    str    x26, [sp, 64]              // CHANGED: save CARRYFLAG

    mov    OADDEND1, x0
    mov    OADDEND2, x1
    mov    OSUM,      x2

    // get oAddend1->lLength
    add    x0, OADDEND1, LLENGTH
    ldr    x0, [x0]
    // get oAddend2->lLength
    add    x1, OADDEND2, LLENGTH
    ldr    x1, [x1]
    // lSumLength = max(x0, x1)
    cmp    x0, x1
    csel   x0, x0, x1, gt
    mov    LSUMLENGTH, x0

    // if (oSum->lLength > lSumLength) clear old digits
    ldr    x0, [OSUM, LLENGTH]
    cmp    x0, LSUMLENGTH
    ble    no_memset
    add    x0, OSUM, LDIGITS
    mov    x1, 0
    mov    x4, SIZELONG
    mov    x6, MAX_DIGITS
    mul    x2, x6, x4
    bl     memset
no_memset:

    // initialize index & carry
    mov    LINDEX, 0
    adds   xzr, xzr, xzr           // clear C flag

    // Main loop
loop1:
    // load aulDigits1[lIndex]
    add    x1, OADDEND1, LDIGITS
    lsl    x0, LINDEX, 3
    ldr    x2, [x1, x0]
    // load aulDigits2[lIndex]
    add    x1, OADDEND2, LDIGITS
    lsl    x0, LINDEX, 3
    ldr    x3, [x1, x0]

    adcs   ULSUM, x2, x3           // add with carry → updates C flag
    cset   CARRYFLAG, cs           // CHANGED: save carry-out into CARRYFLAG

    // store sum word
    add    x1, OSUM, LDIGITS
    lsl    x0, LINDEX, 3
    str    ULSUM, [x1, x0]

    // increment index & test
    add    LINDEX, LINDEX, 1
    sub    x9, LINDEX, LSUMLENGTH  // sets new flags, but we don't care now
    tbnz   x9, 63, loop1

// after loop, CARRYFLAG holds the final carry
endloop1:
    cbz    CARRYFLAG, endif5       // CHANGED: branch if no carry-out

    // we did carry-out
    mov    x6, MAX_DIGITS
    cmp    LSUMLENGTH, x6
    bne    endif6

    // overflow: lSumLength == MAX_DIGITS
    mov    w0, FALSE
    // Epilog
    ldr    x30, [sp]
    ldr    x20, [sp, 16]
    ldr    x21, [sp, 24]
    ldr    x22, [sp, 32]
    ldr    x23, [sp, 40]
    ldr    x24, [sp, 48]
    ldr    x25, [sp, 56]
    ldr    x26, [sp, 64]            // CHANGED: restore CARRYFLAG
    add    sp, sp, ADD_STACK_BYTECOUNT
    ret

endif6:
    // append the carry bit as a new digit
    add    x1, OSUM, LDIGITS
    lsl    x0, LSUMLENGTH, 3
    mov    x3, 1
    str    x3, [x1, x0]
    add    LSUMLENGTH, LSUMLENGTH, 1

endif5:
    // store final length & return TRUE
    str    LSUMLENGTH, [OSUM, LLENGTH]
    mov    w0, TRUE
    // Epilog
    ldr    x30, [sp]
    ldr    x20, [sp, 16]
    ldr    x21, [sp, 24]
    ldr    x22, [sp, 32]
    ldr    x23, [sp, 40]
    ldr    x24, [sp, 48]
    ldr    x25, [sp, 56]
    ldr    x26, [sp, 64]            // CHANGED: restore CARRYFLAG
    add    sp, sp, ADD_STACK_BYTECOUNT
    ret
