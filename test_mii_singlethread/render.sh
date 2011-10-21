#!/bin/sh


fgrep '@0' |\
awk '
BEGIN {
  WIDTH=1300
  first = 1;
  lines = 0;
}
/LINES/ {
  WIDTH = $2; LINES = $3;
  next;
}
/FILE/ {
  FILE = $2;
  print "P3\n" WIDTH " " (3*LINES)"\n255\n" > FILE
  next;
}
/ERROR/ {
  print $0;
}
{
  t = (substr($NF, 2, length($NF))) / 5;
  t = int(t);  
  if (t == ot) next;
  while (t > ot + 1) {
    ot++;
    if(0) print ot " -";
  if (first && ot >= 6000) {
    inputList = "";
    outputList = "";
      inputInstr = " 0 0 0"
      outputInstr = " 0 0 0"
    betweenList = "";
    count = 0;
    first = 0;
  }
    if (!first) {
      inputList = inputList inputInstr
      outputList = outputList outputInstr
      betweenList = betweenList " 99 99 99"
      inputInstr = " 0 0 0"
      outputInstr = " 0 0 0"
      count++;
      if (count == WIDTH) {
        if (lines < LINES) {
          print inputList >> FILE
          print outputList >> FILE
          print betweenList >> FILE
        }
        inputList = "";
        outputList = "";
        betweenList = "";
        count = 0;
        lines++;
      }
    }
  }
  ot = t;
  thread = substr($0, 16, 1);
  special = "";
  if ($3 == "(mii_rxd_preamble" && $5 == "0)") {
    special = special " IN";
  } else {
    special = special "   ";
  }
  if ($3 == "(outIdle" && $5 == "a)") {
    special = special " OUT";
    lastdata = t;
  } else {
    special = special "    ";
  }
  isOUT = ($7 == "out" || $7 == "outpw") && thread != "I";
  if (isOUT) {
    special = special " data " ((t - lastdata)*2) " " $7;
    lastdata = t;
  }
  if (0)  print t " " thread special
  if (first) {
    next;
  }
  if (thread == "e" || thread == "I") {
    inputInstr = " 255 0 0"
  } else {
    inputInstr = " 0 0 0"
  }
  inputList = inputList inputInstr
  if (isOUT) {
    outputInstr = " 70 70 255"
  } else if (thread == "A" || thread == "T") {
    outputInstr = " 0 255 0"
  } else {
    outputInstr = " 0 0 0"
  }
  outputList = outputList outputInstr
  betweenList = betweenList " 99 99 99"
  count++;
  if (count == WIDTH) {
    if (lines < LINES) {
      print inputList >> FILE
      print outputList >> FILE
      print betweenList >> FILE
    }
    inputList = "";
    outputList = "";
    betweenList = "";
    count = 0;
    lines++;
  }
}

'