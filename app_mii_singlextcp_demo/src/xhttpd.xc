// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>
#include <print.h>
#include "httpd.h"
#include "xtcp_client.h"

// The main webserver thread
void xhttpd(chanend tcp_svr)
{
  xtcp_connection_t conn;
  
  // Initiate the HTTP state
  httpd_init(tcp_svr);
   
  // Loop forever processing TCP events
  while(1)
    {
      select
        {
        case xtcp_event(tcp_svr, conn):
          httpd_handle_event(tcp_svr, conn);
          break;
        }
    }
}

