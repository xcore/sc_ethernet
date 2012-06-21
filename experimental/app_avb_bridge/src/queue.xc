// Copyright (c) 2012, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include "queue.h"

#define NQUEUES 2

struct queue {
    int totalWords;
    int baseAddress;
    int free;
    int wr;
    int rd;
} queues[NQUEUES];



#define QTX(n)        (0+(n))
#define QTXIP(n)      (2+(n))
#define QTXQAV(n)     (4+(n))
#define QLOCALQAV     (6)
#define QLOCAL        (7)

#define REQ_QIP  0
#define REQ_QTXQAV  1
#define REQ_QTXQLOCAL 2
#define REQ_QTXQLOCALRT  3

select requestCopier(chanend x) {
case x :> int cmd:
{int size;
    if (cmd == QGET) {
    }
    x :> size;
    
    switch (cmd) {
    case REQ_QIP:
        
        break;
    case REQ_QTXQAV:
        x :> size;
        
        break;
    case REQ_QTXQLOCAL:
        x :> size;
        
        break;
    case REQ_QTXQLOCALRT:
        x :> size;
//        allocFromQueue(local);
        break;
    }
}
    break;
}


select requestTransmitter(streaming chanend q) {
case q :> int val:
    if (val & 1) {
//        readyRight = true;
        
    } else {
//        readyLeft = true;
    }
    break;
}

void queueManager(chanend qLeft, chanend qRight,
                  streaming chanend qTransmit, chanend qAVB) {
    while(1) {
        select {
        case requestCopier(qLeft);
        case requestCopier(qRight);
        case requestTransmitter(qTransmit);
//        case requestCopier(qLocal);
        }
    }
}
