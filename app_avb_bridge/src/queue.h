// Copyright (c) 2012, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

/** Function that manages all queues in the system; it gets requests from
 * the left, right, transmitter, and the local node. Requests from the
 * copiers comprise a ``QGET(queuenumber, size) -> address`` and
 * ``QCOMMIT(queuenumber, address)``. The local node may also ask for
 * ``hmmmm``. The transmitter requests comprise ``QGET() -> queuenumber,
 * address, size`` and ``QCOMMIT(queuenumber, address)``.
 *
 * \param qLeft  request channel from left copier
 * \param qRight request channel from right copier
 * \param qTransmit request channel from transmitter
 * \param qLocal request channel from local node
 */
void queueManager(chanend qLeft, chanend qRight,
                  streaming chanend qTransmit, chanend qLocal);

#define QTX(n)        (0+(n))
#define QTXIP(n)      (2+(n))
#define QTXQAV(n)     (4+(n))
#define QLOCALQAV     (6)
#define QLOCAL        (7)

#define QGET          (0)
#define QCOMMIT       (1)
