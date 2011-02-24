#ifndef _getmac_h_
#define _getmac_h_

// Retrieves least significant 24bits from MAC address stored in OTP
void ethernet_getmac_otp(port otp_data, out port otp_addr, port otp_ctrl, char macaddr[]);

#endif
