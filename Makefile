# compile switches:
# =================
#  look into the machine specific config.h for details on compile switches.
#  (eg. kernel/c64/config.h)

COMPFLAGS=

# selection of target machine
# ===========================
#
# MACHINE=c64 to create Commodore64 version (binaries in bin64)
# MACHINE=c128 for Commodore128 version (binaries in bin128)
# MACHINE=atari for Atari 65XE/800/130 version (no binaries right now)

MACHINE=c64

# Modules to include in package (created with "make package")

MODULES=sswiftlink sfifo64 rs232std swiftlink fifo64
#MODULES=

# Applications to include in package
# the applications (in binary form) do not depend on the machine selection

APPS=getty lsmod microterm ps sh sleep testapp wc cat tee uuencode \
     uudecode 232echo 232term kill rm ls buf cp uptime time meminfo \
     strminfo uname more beep help env date ciartc dcf77 smwrtc \
     hextype clear true false echo touch expand \
     b-co b-cs ide64rtc cd pwd

MYAPPS=hello memmap ed charmap memory taskinfo dynamic

# Test Applications

TAPPS=amalloc

# Scripts

SAPPS=dir man hello.sh sysinfo sysinfo.sh

# Internet Applications
# will be put in the same package als APPS now, but may go into a
# seperate one, in case the APP-package grows to big

IAPPS=connd ftp tcpipstat tcpip ppp loop slip httpd telnet popclient

#============== end of configurable section ============================

.PHONY : all apps myapps kernel libstd help package clean distclean devel

export PATH+=:$(PWD)/devel_utils/:.
export LUPO_INCLUDEPATH=:$(PWD)/kernel:$(PWD)/include
export LNG_LIBRARIES=$(PWD)/lib/libstd.a
export COMPFLAGS
export MACHINE

BINDIR=$(patsubst c%,bin%,$(MACHINE))

all : kernel libstd apps help
	@:

apps : devel kernel libstd
	@$(MAKE) --no-print-directory -C apps

myapps : devel libstd
	@$(MAKE) --no-print-directory -C myapps

mydisc : myapps
	@echo Creating LUnix disc image with apps for $(MACHINE)
	@c1541 -format lunix,00 d64 lunix-myapps-$(MACHINE).d64 > /dev/null
	@cd myapps; for i in \
		$(MYAPPS) \
		; do c1541 -attach ../lunix-myapps-$(MACHINE).d64 -write $$i > /dev/null \
		; done

samples : devel libstd
	@-$(MAKE) --no-print-directory -C samples

kernel : devel kernel/$(MACHINE)/config.h
	@-rm ./include/config.h
	@$(MAKE) --no-print-directory -C kernel

libstd : devel
	@$(MAKE) --no-print-directory -C lib

help :
	@$(MAKE) --no-print-directory -C help

devel :
	@$(MAKE) --no-print-directory -C devel_utils

binaries: all
	@-mkdir -p $(BINDIR)
	@-cp kernel/boot.$(MACHINE) kernel/lunix.$(MACHINE) $(MODULES:%=kernel/modules/%) $(BINDIR)

cbmpackage : binaries
	@-mkdir -p pkg
	@cd $(BINDIR) ; mksfxpkg $(MACHINE) ../pkg/core.$(MACHINE) \
           "*loader" boot.$(MACHINE) lunix.$(MACHINE) $(MODULES)
	@cd apps ; mksfxpkg $(MACHINE) ../pkg/apps.$(MACHINE) $(APPS) $(IAPPS)
	@cd help ; mksfxpkg $(MACHINE) ../pkg/help.$(MACHINE) *.html
	@cd scripts ; mksfxpkg $(MACHINE) ../pkg/scripts.$(MACHINE) $(SAPPS)
	@echo "The following may fail"
	@-cd samples ; \
	 cp luna/skeleton . ; \
	 mksfxpkg $(MACHINE) ../pkg/samples.$(MACHINE) skeleton ; \
	 rm skeleton 

cbmdisc: binaries
	@echo Creating LUnix disc image for $(MACHINE)
	@c1541 -format lunix,00 d64 lunix-$(MACHINE).d64 > /dev/null

	@cd $(BINDIR); for i in \
		loader fasthead fastloader \
		boot.$(MACHINE) lunix.$(MACHINE) $(MODULES) \
		; do c1541 -attach ../lunix-$(MACHINE).d64 -write $$i > /dev/null \
		; done

	@cd kernel; for i in \
		lunixrc \
		; do c1541 -attach ../lunix-$(MACHINE).d64 -write $$i .$$i > /dev/null \
		; done

	@cd apps; for i in \
		$(APPS) $(IAPPS) $(TAPPS) \
		; do c1541 -attach ../lunix-$(MACHINE).d64 -write $$i > /dev/null \
		; done

	@cd help; for i in \
		*.html \
		; do c1541 -attach ../lunix-$(MACHINE).d64 -write $$i > /dev/null \
		; done

	@cd scripts; for i in \
		$(SAPPS) \
		; do c1541 -attach ../lunix-$(MACHINE).d64 -write $$i > /dev/null \
		; done

disc:	cbmdisc
package: cbmpackage

clean :
	@$(MAKE) --no-print-directory -C kernel clean

distclean : clean
	@$(MAKE) --no-print-directory -C kernel distclean
	@$(MAKE) --no-print-directory -C devel_utils clean
	@-cd kernel ; rm -f boot.c* lunix.c* globals.txt
	@-cd bin64 ; rm -f $(MODULES) boot.* lunix.* lng.c64
	@-cd include ; rm -f jumptab.h jumptab.ca65.h ksym.h zp.h
	@-rm -rf pkg
	@find . -name "*~" -exec rm -v \{\} \;
	@find . -name "#*" -exec rm -v \{\} \;
