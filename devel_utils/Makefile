.PHONY : all clean

CC=gcc
COMPFLAGS=-O2 -g -ansi -W -Wstrict-prototypes -Wshadow -Wmissing-declarations -Wmissing-prototypes -fomit-frame-pointer

# list of applications
APPS=luna lupo lld relate chkobj chklib mksfxpkg

all : $(APPS)
	@echo Make development tools

clean :
	@-rm -f $(APPS)

$(APPS) : Makefile

# Rules
% : %.c
	@echo "CC      " $<
	@$(CC) $< -o $@ $(COMPFLAGS)
