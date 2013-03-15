// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>
#include <xs1.h>
#include <stdio.h>
#include <platform.h>
#include "smi.h"

/*
 * Test expects an XA-SK_E100 slice in zero or more ports, it then sets up the
 * SMI on any connected and reports all register once set up.
 */

on tile[0]: smi_interface_t smi0 = { 0x80000000, XS1_PORT_8A, XS1_PORT_4C };
on tile[0]: smi_interface_t smi1 = { 0, XS1_PORT_1M, XS1_PORT_1N };
on tile[1]: smi_interface_t smi2 = { 0x80000000, XS1_PORT_8A, XS1_PORT_4C };
on tile[1]: smi_interface_t smi3 = { 0, XS1_PORT_1M, XS1_PORT_1N };

void smiTest(smi_interface_t &smi) {

  smi_init(smi);

  if(!smi_reg(smi, 0, 0, 1)){
    printf("Not Connected\n");
    return;
  }

  printf("Physical Address: %06x\n", eth_phy_id(smi));
  printf("Basic Control Register: %04x\n", smi_reg(smi, 0, 0, 1));
  printf("Basic Status Register: %04x\n", smi_reg(smi, 1, 0, 1));
  printf("PHY Identifier 1: %04x\n", smi_reg(smi, 2, 0, 1));
  printf("PHY Identifier 2: %04x\n", smi_reg(smi, 3, 0, 1));
  printf("Auto-Negotiation Advertisement Register: %04x\n", smi_reg(smi, 4, 0, 1));
  printf("Auto-Negotiation Link Partner Ability Register: %04x\n", smi_reg(smi, 5, 0, 1));
  printf("Auto-Negotiation Expansion Register: %04x\n", smi_reg(smi, 6, 0, 1));
  printf("Silicon Revision Register: %04x\n", smi_reg(smi, 16, 0, 1));
  printf("Mode Control/Status Register: %04x\n", smi_reg(smi, 17, 0, 1));
  printf("Special Modes: %04x\n", smi_reg(smi, 18, 0, 1));
  printf("Symbol Error Counter Register: %04x\n", smi_reg(smi, 26, 0, 1));
  printf("Control / Status Indication Register: %04x\n", smi_reg(smi, 27, 0, 1));
  printf("Special internal testability controls: %04x\n", smi_reg(smi, 28, 0, 1));
  printf("Interrupt Source Register: %04x\n", smi_reg(smi, 29, 0, 1));
  printf("Interrupt Mask Register: %04x\n", smi_reg(smi, 30, 0, 1));
  printf("PHY Special Control/Status Register: %04x\n", smi_reg(smi, 31, 0, 1));
}

int main() {
  chan c;
  par {
    on tile[0]: {
      printf("SMI Star\n");
      smiTest(smi0);
      printf("\nSMI Triangle\n");
      smiTest(smi1);
      c<:0;
    }
    on tile[1]: {
      c:> int;
      printf("\nSMI Square\n");
      smiTest(smi2);
      printf("\nSMI Circle\n");
      smiTest(smi3);
    }
    on tile[0]: par (int i = 0; i < 7; i++) while (1);
    on tile[1]: par (int i = 0; i < 7; i++) while (1);
  }
  return 0;
}
