SOURCE = main.xc getmac.xc
FLAGS = -Wall -g -O3 -I.. -I../../shared -report -target=XC-2

ifeq "$(OS)" "Windows_NT"
DELETE = del
else
DELETE = rm -f
endif

read_mac.xe: ${SOURCE}
	xcc ${FLAGS} ${SOURCE} -o read_mac.xe

clean:
	$(DELETE) *.o *.a *.xi *.s *.xe *.xb


#=============================================================================
# The following part of the Makefile includes the common build infrastructure
# for compiling XMOS applications. You should not need to edit below here.

XMOS_MAKE_PATH ?= ../..
include $(XMOS_MAKE_PATH)/xcommon/module_xcommon/build/Makefile.common
