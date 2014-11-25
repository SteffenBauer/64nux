.PHONY : all clean

VPATH=../include

# list of applications
APPS=testapp microterm ps lsmod sh wc getty sleep cat tee uuencode uudecode \
     232echo 232term sliptst telnet kill rm ls connd ftp buf cp tcpipstat \
     meminfo strminfo uptime time uname more loop slip ppp tcpip help \
     b-cs b-co env beep httpd clear popclient true false echo touch cd \
     expand pwd

# list of applications that must be linked against libstd
LAPPS=amalloc date ciartc hextype smwrtc dcf77 ide64rtc

all : $(APPS) $(LAPPS)
	@echo Make application tools

# Rules

% : %.s
	@echo "LUNARAW " $<
	@luna -qWR $< -o $@ $(COMPFLAGS)
%.o : %.s
	@echo "LUNAOBJ @ $<
	@luna -qWO $< -o $@ $(COMPFLAGS)

%.o65 : %.ca65.s
# These are allowed to fail because cc65 package may not be present
	-lupo -dUSING_CA65=1 $< -o $@.s
	-ca65 -t lunix $@.s
	-ld65 -t lunix -o $@ $@.o

$(LAPPS) : $(LAPPS:%=%.o)
	@echo "LLD     " $@
	@lld -qN $@.o -o $@

# additional dependencies
$(APPS) : system.h rs232.h jumptab.h stdio.h

$(LAPPS) : system.h rs232.h jumptab.h stdio.h ../lib/libstd.a

clean   : 
	@-rm -f $(APPS) $(LAPPS) $(LAPPS:%=%.o) *.o65*

