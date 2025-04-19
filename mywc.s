//--------------------------------------------------------------------
// mywc.s
// Owen Clarke and Ben Zhou
//--------------------------------------------------------------------

.equ FALSE, 0
.equ TRUE, 1

//--------------------------------------------------------------------

    .section .rodata

printfFormatStr:
    .string "%7ld %7ld %7ld\n"

//--------------------------------------------------------------------

    .section .data

lLineCount:
    .quad 0

lWordCount:
    .quad 0

lCharCount:
    .quad 0

iInWord:
    .int FALSE

//--------------------------------------------------------------------

    .section .bss

iChar:
    .skip 4

//--------------------------------------------------------------------

    .section .text

    .equ MAIN_STACK_BYTECOUNT, 16
    .equ EOF, -1

    .global main

main:
    // Prolog
    sub sp, sp, MAIN_STACK_BYTECOUNT
    str x30, [sp]

loop1:
    // iChar = getchar()
    bl getchar
    adr x1, iChar
    str w0, [x1]

    // if (iChar == EOF) goto endloop1
    adr x0, iChar
    ldr w1, [x0]
    cmp w1, EOF
    beq endloop1

    // lCharCount++
    adr x0, lCharCount
    ldr w1, [x0]
    add w1, w1, 1
    str w1, [x0]

    // if(!isspace(iChar)) goto else1
    adr x0, iChar
    ldr w0, [x0]
    bl isspace
    cmp w0, FALSE
    beq else1

    // if(!iInWord) goto endif1
    adr x0, iInWord
    ldr w0, [x0]
    cmp w0, FALSE
    beq endif1

    // lWordCount++
    adr x0, lWordCount
    ldr w1, [x0]
    add w1, w1, 1
    str w1, [x0]

    // iInWord = FALSE
    adr x0, iInWord
    mov w1, FALSE
    str w1, [x0]

    // goto endif1
    b endif1

else1:

endif1:

endloop1: