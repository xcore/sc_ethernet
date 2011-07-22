// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

/*************************************************************************
 *
 * Ethernet MAC Layer Client Test Code
 * IEEE 802.3 MAC Client
 *
 *   File        : frame_channel.xc
 *
 *************************************************************************
 *************************************************************************
 *
 * Functions for passing an Ethernet frame over a channel.
 *
 *************************************************************************/

#include "frame_channel.h"

void pass_frame(chanend c, const unsigned char buffer[], int nbytes)
{
	master
	{
		int nwords;
		c <: nbytes;
		nwords = (nbytes >> 2) + 1;
#pragma unsafe arrays
		for (int i = 0; i < nwords; i++)
		{
			c <: (buffer, unsigned[])[i];
		}
	}
}

void fetch_frame(unsigned char buffer[], chanend c, int &nbytes)
{
	slave
	{
		int nwords;
		c :> nbytes;
		nwords = (nbytes >> 2) + 1;
#pragma unsafe arrays
		for (int i = 0; i < nwords; i++)
		{
			c :> (buffer, unsigned[])[i];
		}
	}
}

