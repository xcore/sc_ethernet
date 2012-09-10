// The ethernet_conf.h file sets configuration options for module_ethernet

// The default implementation controls which implementation ('full' or 'lite')
// is used when calling ethernet server and client functions
#define ETHERNET_DEFAULT_IMPLEMENTATION lite

/***** 'full' implementation ****************/

#define ETHERNET_RX_BUFSIZE  (4096)

#define ETHERNET_RX_HP_QUEUE 0
//
//#define ETHERNET_RX_BUFSIZE_HIGH_PRIORITY (4096)
//#define ETHERNET_RX_BUFSIZE_LOW_PRIORITY (4096)

#define ETHERNET_CLIENT_FIFO_SIZE 4

#define ETHERNET_TX_BUFSIZE (2048)

#define ETHENRET_TX_HP_QUEUE 0
//#define ETHERNET_TX_BUFSIZE_HIGH_PRIORITY (4096)
//#define ETHERNET_TX_BUFSIZE_LOW_PRIORITY (4096)

#define ETHERNET_COUNT_PACKETS 0

/***** 'lite' implementation ****************/

#define ETHERNET_LITE_RX_BUFSIZE  (4096)

/***** Default Initializers ********/

// The following settings affect the contents of the default port intializers:
// ETHERNET_DEFAULT_SMI_INIT and ETHERNET_DEFAULT_MII_INIT

// This setting controls the phy address used by the
// ETHERNET_DEFAULT_SMI_INIT initializer
#define ETHERNET_DEFAULT_PHY_ADDRESS (0x0)

// This setting controls the tile that ethernet
// is placed for the default port initializers
#define ETHERNET_DEFAULT_TILE tile[0]

#define ETHERNET_DEFAULT_CLKBLK_0 XS1_CLKBLK_1

#define ETHERNET_DEFAULT_CLKBLK_1 XS1_CLKBLK_2

