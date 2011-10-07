// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

/*************************************************************************
 *
 * Ethernet MAC Layer Implementation
 * IEEE 802.3 Device MAC Address
 *
 *
 *
 * Retreives three bytes of MAC address from OTP.
 *
 *************************************************************************/

#include <xs1.h>
#include <platform.h>
#include <print.h>

#define OTPADDRESS 	0x7FF
#define OTPMASK    	0xFFFFFF

// OTP Read DEfines
#define MR_ADDRESS 	0x8001
#define WRITE		(1 << 1)
#define MODE_SEL	(1 << 8)
#define MRA			(1 << 9)
#define MRB			(1 << 10)
#define AUX_UPDATE	(1 << 11)


// READ access time
#define tRP_TICKS (80 / (1000 / XS1_TIMER_MHZ) ) // G-Series - Use the longer one
// #define tRP_TICKS (70 / (1000 / XS1_TIMER_MHZ) ) // L-Series


// Read an address in OTP
static int otpRead(port otp_data, out port otp_addr, port otp_ctrl, unsigned address)
{
	unsigned value, time;

	otp_addr <: address;
	sync(otp_addr);
	otp_ctrl <: 0 @ time;
	otp_ctrl @ (time + 10) <: 1;
	otp_ctrl @ (time + 10 + tRP_TICKS) <: 0;
	sync(otp_ctrl);
	otp_data :> void;
	otp_data :> value;

	return value;
}


// Setup the OTP for reading
void otpSetupRead(port otp_data, out port otp_addr, port otp_ctrl)
{
	// WriteAuxModeRegisterA
	otp_ctrl <: MRA ;
	otp_ctrl <: MRA | MODE_SEL;
	otp_data <: 0;
	sync(otp_data);
	sync(otp_ctrl);
	otp_addr <: MR_ADDRESS;
	sync(otp_addr);
	otp_ctrl <: MRA | MODE_SEL | WRITE | AUX_UPDATE;
	otp_ctrl <: MRA | MODE_SEL;
	otp_ctrl <: MRA;
	otp_ctrl <: 0;
	otp_addr <: 0;

	// WriteAuxModeRegisterB
	otp_ctrl <: MRB;
	otp_ctrl <: MRB | MODE_SEL;
	otp_data <: 0;
	sync(otp_data);
	sync(otp_ctrl);
	otp_addr <: MR_ADDRESS;
	sync(otp_addr);
	otp_ctrl <: MRB | MODE_SEL | WRITE | AUX_UPDATE;
	otp_ctrl <: MRB | MODE_SEL;
	otp_ctrl <: MRB;
	otp_ctrl <: 0;
	otp_addr <: 0;

	// WriteModeRegister
	otp_ctrl <: MODE_SEL;
	otp_data <: 0;
	sync(otp_data);
	sync(otp_ctrl);
	otp_addr <: MR_ADDRESS;
	sync(otp_addr);
	otp_ctrl <: MODE_SEL | WRITE;
	otp_ctrl <: MODE_SEL;
	otp_ctrl <: 0;
	otp_addr <: 0;
}


// Get the MAC address from the OTP
static int getMacAddrAux(port otp_data, out port otp_addr, port otp_ctrl, unsigned MACAddrNum, unsigned macAddr[2])
{
	int address = OTPADDRESS;
	unsigned bitmap;

	// Setup the read parameters for the OTP
	otpSetupRead(otp_data, otp_addr, otp_ctrl);

	if (MACAddrNum < 7)
	{
		int validbitmapfound = 0;

		while (!validbitmapfound && address >= 0)
		{
			bitmap = otpRead(otp_data, otp_addr, otp_ctrl, address);

			if (bitmap >> 31)
			{
				// Bitmap has not been written
				return 1;
			}
			else if (bitmap >> 30)
			{
				validbitmapfound = 1;
			}
			else
			{
				int length = (bitmap >> 25) & 0x1F;
				if (length==0)
				length=8;
				// Invalid bitmap
				address -= length;
			}
		}

		if (address < 0)
		{
			return 1;
		}
		else if (((bitmap >> 22) & 0x7) > MACAddrNum)
		{
			address -= ((MACAddrNum << 1) + 1);
			macAddr[0] = otpRead(otp_data, otp_addr, otp_ctrl, address);
			address--;
			macAddr[1] = otpRead(otp_data, otp_addr, otp_ctrl, address);
			return 0;
		}
		else
		{
			// MAC Address cannot be found
			return 1;
		}
	}
	else
	{
		// Incorrect number of MAC addresses given
		return 1;
	}
}

void ethernet_getmac_otp_indexed(port otp_data, out port otp_addr, port otp_ctrl, int macaddr[], unsigned index)
{
	unsigned int OTPId;
	unsigned int wrd_macaddr[2];
	timer tmr;

	if (getMacAddrAux(otp_data, otp_addr, otp_ctrl, index, wrd_macaddr) == 0)
	{
		// Valid MAC address found
		macaddr[0] = (wrd_macaddr[0] >> 8) & 0xFF;
		macaddr[1] = (wrd_macaddr[0]) & 0xFF;
		macaddr[2] = (wrd_macaddr[1] >> 24) & 0xFF;
		macaddr[3] = (wrd_macaddr[1] >> 16) & 0xFF;
		macaddr[4] = (wrd_macaddr[1] >> 8) & 0xFF;
		macaddr[5] = (wrd_macaddr[1]) & 0xFF;
	}
	else
	{
		// No valid MAC address found

		// get unique 24bits id from otp, thanks Sam!
		OTPId = ( otpRead(otp_data, otp_addr, otp_ctrl, OTPADDRESS) & OTPMASK );

		// reformat that into XMOS mac address and send it out
		if ( (OTPId & 0xffffff) == 0xffffff )
		{
			unsigned int time;
			unsigned int a=1664525;
			unsigned int c=1013904223;
			unsigned int j;


			tmr :> time;
			j = time & 0xf;

			for (int i=0; i<j; i++)
			{
				time = a * time + c;
			}

			OTPId = time;
		}

		macaddr[0] = 0x0;
		macaddr[1] = 0x22;
		macaddr[2] = 0x97;
		macaddr[3] = (OTPId >> 16) & 0xFF;
		macaddr[4] = (OTPId >> 8) & 0xFF;
		macaddr[5] = (OTPId & 0xFF) + index;
	}
}

void ethernet_getmac_otp_count(port otp_data, out port otp_addr, port otp_ctrl, int macaddr[][2], unsigned count)
{
	for (unsigned int n=0; n<count; n++) {
		ethernet_getmac_otp_indexed(otp_data, otp_addr, otp_ctrl, macaddr[n], n);
	}
}

void ethernet_getmac_otp(port otp_data, out port otp_addr, port otp_ctrl, int macaddr[])
{
	ethernet_getmac_otp_indexed(otp_data, otp_addr, otp_ctrl, macaddr, 0);
}

