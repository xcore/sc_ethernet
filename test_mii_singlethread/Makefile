LONG=68 69 70 71
SHORT=64 65 66 67
HOST=$(SHORT)
DEV=$(SHORT)

all:

clean: 

test: bin/tester
	for i in $(DEV); do \
	for j in $(HOST); do \
	bin/tester "$(TFLAG) ../app_mii_singlethread_demo/bin/Release/app_mii_singlethread_demo.xe" $$i $$j; done; done
	for i in $(SHORT); do \
	for j in $(LONG); do \
	bin/tester "$(TFLAG) ../app_mii_singlethread_demo/bin/Release/app_mii_singlethread_demo.xe" $$i $$j; \
	bin/tester "$(TFLAG) ../app_mii_singlethread_demo/bin/Release/app_mii_singlethread_demo.xe" $$j $$i; \
    done; done

visualise: bin/tester
	for i in $(DEV); do \
	for j in $(HOST); do \
	bin/tester "$(TFLAG) ../app_mii_singlethread_demo/bin/Release/app_mii_singlethread_demo.xe" $$i $$j |\
         ./render.sh ; done; done
	for i in $(SHORT); do \
	for j in $(LONG); do \
	bin/tester "$(TFLAG) ../app_mii_singlethread_demo/bin/Release/app_mii_singlethread_demo.xe" $$i $$j |\
         ./render.sh; \
	bin/tester "$(TFLAG) ../app_mii_singlethread_demo/bin/Release/app_mii_singlethread_demo.xe" $$j $$i |\
         ./render.sh; \
    done; done

bin/tester: src/stimulus.c
	if [ ! -d bin ]; then mkdir bin; fi
	cc -o bin/tester -std=c99 -m32 -I $(installpath)/include src/stimulus.c $(installpath)/lib/libxsidevice.so 
