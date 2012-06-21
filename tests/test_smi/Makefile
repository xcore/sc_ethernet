TARGET = xp-skc-l2-single
APP_NAME = 
XCC_FLAGS = -g -O2 -DSMI_MDC_BIT=1 -DSMI_MDIO_BIT=0
USED_MODULES = module_ethernet_smi

ifeq ($(notdir $(abspath ..)),tests)
XMOS_MODULE_PATH += ../../..
endif


#=============================================================================
# The following part of the Makefile includes the common build infrastructure
# for compiling XMOS applications. You should not need to edit below here.

XMOS_MAKE_PATH ?= ../..
include $(XMOS_MAKE_PATH)/xcommon/module_xcommon/build/Makefile.common
