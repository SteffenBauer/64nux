.PHONY : all clean

VPATH=../include

# list of applications
APPS=hello memmap ed charmap memory taskinfo dynamic

# list of applications that must be linked against libstd
LAPPS=

all : $(APPS) $(LAPPS)

# Rules

% : %.s
	@echo "LUNARAW " $<
	@luna -qWR $< -o $@ $(COMPFLAGS)
%.o : %.s
	@echo "LUNAOBJ " $<
	@luna -qWO $< -o $@ $(COMPFLAGS)

$(LAPPS) : $(LAPPS:%=%.o)
	@echo "LLD     " $@
	@lld -qN $@.o -o $@

# additional dependencies
$(APPS) : system.h jumptab.h stdio.h

$(LAPPS) : system.h rs232.h jumptab.h stdio.h ../lib/libstd.a

clean   : 
	@-rm -f $(APPS) $(LAPPS) $(LAPPS:%=%.o)

