LONG=68 69 70 71
SHORT=64 65 66 67
HOST=$(SHORT)
DEV=$(SHORT)

//LONG=68
//SHORT=64
//HOST=
//DEV=
STEP=1
BIGSTEP=5

APP=app_mii_singlethread_regr
BIN=../$(APP)/bin/$(APP).xe

all:

clean: 

test: bin/tester
	(cd ../$(APP); make all)
	for i in $(DEV); do \
	 for j in $(HOST); do \
	  bin/tester "$(TFLAG) $(BIN)" $$i $$j $(STEP) 0; done; done
	for i in $(SHORT); do \
	 for j in $(LONG); do \
	  bin/tester "$(TFLAG) $(BIN)" $$i $$j $(STEP) 0; \
	  bin/tester "$(TFLAG) $(BIN)" $$j $$i $(STEP) 0; \
    done; done

visualise: bin/tester
	(cd ../$(APP); make all)
	for i in $(DEV); do \
	 for j in $(HOST); do \
	  bin/tester "-t $(BIN)" $$i $$j $(BIGSTEP) 1 | ./render.sh ; done; done
	for i in $(SHORT); do \
	 for j in $(LONG); do \
	  bin/tester "-t $(BIN)" $$i $$j $(BIGSTEP) 1 | ./render.sh; \
	  bin/tester "-t $(BIN)" $$j $$i $(BIGSTEP) 1 | ./render.sh; \
    done; done

bin/tester: src/stimulus.c
	if [ ! -d bin ]; then mkdir bin; fi
	cc -o bin/tester -std=c99 -m32 -I $(installpath)/include src/stimulus.c $(installpath)/lib/libxsidevice.so 
