Received data
-------------



======== ============
INTS     CONTENTS
======== ============
1 (HEADER FOR FREEPTR)
1 (HEADER FOR FREEPTR)
1 TIMESTAMP
L DATA
1 LASTDATAWORD
1 TAILBITS
1 PART CRC
======== ============

XC interrupt function translates this into


======== ============
INTS     CONTENTS
======== ============
1        LENGTH BYTES    <- done in second part of interrupt (commit)
1        FULL            <- done in second part of interrupt (commit)
1        TIMESTAMP
(LB+3)/4 DATA            <- done in middle part of interrupt (CRC computation)
======== ============



Interrupt
---------


   Read NEXTBUF
   If NOBUF
      Recycle current buffer and return.
   else
      Pass NEXTBUF to MII layer
   Compute CRC and filter etc on lastbuf, and repair data tail //   IN XC from here
   If accept then
                                                          // commit
      Fill in data so that user level can use lastbuf.
      mark lastbuf as FULL
      lastbuf := NEXTBUF
      WR := WR + length
      if WR + 1500 > BUFLENGHT
         mark remainder as "USELESS TAIL"
         WR = 0;
      fi
      if WR - FREEPTR > 1500 then
         NEXTBUF = NOBUF;
      else 
         NEXTBUF = WR
   else
      keep NEXTBUF as is because data is useless
      lastbuf := NEXTBUF




USer thread
-----------


On release:

    Mark as FREE
    while FREEPTR does not point to FULL  
       If FREE
           Advance FREEPTR
       If USELESS TAIL
           FREEPTR = 0
        
