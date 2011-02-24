void one_port_filter(mii_packet_t buf[],
                     const int mac[2],
                     REFERENCE_PARAM(mii_queue_t, free_queue),
                     REFERENCE_PARAM(mii_queue_t, internal_q),
                     streaming chanend c);

void two_port_filter(mii_packet_t buf[],
                     const int mac[2],
                     REFERENCE_PARAM(mii_queue_t,free_q),
                     REFERENCE_PARAM(mii_queue_t,internal_q),
                     REFERENCE_PARAM(mii_queue_t,q1),
                     REFERENCE_PARAM(mii_queue_t,q2),
                     streaming chanend c0,
                     streaming chanend c1);

