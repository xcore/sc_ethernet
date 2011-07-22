/**
 * Module:  app_ethernet_demo1
 * Version: 1v3
 * Build:   d5b0bfe5e956ae7926b1afc930d8f10a4b48a88e
 * File:    frame_channel.xc
 *
 * The copyrights, all other intellectual and industrial 
 * property rights are retained by XMOS and/or its licensors. 
 * Terms and conditions covering the use of this code can
 * be found in the Xmos End User License Agreement.
 *
 * Copyright XMOS Ltd 2009
 *
 * In the case where this code is a modification of existing code
 * under a separate license, the separate license terms are shown
 * below. The modifications to the code are still covered by the 
 * copyright notice above.
 *
 **/                                   
/*************************************************************************
 *
 * Ethernet MAC Layer Client Test Code
 * IEEE 802.3 MAC Client
 *
 *   File        : frame_channel.xc
 *
 *************************************************************************
 *
 * Copyright (c) 2008 XMOS Ltd.
 *
 * Copyright Notice
 *
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

