// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <string.h>
#include <print.h>
#include "xtcp_client.h"
#include "httpd.h"


// Default HTTP page with HTTP headers included
char page[] = "HTTP/1.0 200 OK\nServer: xc2/pre-1.0 (http://xmos.com)\nContent-type: text/html\n\n<html><head></head><body>Hello World!</body></html>\n\n";


// Maximum number of concurrent connections
#define NUM_HTTPD_CONNECTIONS 10


// Structure to hold HTTP state
typedef struct httpd_state_t {
  int active;      //< Whether this state structure is being used
                   //  for a connection
  int conn_id;     //< The connection id 
  char *dptr;      //< Pointer to the remaining data to send
  int dlen;        //< The length of remaining data to send
  char *prev_dptr; //< Pointer to the previously sent item of data
} httpd_state_t;

httpd_state_t connection_states[NUM_HTTPD_CONNECTIONS];
////

// Initialize the HTTP state
void httpd_init(chanend tcp_svr)
{
  int i;
  // Listen on the http port
  xtcp_listen(tcp_svr, 80, XTCP_PROTOCOL_TCP);
  
  for ( i = 0; i < NUM_HTTPD_CONNECTIONS; i++ )
    {
      connection_states[i].active = 0;
      connection_states[i].dptr = NULL;
    }
}
////

// Parses a HTTP request for a GET
void parse_http_request(httpd_state_t *hs, char *data, int len)
{
  // Return if we have data already
  if (hs->dptr != NULL)
    {
      return;
    }
  
  // Test if we received a HTTP GET request
  if (strncmp(data, "GET ", 4) == 0)
    {
      // Assign the default page character array as the data to send
      hs->dptr = &page[0];
      hs->dlen = strlen(&page[0]);
    }
  else
    {
      // We did not receive a get request, so do nothing
    }
}
//:

// Receive a HTTP request
void httpd_recv(chanend tcp_svr, xtcp_connection_t *conn)
{
  struct httpd_state_t *hs = (struct httpd_state_t *) conn->appstate;
  char data[XTCP_CLIENT_BUF_SIZE];
  int len;
  
  // Receive the data from the TCP stack
  len = xtcp_recv(tcp_svr, data);
  
  // If we already have data to send, return
  if ( hs == NULL || hs->dptr != NULL)
    {
      return;
    }
  
  // Otherwise we have data, so parse it
  parse_http_request(hs, &data[0], len);
  
  // If we are required to send data
  if (hs->dptr != NULL)
    {
      // Initate a send request with the TCP stack.
      // It will then reply with event XTCP_REQUEST_DATA 
      // when it's ready to send
      xtcp_init_send(tcp_svr, conn);
    }
  ////
}


// Send some data back for a HTTP request
void httpd_send(chanend tcp_svr, xtcp_connection_t *conn)
{
  struct httpd_state_t *hs = (struct httpd_state_t *) conn->appstate;

  // Check if we need to resend previous data
  if (conn->event == XTCP_RESEND_DATA) {
    xtcp_send(tcp_svr, hs->prev_dptr, (hs->dptr - hs->prev_dptr));
    return;
  }

  // Check if we have no data to send
  if (hs->dlen == 0 || hs->dptr == NULL)
    {
      // Terminates the send process
      xtcp_complete_send(tcp_svr);
      // Close the connection
      xtcp_close(tcp_svr, conn);
    }
  // We need to send some new data
  else {
    int len = hs->dlen;
    
    if (len > conn->mss)
      len = conn->mss;

    xtcp_send(tcp_svr, hs->dptr, len);
    
    hs->prev_dptr = hs->dptr;
    hs->dptr += len;
    hs->dlen -= len;    
  }
  ////

}


// Setup a new connection
void httpd_init_state(chanend tcp_svr, xtcp_connection_t *conn)
{
  int i;
  
  // Try and find an empty connection slot
  for (i=0;i<NUM_HTTPD_CONNECTIONS;i++)
    {
      if (!connection_states[i].active)
        break;
    }
  
  // If no free connection slots were found, abort the connection
  if ( i == NUM_HTTPD_CONNECTIONS )
    {
      xtcp_abort(tcp_svr, conn);
    }
  // Otherwise, assign the connection to a slot        //
  else
    {
      connection_states[i].active = 1;
      connection_states[i].conn_id = conn->id;
      connection_states[i].dptr = NULL;
      xtcp_set_connection_appstate(
           tcp_svr, 
           conn, 
           (xtcp_appstate_t) &connection_states[i]);
    }
}


// Free a connection slot, for a finished connection
void httpd_free_state(xtcp_connection_t *conn)
{
  int i;
  
  for ( i = 0; i < NUM_HTTPD_CONNECTIONS; i++ )
    {
      if (connection_states[i].conn_id == conn->id)
        {
          connection_states[i].active = 0;
        }
    }
}
////


// HTTP event handler
void httpd_handle_event(chanend tcp_svr, xtcp_connection_t *conn)
{
  // We have received an event from the TCP stack, so respond 
  // appropriately

  // Ignore events that are not directly relevant to http
  switch (conn->event) 
    {
    case XTCP_IFUP:
    case XTCP_IFDOWN:
    case XTCP_ALREADY_HANDLED:
      return;
    default:
      break;
    }

  // Check if the connection is a http connection
  if (conn->local_port == 80) {
    switch (conn->event)
      {
      case XTCP_NEW_CONNECTION:
        httpd_init_state(tcp_svr, conn);
        break;          
      case XTCP_RECV_DATA:
        httpd_recv(tcp_svr, conn);
        break;        
      case XTCP_SENT_DATA:        
      case XTCP_REQUEST_DATA:
      case XTCP_RESEND_DATA:
          httpd_send(tcp_svr, conn);
          break;         
      case XTCP_TIMED_OUT:
      case XTCP_ABORTED:
      case XTCP_CLOSED:
          httpd_free_state(conn);
          break;
      default:
        // Ignore anything else
        break;
      }
    conn->event = XTCP_ALREADY_HANDLED;
  }
  ////
  return;
}
////
