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
#include <xclib.h>
#include <platform.h>

#include "getmac.h"

#define OTPADDRESS 	0x7FF
#define OTPMASK    	0xFFFFFF

// OTP Read DEfines
#define MR_ADDRESS 	0x8001
#define WRITE		(1 << 1)
#define MODE_SEL	(1 << 8)
#define MRA		(1 << 9)
#define MRB		(1 << 10)
#define AUX_UPDATE	(1 << 11)


// READ access time
#define tRP_TICKS (80 / (1000 / XS1_TIMER_MHZ) )


// Read an address in OTP
static int otpRead(struct otp_ports& p, unsigned address)
{
	unsigned value, time;

	p.otp_addr <: address;
	sync(p.otp_addr);
	p.otp_ctrl <: 0 @ time;
	p.otp_ctrl @ (time + 10) <: 1;
	p.otp_ctrl @ (time + 10 + tRP_TICKS) <: 0;
	sync(p.otp_ctrl);
	p.otp_data :> void;
	p.otp_data :> value;

	return value;
}

static void otpSetupReadF1(struct otp_ports& p)
{
	p.otp_data <: 0;
	sync(p.otp_data);
	sync(p.otp_ctrl);
	p.otp_addr <: MR_ADDRESS;
	sync(p.otp_addr);
}

static void otpSetupReadTerm(struct otp_ports& p)
{
	p.otp_ctrl <: 0;
	p.otp_addr <: 0;
}

static void otpSetupReadModeRegister(struct otp_ports& p, unsigned reg)
{
	p.otp_ctrl <: reg ;
	p.otp_ctrl <: reg | MODE_SEL;
	otpSetupReadF1(p);
	p.otp_ctrl <: reg | MODE_SEL | WRITE | AUX_UPDATE;
	p.otp_ctrl <: reg | MODE_SEL;
	p.otp_ctrl <: reg;
	otpSetupReadTerm(p);
}

// Setup the OTP for reading
void otpSetupRead(struct otp_ports& p)
{
	// WriteAuxModeRegisterA
	otpSetupReadModeRegister(p, MRA);

	// WriteAuxModeRegisterB
	otpSetupReadModeRegister(p, MRB);

	// WriteModeRegister
	p.otp_ctrl <: MODE_SEL;
	otpSetupReadF1(p);
	p.otp_ctrl <: MODE_SEL | WRITE;
	p.otp_ctrl <: MODE_SEL;
	otpSetupReadTerm(p);
}


// Get the MAC address from the OTP
#pragma unsafe arrays
{ unsigned, unsigned } static getMacAddrAux(struct otp_ports &p, unsigned MACAddrNum)
{
	int address = OTPADDRESS;
	unsigned bitmap;
	int validbitmapfound = 0;
	unsigned a=0,b=0;

	// Setup the read parameters for the OTP
	otpSetupRead(p);


	while (!validbitmapfound && address >= 0)
	{
		bitmap = otpRead(p, address);

		if (bitmap >> 31)
		{
			// Bitmap has not been written
			break;
		}
		else if (bitmap >> 30)
		{
			validbitmapfound = 1;
		}
		else
		{
			int length = (bitmap >> 25) & 0x1F;
			if (length==0) length=8;
			// Invalid bitmap
			address -= length;
		}
	}

	if (validbitmapfound && ((bitmap >> 22) & 0x7) > MACAddrNum)
	{
		address -= ((MACAddrNum << 1) + 1);
		b = otpRead(p, address);
		address--;
		a = otpRead(p, address);
	}
	return { a, b };
}

#pragma unsafe arrays
void ethernet_getmac_otp_indexed(struct otp_ports& p, char macaddr[], unsigned index)
{
	unsigned int a, b;

	{ a, b } = getMacAddrAux(p, index);
	if (a == 0)
	{
		// get unique 24bits id from otp, thanks Sam!
		unsigned int OTPId = ( otpRead(p, OTPADDRESS) & OTPMASK );
		if ( OTPId == 0xffffff ) OTPId = 0;

		b = 0x00000002;
		a = 0x97000000 + OTPId + index;
	}

	// Valid MAC address found
	(macaddr, unsigned[])[0] = (byterev(b) >> 16) + (byterev(a) << 16);
	(macaddr, short[])[2] = (byterev(a) >> 16);
}

void ethernet_getmac_otp_count(struct otp_ports& p, int macaddr[][2], unsigned count)
{
	for (unsigned int n=0; n<count; n++) {
		ethernet_getmac_otp_indexed(p, (macaddr[n], char[]), n);
	}
}

void ethernet_getmac_otp(struct otp_ports& p, char macaddr[])
{
	ethernet_getmac_otp_indexed(p, macaddr, 0);
}

