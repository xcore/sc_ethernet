TARGET = xp-skc-l2-single
APP_NAME = 
XCC_FLAGS = -g -O2 -DSMI_MDC_BIT=1 -DSMI_MDIO_BIT=0
USED_MODULES = module_ethernet_smi

# This change to the module path is so that this application can be in the
# tests sub-directory in it's git repo
ifeq ($(notdir $(abspath ..)),tests)
PATHSEP = $(if $(findstring Windows, $(OS))$(findstring WINDOWS,$(OS)),;,:)
XMOS_MODULE_PATH := $(XMOS_MODULE_PATH)$(PATHSEP)../../..
endif



#=============================================================================
# The following part of the Makefile includes the common build infrastructure
# for compiling XMOS applications. You should not need to edit below here.

XMOS_MAKE_PATH ?= ../..
include $(XMOS_MAKE_PATH)/xcommon/module_xcommon/build/Makefile.common
