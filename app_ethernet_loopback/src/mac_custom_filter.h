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
