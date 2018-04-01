# Install Configuration

PREFIX=/usr/local



# Versioning
VERSION_MAJOR = 0
VERSION_MINOR = 2
VERSION_SUFFIX = dev
VERSION = $(VERSION_MAJOR).$(VERSION_MINOR)-$(VERSION_SUFFIX)

# If we're working from git, we have access to proper variables. If
# not, make it clear that we're working from a release.
GIT_DIR ?= .git
ifneq ($(and $(wildcard $(GIT_DIR)),$(shell which git)),)
        GIT_BRANCH = $(shell git rev-parse --abbrev-ref HEAD)
        GIT_HASH = $(shell git rev-parse HEAD)
        GIT_HASH_SHORT = $(shell git rev-parse --short HEAD)
        GIT_TAG = $(shell git describe --abbrev=0 --tags)
else
        GIT_BRANCH = none
        GIT_HASH = none
        GIT_HASH_SHORT = none
        GIT_TAG = none
endif
BUILD_DATE_TIME = $(shell date +%Y%m%d.%k%M%S | sed s/\ //g)
VERSION_INFO = version.h

COMMON_OBJECTS=byte_utils.o database.o minipro.o fuses.o easyconfig.o
OBJECTS=$(COMMON_OBJECTS) main.o minipro-query-db.o
PROGS=minipro minipro-query-db
MINIPRO=minipro
MINIPRO_QUERY_DB=minipro-query-db
MINIPROHEX=miniprohex
TESTS=$(wildcard tests/test_*.c);
OBJCOPY=objcopy

DIST_DIR = $(MINIPRO)-$(VERSION)
BIN_INSTDIR=$(DESTDIR)$(PREFIX)/bin
MAN_INSTDIR=$(DESTDIR)$(PREFIX)/share/man/man1

libusb_CFLAGS = $(shell pkg-config --cflags libusb-1.0)
libusb_LIBS = $(shell pkg-config --libs libusb-1.0)

CFLAGS = -g -O0
override CFLAGS += $(libusb_CFLAGS)
override LIBS += $(libusb_LIBS)

all: $(PROGS)

version-info: $(VERSION_INFO)
$(VERSION_INFO):
	@echo "Creating $@"
	@echo "#define GIT_BRANCH \"$(GIT_BRANCH)\"" > $@
	@echo "#define GIT_HASH \"$(GIT_HASH)\"" >> $@
	@echo "#define GIT_HASH_SHORT \"$(GIT_HASH_SHORT)\"" >> $@
	@echo "#define GIT_TAG \"$(GIT_TAG)\"" >> $@
	@echo "#define VERSION \"$(VERSION)\""  >> $@
	@echo "#define VERSION_MAJOR \"$(VERSION_MAJOR)\""  >> $@
	@echo "#define VERSION_MINOR \"$(VERSION_MINOR)\""  >> $@
	@echo "#define VERSION_SUFFIX \"$(VERSION_SUFFIX)\""  >> $@

minipro: version-info $(COMMON_OBJECTS) main.o
	$(CC) $(COMMON_OBJECTS) main.o $(LIBS) -o $(MINIPRO)

minipro-query-db: version-info $(COMMON_OBJECTS) minipro-query-db.o
	$(CC) $(COMMON_OBJECTS) minipro-query-db.o $(LIBS) -o $(MINIPRO_QUERY_DB)

clean:
	rm -f $(OBJECTS) $(PROGS)
	rm -f version.h

distclean: clean
	rm -rf minipro-$(VERSION)*

install:
	mkdir -p $(BIN_INSTDIR)
	mkdir -p $(MAN_INSTDIR)
	cp $(MINIPRO) $(BIN_INSTDIR)/
	cp $(MINIPRO_QUERY_DB) $(BIN_INSTDIR)/
	cp $(MINIPROHEX) $(BIN_INSTDIR)/
	cp man/minipro.1 $(MAN_INSTDIR)/

uninstall:
	rm -f $(BIN_INSTDIR)/$(MINIPRO)
	rm -f $(BIN_INSTDIR)/$(MINIPRO_QUERY_DB)
	rm -f $(BIN_INSTDIR)/$(MINIPROHEX)
	rm -f $(MAN_INSTDIR)/minipro.1

dist: distclean version-info
	git archive --format=tar --prefix=minipro-$(VERSION)/ -o "minipro-$(VERSION).tar" HEAD
	tar -xf minipro-$(VERSION).tar
	sed -i '/rm -f version.h/s/^/#/g' minipro-$(VERSION)/Makefile
	sed -i "s/GIT_BRANCH = none/GIT_BRANCH = $(GIT_BRANCH)/" minipro-$(VERSION)/Makefile
	sed -i "s/GIT_HASH = none/GIT_HASH = $(GIT_HASH)/" minipro-$(VERSION)/Makefile
	sed -i "s/GIT_HASH_SHORT = none/GIT_HASH_SHORT = $(GIT_HASH_SHORT)/" minipro-$(VERSION)/Makefile
	sed -i "s/GIT_TAG = none/GIT_TAG = $(GIT_TAG)/" minipro-$(VERSION)/Makefile

	cp -f $(VERSION_INFO) minipro-$(VERSION)
	tar zcf minipro-$(VERSION).tar.gz minipro-$(VERSION)
	rm -rf minipro-$(VERSION)
	rm -f minipro-$(VERSION).tar
	@echo Created minipro-$(VERSION).tar.gz


.PHONY: all dist distclean clean install test version-info
