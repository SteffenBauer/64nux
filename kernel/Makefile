# -*- make -*-

# List of modules
    MODULES=$(addprefix modules/,sswiftlink sfifo64 rs232std swiftlink fifo64)

#============== end of configurable section ============================

.PHONY : all modules clean distclean

export LUPO_INCLUDEPATH=../include
VPATH=$(LUPO_INCLUDEPATH)

KINCLUDES=config.h $(MACHINE).h system.h kerrors.h \
	ikernel.h keyboard.h debug.h zp.h

BINCLUDES=ksym.h $(KINCLUDES)

KERNEL=lunix.$(MACHINE)
BOOT=boot.$(MACHINE)

# List of objects (for "lunix.*")
OBJ=init.o delay.o hook.o keyboard.o lock.o panic.o \
    nmi.o console.o error.o \
    taskctrl.o environment.o \
    fs.o mm.o \
    kfunc_tab.o module.o misc.o

#    fs.o fs_pipe.o fs_iec.o fs_ide64.o fs_cons.o fs_user.o fs_sys.o \
#    imemory.o addtask.o taskctrl.o signal.o smb.o environment.o \
#    reloc.o kfunc_tab.o execute.o module.o misc.o

# Boot-loader objects (for "boot.*")
BOOTOBJ=bootstrap.o calib.o

all : $(KERNEL) $(BOOT) modules lng_kfunc.txt
	@:

# Rules
%.o : %.s
	@echo "LUNAOBJ " $<
	@luna -qOo $@ $< $(COMPFLAGS)
%   : %.s
	@echo "LUNARAW " $<
	@luna -qRo $@ $< $(COMPFLAGS)

# Additional dependencies
$(OBJ)	    : $(KINCLUDES) Makefile
$(BOOTOBJ)  : $(BINCLUDES) Makefile
$(MODULES)  : system.h stdio.h jumptab.h Makefile
console.o   : opt/*_console*.s
fs.o        : fs/*.s
mm.o        : mm/*.s
taskctrl.0  : taskctrl/*.s
keyboard.o  : $(MACHINE)/keyboard.s
bootstrap.o : $(MACHINE)/reset.s $(MACHINE)/irqinit.s $(MACHINE)/reboot.s \
	      $(MACHINE)/initmemmap.s $(MACHINE)/keyboard_init.s \
	      opt/*_console*_init.s

# Copy configuration file.
../include/config.h : $(MACHINE)/config.h
	@echo Using configuration $<
	@cp $< $@

# Jump-table header file
../include/jumptab.h : kfunc_tab.s
	@echo "MKJMPTAB"
	@mkjumptab_h

# zp.h : $(OBJ:o=s) ../include/config.h
# The above would be correct, but would trigger a total rebuild,
# on every small code-change.
../include/zp.h : $(OBJ:o=s) ../include/config.h
	@echo "MKZP"
	@mkzp_h $(OBJ:o=s)

# Final step of creating the kernel (linking all objects)
$(KERNEL) : $(OBJ)
	@echo "LLD     " $@
	@lld -d globals.txt -o $@ -s 8192 $^

# Collect kernel symbols (needed by boot loader).
../include/ksym.h : $(KERNEL) globals.txt
	@echo "MKSYM"
	@mksym

# Final step of creating the boot loader (linking all objects)

ifeq "$(MACHINE)" "c64"
 START_ADDRESS=4096
# START_ADDRESS=8192
endif
ifeq "$(MACHINE)" "c128"
 START_ADDRESS=4864
endif
ifeq "$(MACHINE)" "atari"
 START_ADDRESS=20480
endif

$(BOOT) : $(BOOTOBJ)
	@echo "LLD     " $@
	@lld -o $@ -s $(START_ADDRESS) $^

modules : $(MODULES)

lng_kfunc.txt : *.s
	@echo "RELATE"
	@relate $+ > $@

clean :
	@$(RM) *.o

distclean : clean
	@$(RM) ../include/config.h ../include/zp.h ../include/jumptab.h \
	  ../include/ksym.h lunix.c* boot.c* lunix.atari boot.atari $(MODULES) \
	  globals.txt lng_kfunc.txt
