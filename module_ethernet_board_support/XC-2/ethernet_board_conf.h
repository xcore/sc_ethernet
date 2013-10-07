#ifndef __ethernet_board_defaults_h__
#define __ethernet_board_defaults_h__

#define ETHERNET_DEFAULT_TILE stdcore[2]
#define ETHERNET_DEFAULT_PHY_ADDRESS 0x1f
#define SMI_MDIO_BIT 7
#define SMI_MDIO_REST (~(1<<7))
#define SMI_MDIO_RESET_MUX 1


#endif // __ethernet_board_defaults_h__
