SOURCE = mac.xc ../../tools_libotp/xs1b_l1/libotp_l1.a
FLAGS = -Wall -g -O3 -I../../tools_libotp -report -target=XC-2

ifeq "$(OS)" "Windows_NT"
DELETE = del
else
DELETE = rm -f
endif

write_mac.xe: ${SOURCE}
	xcc ${FLAGS} ${SOURCE} -o write_mac.xe

clean:
	$(DELETE) *.o *.a *.xi *.s *.xe *.xb
