#include "mii_full.h"

static int status[NUM_ETHERNET_MASTER_PORTS];
static int notify[NUM_ETHERNET_MASTER_PORTS];

void ethernet_update_link_status(int linkNum, int new_status)
{
  if (new_status != status[linkNum]) {
    status[linkNum] = new_status;
    notify[linkNum] = 1;
  }
}

int ethernet_get_link_status(int linkNum) {
  return status[linkNum];
}

int ethernet_link_status_notification(int linkNum) {
  int ret = notify[linkNum];
  notify[linkNum] = 0;
  return ret;
}
