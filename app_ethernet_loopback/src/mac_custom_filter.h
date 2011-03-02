// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

/* Listen to broadcast frames */
unsigned int mac_custom_filter(unsigned int data[]) 
{
	for (int i=0;i<6;i++){
          if ((data,char[])[i] != 0xFF){
            return 0;
          }
	}

	return 1;
}
