#if 0
// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#define MAX_ETHERNET_PACKET_SIZE (1518)
#define MII_Q_SIZE (4096)

typedef struct mii_queue_t
{
	int frptr;
	int wrptr;
	int buf[MII_Q_SIZE/4];
} mii_queue_t;

static mii_queue_t even_q;
static mii_queue_t odd_q;

static int last_buf_q;
static int last_buf_i;

int next_buf_q = 0;
int next_buf_i = 0;

void mii_manage_rxbuffer(int packet_base, int packet_end)
{
	int accept_packet, buf_len_words, packet_len_bytes;

	buf_len_words = packet_end - packet_base;

	if (last_buf_q == 0) packet_len_bytes = mii_repair_tail(odd_q, buf_len_words);
	else packet_len_bytes = mii_repair_tail(even_q, length);
	
	// Filter on num of bytes in packet
	if (packet_len_bytes < 64)
	{
		accept_packet = 0;
	}
	else
	{
		accept_packet = 1;
	}
	
	if (accept_packet)
	{
		mii_commit();
	}
	else
	{
		mii_reject();
	}
}

void mii_repair_tail(mii_queue_t &queue, int buf_len_words)
{
	int tail_bytes, num_data_words;

	num_data_words = (buf_len_words - 6);

	tail_bytes = queue.buf[last_buf_i + buf_len_words - 1 - 1] >> 3;

	// Move tail bytes to after the last data word
	if (tail_bytes > 0)
	{
		queue.buf[last_buf_i + 3 + buf_len_words] = queue.buf[last_buf_i + buf_len_words - 1];
	}

	// Return total number of *bytes* in packet
	return (num_data_words << 2) + tail_bytes;
}

void mii_commit(void)
{
	last_buf_q = next_buf_q;
	last_buf_i = next_buf_i;
	
	if (next_buf_q == 0)
	{

	}
}

void mii_zero_queue(int even)
{
	if (!even)
	{
		odd_q.frptr = 0;
		odd_q.wrptr = 0;
		odd_q.full = 0;
	}
	else
	{
		even_q.frptr = 0;
		even_q.wrptr = 0;
		even_q.full = 0;
	}
}

#endif
