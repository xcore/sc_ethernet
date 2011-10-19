all: bin/tester

clean: 

test: bin/tester
	bin/tester "$(TFLAG) ../app_mii_singlethread_demo/bin/Release/app_mii_singlethread_demo.xe"

bin/tester: src/stimulus.c
	if [ ! -d bin ]; then mkdir bin; fi
	cc -o bin/tester -std=c99 -m32 -I $(installpath)/include src/stimulus.c $(installpath)/lib/libxsidevice.so 