/* Read data from stdin and write it to the OTP */

#include <syscall.h>
#include <print.h>
#include <otp.h>
#include <stdlib.h>
#include <platform.h>

/* Core number to write the MAC address to */
#define MAC_ADDR_CORENUM 1

/* Bitmap at address 0x7ff:
 * Bitfield 	 Name 	 Description
 * [31] 	validFlag 	If ==0, this structure has been written and should be processed.
 * [30] 	newbitmapFlag 	If ==0, this bitmap is now invalid, and a new bitmap should be processed which follows the structure.
 * [25:29] 	headerLength 	Length of structure in words (including bitmap) rounded up to the next even number.
 * [22:24] 	numMac 	Number of MAC addresses that follow this bitmap (0-7).
 * [21] 	serialFlag 	if ==1, Board serial number follows bitmap.
 * [20] 	boardIDFlag 	if == 1, XMOS Board Identifier follows bitmap.
 * [19] 	boardIDStrFlag 	if == 1, Board ID string (null terminated) follows bitmap.
 * [18] 	oscSpeed 	if == 0, 25Mhz clock input to XCore. if ==1, undefined.
 * [0:17] 	undefined 	Leave =1.
 */

#define MASK(x) ((1 << x) - 1)
#define VALID_FLAG(x) ((x & MASK(1)) << 31)
#define NEW_BITMAP_FLAG(x) ((x & MASK(1)) << 30)
#define HEADER_LENGTH(x) ((x & MASK(5)) << 25)
#define NUM_MAC(x) ((x & MASK(3)) << 22)
#define SERIAL_FLAG(x) ((x & MASK(1)) << 21)
#define BOARD_ID_FLAG(x) ((x & MASK(1)) << 20)
#define BOARD_ID_STR_FLAG(x) ((x & MASK(1)) << 19)
#define OSC_SPEED_FLAG(x) ((x & MASK(1)) << 18)
#define RESERVED ((~0 & MASK(18)) << 0)


// Convert a hex char into the integer value
int charValue(char c)
{
	if (c >= '0' && c <= '9')
	{
		return c - '0';
	}

	if (c >= 'a' && c <= 'f')
	{
		return c + 0xa - 'a';
	}

	if (c >= 'A' && c <= 'F')
	{
		return c + 0xa - 'A';
	}

	return -1;
}


// Read board seial number from stdin. Must be string of 8 decimal digits with no seperators.
unsigned int readserialnum( void )
{
	char buf[9];
	unsigned int val;

	if (_read(FD_STDIN, buf, 9) < 9)
	{
		return 0;
	}

	if (buf[8] != '\n')
	{
		return 0;
	}

	// Check that all the characters are digits
	for (unsigned i = 0; i < 8; i++)
	{
		int val = charValue(buf[i]);

		if ( (val < 0) | (val > 9) )
		{
			return 0;
		}
	}

	val  = charValue(buf[0]) * 10000000;
	val += charValue(buf[1]) * 1000000;
	val += charValue(buf[2]) * 100000;
	val += charValue(buf[3]) * 10000;
	val += charValue(buf[4]) * 1000;
	val += charValue(buf[5]) * 100;
	val += charValue(buf[6]) * 10;
	val += charValue(buf[7]);

	return val;
}


// Read board identifier from stdin. Must be string of 8 hexadecimal digits with no seperators.
unsigned int readboardidentifier( void )
{
	char buf[9];
	unsigned int ret_val = 0;

	if (_read(FD_STDIN, buf, 9) < 9)
	{
		return 0;
	}

	if (buf[8] != '\n')
	{
		return 0;
	}

	for (unsigned i = 0; i < 8; i++)
	{
		int val = charValue(buf[i]);

		if (val < 0)
		{
			return 0;
		}

		ret_val = (ret_val << 4) | val;
	}

	return ret_val;
}


// Read number of MAC addresses from stdin. Must be string of 1 digits with no seperators.
unsigned int readnumMAC(void)
{
	char buf[2];
	unsigned int val;

	if (_read(FD_STDIN, buf, 2) < 2)
	{
		return 0;
	}

	if (buf[1] != '\n')
	{
		return 0;
	}

	// Conver the char into a number
	val = charValue(buf[0]);

	if (val > 7)
	{
		printstr("Error number of MAC addresses greater than 7\n");
		_Exit(1);

		return 0;
	}

	return val;
}


// Read MAC address from stdin. Must be string of 12 hexadecimal digits with no seperators.
int readMAC(unsigned &word1, unsigned &word2)
{
	char buf[13];

	if (_read(FD_STDIN, buf, 13) < 13)
		return 0;

	if (buf[12] != '\n')
		return 0;
	word1 = 0;

	for (unsigned i = 0; i < 4; i++)
	{
		int val = charValue(buf[i]);

		if (val < 0)
		{
			return 0;
		}

		word1 = (word1 << 4) | val;
	}

	word2 = 0;

	for (unsigned i = 0; i < 8; i++)
	{
		int val = charValue(buf[i + 4]);

		if (val < 0)
		{
	  		return 0;
		}

		word2 = (word2 << 4) | val;
	}

	return 1;
}


// Get the board information and write it to the OTP
void domac(port otp_data, out port otp_addr, out port otp_ctrl)
{
	char buf[2];
	unsigned data[19];
	unsigned mac_u[8], mac_l[8];
	unsigned serial_number, board_identifier, num_MAC_address;
	Options options;
	timer t;

	#if defined(__XS1_L__)
		printstr("\nOTP programmer (L1)\n");
	#elif defined(__XS1_G__)
		printstr("\nOTP programmer (G4)\n");
	#else
		#error "Specify target"
	#endif

	printstr("OTP data will be written to stdcore[");
	printint(MAC_ADDR_CORENUM);
	printstr("]\n");

	printstr("\nEnter serial number (8 digits, enter for none): ");
	serial_number = readserialnum();

	printstr("Enter board identifier (8 digits, enter for none): ");
	board_identifier = readboardidentifier();

	printstr("Enter number of MAC addresses (0-7): ");
	num_MAC_address = readnumMAC();

	for ( unsigned int i = 0; i < num_MAC_address; i++ )
	{
		printstr("Enter MAC address ");
		printint(i);
		printstr(" (e.g. 123456789abc): ");

		mac_u[i] = 0;
		mac_l[i] = 0;

		if (!readMAC(mac_u[i], mac_l[i]))
		{
			printstr("Error reading MAC address from stdin\n");
			_Exit(1);
		}
	}

    // Now, print out the data to the user
	printstr("\nSerial Number: ");
	printuint(serial_number);

	printstr("\nBoard Identifier: 0x");
	printhex(board_identifier);

	printstr("\nNum Of MAC Addresses: ");
	printuint(num_MAC_address);

	for ( unsigned int i = 0; i < num_MAC_address; i++ )
	{
		printstr("\nMAC address ");
		printint(i);
		printstr(" : ");

		printhex(mac_u[i]);
		printhex(mac_l[i]);
	}

	printstr("\n\nEnter 1 to confirm data for writing, 0 to cancel: ");

	// Get them to enter a 1 to confirm
	if (_read(FD_STDIN, buf, 2) < 2)
	{
		printstrln("Error reading value from stdin\n");
		_Exit(2);
	}

	// Check if we can write the data
	if ( charValue(buf[0]) == 1 )
	{
		unsigned int has_serial = 0;
		unsigned int has_board_id = 0;
		unsigned int data_length = 0;
		unsigned int dp = 0;

		// Test if we have a board identifier
		if ( board_identifier != 0 )
		{
			has_board_id = 1;

			data[dp] = board_identifier;
			dp++;
		}

		// Test if we have a serial number
		if ( serial_number != 0 )
		{
			has_serial = 1;

			data[dp] = serial_number;
			dp++;
		}

		// Add the MAC addresses to the data buffer
		for ( unsigned int i = 0; i < num_MAC_address; i++ )
		{
			data[dp] = mac_l[i];
			dp++;

			data[dp] = mac_u[i];
			dp++;
		}

		// Setup the bitmap byte
		data[dp] = (VALID_FLAG(0) | NEW_BITMAP_FLAG(1) | HEADER_LENGTH(4) | NUM_MAC(num_MAC_address) | SERIAL_FLAG(has_serial) | BOARD_ID_FLAG(has_board_id) | BOARD_ID_STR_FLAG(0) | OSC_SPEED_FLAG(1) | RESERVED);
		dp++;

		// Calcualate the data length
		data_length = ( num_MAC_address * 2 ) + has_serial + has_board_id + 1;

		// Check that it matches what we have calculated.
		if ( dp != data_length )
		{
			printstrln("Error in calcualating OTP data length\n");
			_Exit(2);
		}

		// Setup the OTP options
		InitOptions(options);
		options.EnableChargePump = 1;
		options.differential_mode = 0;

		// Print data for checking
		for ( unsigned int i = 0; i < data_length; i++ )
		{
			printstr("\n0x");
			printhex(data[i]);
		}

		if (!Program(t, otp_data, otp_addr, otp_ctrl, 0x800 - data_length, data, data_length, options))
		{
			printstrln("Error writing MAC address to OTP\n");
			_Exit(2);
		}

		printstr("\nOTP data written\n");
	}
	else
	{
		printstr("\nOTP data not written\n");
	}
}

port otp_data = on stdcore[MAC_ADDR_CORENUM]: XS1_PORT_32B;
out port otp_addr = on stdcore[MAC_ADDR_CORENUM]: XS1_PORT_16C;
out port otp_ctrl = on stdcore[MAC_ADDR_CORENUM]: XS1_PORT_16D;

int main()
{
	par
	{
		on stdcore[MAC_ADDR_CORENUM] : domac(otp_data, otp_addr, otp_ctrl);
	}

	return 0;
}
