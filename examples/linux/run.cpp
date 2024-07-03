#include <stdio.h>
 
int main(void)
{
    unsigned char shellcode[] = "";
    
    // printf("Shellcode Length: %d\n", (int)sizeof(shellcode)-1);

    (*(void (*)())shellcode)();

    return 1;
}