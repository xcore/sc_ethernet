#ifdef __XC__
#pragma select handler
void safe_mac_rx(chanend cIn, 
                        unsigned char buffer[], 
                        unsigned int &len,
                        unsigned int &src_port,
                        int n) ;
#endif

void mac_set_custom_filter(chanend c_mac_svr, int x);
