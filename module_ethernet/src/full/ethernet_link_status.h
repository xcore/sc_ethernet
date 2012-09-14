#ifndef __ethernet_link_status_h__
#define __ethernet_link_status_h__
void ethernet_update_link_status(int linkNum, int status);

int ethernet_get_link_status(int linkNum);

int ethernet_link_status_notification(int linkNum);

#endif // __ethernet_link_status_h__
