# The TARGET variable determines what target system the application is 
# compiled for. It either refers to an XN file in the source directories
# or a valid argument for the --target option when compiling.

TARGET = XP-DSC-BLDC

APP_NAME =

XCC_FLAGS = -O3 -g -report -save-temps

USED_MODULES = module_xtcp.2v0 module_mii_singlethread \
               module_mii_singlethread_server

# This uses the tcp mac filtering in module_xtcp
USE_XTCP_MAC_CUSTOM_FILTER=1

#=============================================================================
# The following part of the Makefile includes the common build infrastructure
# for compiling XMOS applications. You should not need to edit below here.
-include ../module_xcommon/build/Makefile.common
-include ../../xcommon/module_xcommon/build/Makefile.common
