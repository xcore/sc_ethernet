#include <print.h>
#include <stdlib.h>

#include "mii_malloc.h"
#include "hwlock.h"

extern hwlock_t ethernet_memory_lock;

// for the purposes of this test, the maximum packet size is 220 bytes (which with the 36 byte
// mii packet header gives 256 bytes per packet payload, plus 2 words for the block header
// gives 66 words per block (264 bytes)

#define PACKET_SIZE_IN_BYTES (220)
#define MEM_BLOCK_HDR (2)
#define MEM_BUF_START (7)
#define MAX_BLOCK_SIZE (PACKET_SIZE_IN_BYTES+36+8)
#define BUFFER_SIZE  256

int buffer[BUFFER_SIZE];
mii_mempool_t mempool;

int done=0;

void wait(unsigned);

// Copied from the private data structure in mii_malloc.c
typedef struct mempool_info_t {
  int *rdptr;
  int *wrptr;
  int *start;
  int *end;
  unsigned max_packet_size;
} mempool_info_t;

mempool_info_t* hdr = buffer;

void do_error(unsigned line, char* string)
{
	printuint(line);
	printstr(" : ");
	printstrln(string);
	exit(0);
}

#define error(a) do_error(__LINE__, a);

static void test_init_mempool()
{
    mempool = (mii_mempool_t)buffer;
    mii_init_mempool(mempool, sizeof(buffer), PACKET_SIZE_IN_BYTES);
}

void test_logical()
{
	ethernet_memory_lock = __hwlock_init();

	test_init_mempool();

    if (hdr->rdptr != &buffer[5]) error("Buffer rdptr not correct");
    if (hdr->wrptr != &buffer[5]) error("Buffer wrptr not correct");
    if (hdr->max_packet_size != MAX_BLOCK_SIZE) error("Buffer max_packet_size not correct");
    if (hdr->start != &buffer[5]) error("Buffer start not correct");
    if (hdr->end   != &buffer[BUFFER_SIZE - MAX_BLOCK_SIZE/4]) error("Buffer end not correct");

    //
    // TEST GENERAL FILLING AND EMPTYING
    //
    {
    	unsigned b, b1,b2,b3,b4,b5,b6;

    	b1 = mii_reserve(mempool);
    	if (b1 != (unsigned)&buffer[MEM_BUF_START]) error("Empty buffer failed to return alloc");

    	b1 = mii_reserve(mempool);
    	if (b1 != (unsigned)&buffer[MEM_BUF_START]) error("Two reserves in row don't give same address");

    	// Allocate a 32 byte packet (40 bytes in buffer)
    	mii_commit(b1, 32);
    	if (*((unsigned*)b1-MEM_BLOCK_HDR) != (32/4+MEM_BLOCK_HDR))
    		error("Memory block incorrect size");

    	b2 = mii_reserve(mempool);
    	if (b2 != (unsigned)&buffer[MEM_BUF_START + 32/4 + MEM_BLOCK_HDR])
    		error("New write pointer in wrong place");

    	// Allocate a 128 byte packet (176 bytes in buffer)
    	mii_commit(b2, 128);
    	if (*((unsigned*)b2-MEM_BLOCK_HDR) != (128/4+MEM_BLOCK_HDR))
    		error("Memory block incorrect size");

    	b3 = mii_reserve(mempool);
    	if (b3 != (unsigned)&buffer[MEM_BUF_START + 32/4 + 128/4 + MEM_BLOCK_HDR*2])
    		error("New write pointer in wrong place");

    	// Allocate a 128 byte packet (312 bytes in buffer)
    	mii_commit(b3, 128);

    	b4 = mii_reserve(mempool);
    	if (b4 != (unsigned)&buffer[MEM_BUF_START + 32/4 + 128/4 + 128/4 + MEM_BLOCK_HDR*3])
    		error("New write pointer in wrong place");

    	// Allocate a 200 byte packet (520 bytes in buffer)
    	mii_commit(b4, 200);

    	b5 = mii_reserve(mempool);
    	if (b5 != (unsigned)&buffer[MEM_BUF_START + 32/4 + 128/4 + 128/4 + 200/4 + MEM_BLOCK_HDR*4])
    		error("New write pointer in wrong place");

    	// Allocate a 200 byte packet (728 bytes in buffer)
    	mii_commit(b5, 200);

    	// Allocate a 200 byte packet (936 bytes in buffer)
    	b6 = mii_reserve(mempool);
    	mii_commit(b6, 200);

    	// Write pointer should wrap because not enough to ensure full reception: 936+264 > 1024
        if (hdr->wrptr != &buffer[5]) error("Buffer wrptr not correct");

    	// Reserve should fail because the buffer is in use
    	b = mii_reserve(mempool);
    	if (b != 0)
    		error("Should return 0 indicating full buffer");

    	// Write pointer has wrapped
        if (hdr->rdptr != &buffer[5]) error("Buffer rdptr not correct");
        if (*hdr->wrptr == 0) error("First packet marked empty");

        // Free first packet
        mii_free(b1);
        if (hdr->rdptr != &buffer[5 + 32/4 + MEM_BLOCK_HDR]) error("Buffer rdptr not correct");
        if (hdr->wrptr != &buffer[5]) error("Buffer wrptr not correct");
        if (*hdr->wrptr != 0) error("First packet not marked empty");

    	// Hole at start is 40 bytes
    	b = mii_reserve(mempool);
    	if (b != 0) error("Should return 0 indicating full buffer");

    	// Free second packet (hole is 176 bytes)
        mii_free(b2);
    	b = mii_reserve(mempool);
    	if (b != 0) error("Should return 0 indicating full buffer");

    	// Free third packet (hole is 312 bytes)
        mii_free(b3);
    	b = mii_reserve(mempool);
    	if (b != (unsigned)&buffer[MEM_BUF_START]) error("Should return 0 indicating full buffer");

    	// Free 4th and 5th packets
        mii_free(b4);
        mii_free(b5);

    	// Free 6th packet
        mii_free(b6);
        if (hdr->rdptr != &buffer[5]) error("Buffer rdptr not correct");

    	b = mii_reserve(mempool);
    	if (b != (unsigned)&buffer[MEM_BUF_START]) error("Should return 0 indicating full buffer");
    }

    //
    //  TEST BUFFER FREE OF OUT-OF-ORDER PACKETS
    //

    test_init_mempool();
	{
		unsigned b1,b2,b3,b4,b5,b6;

    	// Allocate a 32 byte packet (40 bytes in buffer)
    	b1 = mii_reserve(mempool);
    	mii_commit(b1, 32);

    	// Allocate a 128 byte packet (176 bytes in buffer)
    	b2 = mii_reserve(mempool);
    	mii_commit(b2, 128);

    	// Allocate a 128 byte packet (312 bytes in buffer)
    	b3 = mii_reserve(mempool);
    	mii_commit(b3, 128);

    	// Allocate a 200 byte packet (520 bytes in buffer)
    	b4 = mii_reserve(mempool);
    	mii_commit(b4, 200);

    	// Allocate a 200 byte packet (728 bytes in buffer)
    	b5 = mii_reserve(mempool);
    	mii_commit(b5, 200);

    	// Allocate a 200 byte packet (936 bytes in buffer)
    	b6 = mii_reserve(mempool);
    	mii_commit(b6, 200);

        if ((unsigned)hdr->wrptr != b1-8) error("Buffer wrptr not correct");
        if ((unsigned)hdr->rdptr != b1-8) error("Buffer rdptr not correct");

        // Free 2nd packet
        mii_free(b2);
        if ((unsigned)hdr->rdptr != b1-8) error("Buffer rdptr not correct");

        // Free 1st packet
        mii_free(b1);
        if ((unsigned)hdr->rdptr != b3-8) error("Buffer rdptr not correct");

        // Free 4th+5th packet
        mii_free(b4);
        mii_free(b5);
        if ((unsigned)hdr->rdptr != b3-8) error("Buffer rdptr not correct");

        // Free 3rd packet
        mii_free(b3);
        if ((unsigned)hdr->rdptr != b6-8) error("Buffer rdptr not correct");

    	// Allocate a 32 byte packet (40 bytes in buffer)
    	b1 = mii_reserve(mempool);
    	mii_commit(b1, 32);

    	// Allocate a 32 byte packet (40 bytes in buffer)
    	b2 = mii_reserve(mempool);
    	mii_commit(b2, 32);

        // Free 6th packet
        mii_free(b6);
        if ((unsigned)hdr->rdptr != b1-8) error("Buffer rdptr not correct");
	}
}


// TESTS FOR CHECKING INTER-THREAD TIMING

unsigned counter_no_mem = 0;
unsigned counter_allocated = 0;
unsigned counter_freed = 0;

unsigned server_rdptr;

void test_timing_init()
{
	test_init_mempool();
	server_rdptr = mii_init_my_rdptr(mempool);
}

void test_timing_read()
{
	srand(11);
	while (!done)
	{
		mii_buffer_t buf = mii_get_my_next_buf(mempool, server_rdptr);
		if (buf != 0)
		{
			wait(0xf);
			server_rdptr = mii_update_my_rdptr(mempool, server_rdptr);
			wait(0xff);
			mii_free(buf);
			counter_freed++;
		}
	}
}


void test_timing_write()
{
	srand(7);
	while (counter_allocated < 0x1000000)
	{
		mii_buffer_t buf = mii_reserve(mempool);
		if (buf != 0)
		{
			mii_commit(buf, 40);
			counter_allocated++;
			wait(0xff);
		}
		else
		{
			counter_no_mem++;
		}
	}
	done = 1;
}


