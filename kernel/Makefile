include ../kconfig/.config
include ../config.mk

ifeq ($(ARCH_STM32F4),y)
ifeq ($(CLK_48MHZ),y)
	CFLAGS+=-DCLK_SPEED=48
endif
ifeq ($(CLK_96MHZ),y)
	CFLAGS+=-DCLK_SPEED=96
endif
ifeq ($(CLK_168MHZ),y)
	CFLAGS+=-DCLK_SPEED=168
endif
endif

CROSS_COMPILE?=arm-none-eabi-
CC:=$(CROSS_COMPILE)gcc
AS:=$(CROSS_COMPILE)as
AR:=$(CROSS_COMPILE)ar
LIBNAME:=libkernel.a
PREFIX:=$(PWD)/build
#Target flags
CFLAGS+=-mthumb -mlittle-endian -mthumb-interwork
CFLAGS+=-DCORE_M3 -DBOARD_$(CHIP)
CFLAGS+=-DKLOG_LEVEL=6
CFLAGS+=-DCONFIG_KMEM_SIZE=$(KMEM_SIZE)
#Include paths
CFLAGS+=-I. -I../include -Ihal -I..
#Freestanding options
CFLAGS+=-fno-builtin
CFLAGS+=-ffreestanding
CFLAGS+=-nostdlib
#Debugging
CFLAGS+=-ggdb
#CFLAGS+=-Os

ASFLAGS:=-mcpu=cortex-m3 -mthumb -mlittle-endian -mthumb-interwork -ggdb


OBJS-y:=  hal/cpu/$(CPU).o hal/arch/$(CHIP)/$(CHIP).o hal/tools.o
OBJS-y+= \
	hal/startup.o			\
	svc.o				\
	frosted.o			\
	string.o			\
	sys.o				\
	systick.o			\
	syscall.o			\
	locks.o				\
	semaphore.o			\
	mutex.o				\
	tasklet.o			\
	scheduler.o			\
	syscall_table.o		\
	malloc.o			\
	module.o			\
	poll.o				\
	cirbuf.o			\
	timer.o
OBJS-y += vfs.o
OBJS-y += syscall_vector.o

CFLAGS+=$(CFLAGS-y)


all: hal/regs.h syscall_table.h $(OBJS-y)
	@echo -e "\t[AR] $(PREFIX)/lib/$(LIBNAME)"
	@mkdir -p $(PREFIX)/lib
	$(AR) cr $(PREFIX)/lib/$(LIBNAME) $(OBJS-y)

syscall_table.c: syscall_table_gen.py
	python2 $^

hal/regs.h: 
	./hal/def_reg.py hal/cpu/$(CPU).def hal/arch/$(CHIP)/$(CHIP).def

hal/startup.c:
	./hal/def_irq.py hal/cpu/$(CPU)_irq.def hal/arch/$(CHIP)/$(CHIP)_irq.def


syscall_table.h: syscall_table.c

clean:
	@rm -f hal/regs.c hal/regs.h hal/startup.c
	@rm -f $(OBJS-y)
	@rm -f $(PREFIX)/lib/$(LIBNAME)

