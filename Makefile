# This variable should contain a space separated list of all
# the directories containing buildable applications (usually
# prefixed with the app_ prefix)
#
# If the variable is set to "all" then all directories that start with app_
# are built.
BUILD_SUBDIRS = app_ethernet_demo app_ethernet_loopback app_bridge \
	app_mii_singlethread_regr
#	app_mii_singlethread_demo \
#	test_mii_singlethread \
#	app_mii_singleavb_demo

XMOS_MAKE_PATH ?= ..
include $(XMOS_MAKE_PATH)/xcommon/module_xcommon/build/Makefile.toplevel
