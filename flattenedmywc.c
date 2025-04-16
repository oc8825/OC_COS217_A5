/* flattenedmywc.c */

#include <stdio.h>
#include <ctype.h>

/* In lieu of a boolean data type. */
enum
{
    FALSE,
    TRUE
};

static long lLineCount = 0; /* Bad style. */
static long lWordCount = 0; /* Bad style. */
static long lCharCount = 0; /* Bad style. */
static int iChar;           /* Bad style. */
static int iInWord = FALSE; /* Bad style. */

int main(void)
{
loop1:
    iChar = getchar();
    if (iChar == EOF)
        goto endloop1;
    lCharCount++;
    if (!isspace(iChar))
        goto else1;
    if (!iInWord)
        goto endif1;
    lWordCount++;
    iInWord = FALSE;
    goto endif1;
else1:
    if (iInWord)
        goto endif1;
    iInWord = TRUE;
    goto endif1;
endif1:
    if (iChar != '\n')
        goto endif2;
    lLineCount++;
endif2:
    goto loop1;
endloop1:
    if (!iInWord)
        goto endif3;
    lWordCount++;
endif3:
    printf("%7ld %7ld %7ld\n", lLineCount, lWordCount, lCharCount);
    return 0;
}