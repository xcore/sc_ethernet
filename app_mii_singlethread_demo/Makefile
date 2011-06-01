# The TARGET variable determines what target system the application is 
# compiled for. It either refers to an XN file in the source directories
# or a valid argument for the --target option when compiling.

TARGET = XC-2

# The APP_NAME variable determines the name of the final .xe file. It should
# not include the .xe postfix. If left blank the name will default to 
# the project name

APP_NAME = app_mii_singlethread_dmeo

# The flags passed to xcc when building the application
# You can also set the following to override flags for a particular language:
#
#    XCC_XC_FLAGS, XCC_C_FLAGS, XCC_ASM_FLAGS, XCC_CPP_FLAGS
#
# If the variable XCC_MAP_FLAGS is set it overrides the flags passed to 
# xcc for the final link (mapping) stage.

XCC_FLAGS = -g 

# The USED_MODULES variable lists other module used by the application. 

USED_MODULES = module_mii_singlethread

#=============================================================================
# The following part of the Makefile includes the common build infrastructure
# for compiling XMOS applications. You should not need to edit below here.


# Use the latest 1v* version of module_xmos_common
-include ../module_xcommon/build/Makefile.common
-include ../../xcommon/module_xcommon/build/Makefile.common

# The final target of the build. This is usually dependent on a binary file
# in the $(BIN_DIR) directory e.g.
#
#  all : $(BIN_DIR)/my_app.xe

all: $(BIN_DIR)/$(APP_NAME).xe
	@echo Build Complete


clean: clean_common
