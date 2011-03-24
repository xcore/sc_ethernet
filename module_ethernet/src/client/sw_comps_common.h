/*
 * @ModuleName Generic frame work and definations for software component.
 * @Author Ayewin Oung
 * @Date 06/11/2006
 * @Version 1.0
 * @Description: Generic frame work and definations.
 *
 * Copyright XMOS Ltd 2008
 */


#ifndef _SW_COMPS_COMMON_H_
#define _SW_COMPS_COMMON_H_  1

// Generic definations.
#ifndef NULL
#define NULL   (0)
#endif

#ifndef FALSE
#define FALSE  (0)
#endif

#ifndef TRUE
#define TRUE   (1)
#endif

//#define uint  unsigned int
//#define uchar unsigned char

// Guard agains multiple file issues.
#ifndef _XMOS_RTN_t_
#define _XMOS_RTN_t_
// Generic return
typedef enum
{
   XMOS_SUCCESS = 0,    // Success
   XMOS_FAIL,           // Fail
   XMOS_INVALID_PARA,   // Invalid parameter
   XMOS_TIME_OUT,       // Time out
   XMOS_RES_UNAVB,      // Resource unavaliable
   XMOS_ACK,            // acknowledged.
   XMOS_NACK,           // negative acknowledged
   XMOS_FRAMING_ERROR,
   XMOS_UNDERFLOW,
   XMOS_OVERFLOW
} XMOS_RTN_t;
#endif

typedef unsigned int  uint;
typedef unsigned char uchar;


#ifndef SW_REF_CLK_MHZ
// Default 100MHz software ref clock.
#define SW_REF_CLK_MHZ  100
#endif


// Tools bug work around
#define TRANSACTION_MASTER    master
#define TRANSACTION_SLAVE     slave

// app control token for kill
#define CT_APP_KILL           0x80

#endif
