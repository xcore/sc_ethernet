// The ethernet_conf.h file sets configuration options for module_ethernet

// The default implementation controls which implementation ('full' or 'lite')
// is used when calling ethernet server and client functions
#define ETHERNET_DEFAULT_IMPLEMENTATION lite

/***** ports ********************************/

// Set this define if you want to combined MDC and MDIO on a single port
#define SMI_COMBINE_MDC_MDIO 0

/***** clients ******************************/

#define ETHERNET_MAX_RX_CLIENTS 1

#define ETHERNET_MAX_TX_CLIENTS 1

/***** 'full' implementation ****************/

#define ETHERNET_RX_BUFSIZE  (4096)

#define ETHERNET_RX_HP_QUEUE 0
//
//#define ETHERNET_RX_BUFSIZE_HIGH_PRIORITY (4096)
//#define ETHERNET_RX_BUFSIZE_LOW_PRIORITY (4096)

#define ETHERNET_CLIENT_FIFO_SIZE 4

#define ETHERNET_TX_BUFSIZE (2048)

#define ETHERNET_TX_HP_QUEUE 0
//#define ETHERNET_TX_BUFSIZE_HIGH_PRIORITY (4096)
//#define ETHERNET_TX_BUFSIZE_LOW_PRIORITY (4096)

#define ETHERNET_COUNT_PACKETS 0

/***** 'lite' implementation ****************/

#define ETHERNET_LITE_RX_BUFSIZE  (4096)

