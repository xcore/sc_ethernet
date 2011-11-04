#include <xccompat.h>

/** Sends an ethernet frame. Frame includes dest/src MAC address(s), type
 *  and payload.
 *
 *
 *  \param c_mac     channel end to tx server.
 *  \param buffer[]  byte array containing the ethernet frame. *This must
 *                   be word aligned*
 *  \param nbytes    number of bytes in buffer
 *  \param ifnum     the number of the eth interface to transmit to 
 *                   (use ETH_BROADCAST transmits to all ports)
 *
 */
void mac_tx(chanend c_mac, unsigned int buffer[], int nbytes, int ifnum);

/** Sends an ethernet frame and gets the timestamp of the send. 
 *  Frame includes dest/src MAC address(s), type
 *  and payload.
 *
 *  This is a blocking call and returns the *actual time* the frame
 *  is sent to PHY according to the XCore 100Mhz 32-bit timer on the core
 *  the ethernet server is running.
 *
 *  \param c_mac     channel end connected to ethernet server.
 *  \param buffer[]  byte array containing the ethernet frame. *This must
 *                   be word aligned*
 *  \param nbytes    number of bytes in buffer
 *  \param ifnum     the number of the eth interface to transmit to 
 *                   (use ETH_BROADCAST transmits to all ports)
 *  \param time      A reference paramater that is set to the time the
 *                   packet is sent to the phy
 *
 *  NOTE: This function will block until the packet is sent to PHY.
 */
void mac_tx_timed(chanend c_mac, unsigned int buffer[], int nbytes,
                  REFERENCE_PARAM(unsigned int, time),
                  int ifnum);
