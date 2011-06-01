#define USER_BUFFER_SIZE_BITS      4
#define SYSTEM_BUFFER_SIZE_BITS    4

#define USER_BUFFER_SIZE           (1<<USER_BUFFER_SIZE_BITS)
#define SYSTEM_BUFFER_SIZE         (1<<SYSTEM_BUFFER_SIZE_BITS)

#ifndef ASSEMBLER
extern void miiTBufferInit(chanend c_in, int buffer[], int words, int doFilter);
extern void miiInstallHandler(chanend miiChannel);
{int,int} miiReceiveBuffer(int block);
extern void miiReturnBufferToPool(int bufferAddress);
#endif
