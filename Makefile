
appname      := demo

PREFIX       := /usr
HEADERINST   := $(PREFIX)/include/cppgpio
CHEADERINST  := $(PREFIX)/include
LIBINST      := $(PREFIX)/lib

LIBTOOL      := ar rucs
MKDIR        := mkdir -p
CP           := cp
CD           := cd
CHOWN	     := chown
CHMOD        := chmod
LN           := ln -sf
RM           := rm -f
RMDIR        := rm -rf
MAKE         := make

sourcepref   := src
includepref  := include
headerpref   := include/cppgpio
SRCS         := $(shell find $(sourcepref) -maxdepth 1 -name "*.cpp")
SRCS         := $(SRCS:./%=%)
HDRS         := $(shell find $(headerpref) -maxdepth 1 -name "*.hpp")
HDRS         := $(HDRS:./%=%)
relheaderfiles:= $(HDRS:$(headerpref)/%=%)
cnvheader    := cppgpio.hpp
OBJS         := $(SRCS:.cpp=.o)
libname      := cppgpio
libnamea     := lib$(libname).a
libnameso    := lib$(libname).so
libnamesover := $(libnameso).1
libnamesoverx:= $(libnameso).1.0.0

CXX          := g++
CXXFLAGS     := -Wall -O2 -fPIC -std=gnu++14 -pthread -I $(includepref)
LDFLAGS      :=
LDLIBS       := -lpthread -lcppgpio

SUBDIRS      := $(sourcepref)

MAKE_SUBDIRS = for subdir in $(SUBDIRS); do \
                    (cd $$subdir && $(MAKE) $@); \
                    if [ $$? -ne 0 ]; then \
                        exit -1; \
                    fi; \
                done


all: lib


.PHONY: all lib depend clean dist-clean install uninstall


lib:
	+@$(MAKE_SUBDIRS)
	$(LIBTOOL) $(libnamea) $(OBJS)
	$(CXX) -shared -Wl,-soname,$(libnameso) -o $(libnamesoverx) $(OBJS)

$(appname): demo.o
	$(CXX) $(CXXFLAGS) $(LDFLAGS) -o $(appname) demo.o $(LDLIBS)

clean:
	+@$(MAKE_SUBDIRS)
	$(RM) demo.o demo

depend: .depend
	+@$(MAKE_SUBDIRS)

.depend: demo.cpp
	$(RM) ./.depend
	$(CXX) $(CXXFLAGS) -MM $^ >> ./.depend;
	
dist-clean: clean uninstall
	+@$(MAKE_SUBDIRS)
	$(RM) *~ .depend

install: uninstall
	$(MKDIR) $(CHEADERINST)
	$(CP) $(includepref)/$(cnvheader) $(CHEADERINST)
	$(CHOWN) root:root $(CHEADERINST)/$(cnvheader)
	$(CHMOD) 0644 $(CHEADERINST)/$(cnvheader)
	$(MKDIR) $(HEADERINST)
	$(CP) $(HDRS) $(HEADERINST)
	$(CD) $(HEADERINST) && $(CHOWN) root:root $(relheaderfiles)
	$(CD) $(HEADERINST) && $(CHMOD) 0644 $(relheaderfiles)
	$(MKDIR) $(LIBINST)
	$(CP) $(libnamea) $(LIBINST)
	$(CD) $(LIBINST) && $(CHOWN) root:root $(libnamea)
	$(CD) $(LIBINST) && $(CHMOD) 0755 $(libnamea)
	$(CP) $(libnamesoverx) $(LIBINST)
	$(CD) $(LIBINST) && $(CHOWN) root:root $(libnamesoverx)
	$(CD) $(LIBINST) && $(CHMOD) 0755 $(libnamesoverx)
	$(CD) $(LIBINST) && $(LN) $(libnamesoverx) $(libnamesover)
	$(CD) $(LIBINST) && $(LN) $(libnamesover) $(libnameso)

uninstall:
	$(CD) $(CHEADERINST) && $(RM) $(cnvheader)
	$(CD) $(HEADERINST) && $(RM) $(relheaderfiles)
	$(CD) $(LIBINST) && $(RM) $(libnamea)
	$(CD) $(LIBINST) && $(RM) $(libnamesoverx)
	$(CD) $(LIBINST) && $(RM) $(libnamesover)
	$(CD) $(LIBINST) && $(RM) $(libnameso)

-include .depend
