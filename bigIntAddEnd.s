endloop1:
    // if(ulCarry != 1) goto endif5
    adr x0, ulCarry
    ldr x0, [x0]
    cmp x0, 1
    bne endif5

    // if(lSumLength != MAX_DIGITS) goto endif6
    adr x0, lSumLength
    ldr x0, [x0]
    cmp x0, MAX_DIGITS
    bne endif6

    // return FALSE
    mov w0, FALSE
    ret

endif6:
    // oSum->aulDigits[lSumLength] = 1
    ldr x0, [sp, OSUM]
    add x0, x0, 8
    ldr x1, [sp, LSUMLENGTH]
    lsl x1, x1, 3
    add x2, x0, x1
    mov x3, 1
    str x3, [x2]

    // lSumLength++
    adr x0, lSumLength
    ldr x1, [x0]
    add x1, x1, 1
    str x1, [x0]

endif5:
    // oSum->lLength = lSumLength
    ldr x0, [sp, OSUM]
    ldr x1, [sp, LSUMLENGTH]
    str x1, [x0]

    // return TRUE
    mov w0, TRUE
    ret
