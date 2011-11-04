LONG=68 69 70 71
SHORT=64 65 66 67
HOST=$(SHORT)
DEV=$(SHORT)

APP=app_mii_singlethread_regr
BIN=../$(APP)/bin/$(APP).xe

all:

clean: 

test: bin/tester $(BIN)
	for i in $(DEV); do \
	for j in $(HOST); do \
	bin/tester "$(TFLAG) " $$i $$j; done; done
	for i in $(SHORT); do \
	for j in $(LONG); do \
	bin/tester "$(TFLAG) $(BIN)" $$i $$j; \
	bin/tester "$(TFLAG) $(BIN)" $$j $$i; \
    done; done

visualise: bin/tester $(BIN)
	for i in $(DEV); do \
	for j in $(HOST); do \
	bin/tester "$(TFLAG) $(BIN)" $$i $$j |\
         ./render.sh ; done; done
	for i in $(SHORT); do \
	for j in $(LONG); do \
	bin/tester "$(TFLAG) $(BIN)" $$i $$j |\
         ./render.sh; \
	bin/tester "$(TFLAG) $(BIN)" $$j $$i |\
         ./render.sh; \
    done; done

$(BIN):
	(cd ../$APP; make all)
bin/tester: src/stimulus.c
	if [ ! -d bin ]; then mkdir bin; fi
	cc -o bin/tester -std=c99 -m32 -I $(installpath)/include src/stimulus.c $(installpath)/lib/libxsidevice.so 
