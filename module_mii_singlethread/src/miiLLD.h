extern unsigned int tailValues[4];
extern void miiLLD(buffered in port:32 rxd, in port rxdv, buffered out port:32 txd,
                   chanend INchannel, chanend OUTchannel, in port timing,
                   timer tmr);
