-include kconfig/.config
-include config.mk

CROSS_COMPILE?=arm-none-eabi-
CC:=$(CROSS_COMPILE)gcc
AS:=$(CROSS_COMPILE)as
AR:=$(CROSS_COMPILE)ar

ifeq ($(FRESH),y)
	CFLAGS+=-DCONFIG_FRESH=1
endif

ifeq ($(PRODCONS),y)
	CFLAGS+=-DCONFIG_PRODCONS=1
endif



CFLAGS+=-mthumb -mlittle-endian -mthumb-interwork -Ikernel -DCORE_M3 -Iinclude -fno-builtin -ffreestanding -DKLOG_LEVEL=6
PREFIX:=$(PWD)/build
LDFLAGS:=-gc-sections -nostartfiles -ggdb -L$(PREFIX)/lib 

#debugging
CFLAGS+=-ggdb

#optimization
#CFLAGS+=-Os

ASFLAGS:=-mcpu=cortex-m3 -mthumb -mlittle-endian -mthumb-interwork -ggdb
APPS-y:= apps/init.o 
APPS-$(FRESH)+=apps/fresh.o


OBJS-y:=
CFLAGS-y:=-Ikernel/hal

# device drivers 
OBJS-$(MEMFS)+= kernel/drivers/memfs.o
CFLAGS-$(MEMFS)+=-DCONFIG_MEMFS

OBJS-$(SYSFS)+= kernel/drivers/sysfs.o
CFLAGS-$(SYSFS)+=-DCONFIG_SYSFS

OBJS-$(DEVNULL)+= kernel/drivers/null.o
CFLAGS-$(DEVNULL)+=-DCONFIG_DEVNULL



OBJS-$(SOCK_UNIX)+= kernel/drivers/socket_un.o
CFLAGS-$(SOCK_UNIX)+=-DCONFIG_SOCK_UNIX

OBJS-$(DEVUART)+= kernel/drivers/uart.o
CFLAGS-$(DEVUART)+=-DCONFIG_DEVUART

OBJS-$(GPIO_SEEEDPRO)+=kernel/drivers/gpio/gpio_seeedpro.o
CFLAGS-$(GPIO_SEEEDPRO)+=-DCONFIG_GPIO_SEEEDPRO

OBJS-$(GPIO_STM32F4)+=kernel/drivers/gpio/gpio_stm32f4.o
CFLAGS-$(GPIO_STM32F4)+=-DCONFIG_GPIO_STM32F4


CFLAGS+=$(CFLAGS-y)

all: image.bin

kernel/syscall_table.c: kernel/syscall_table_gen.py
	python2 $^


include/syscall_table.h: kernel/syscall_table.c

$(PREFIX)/lib/libkernel.a:
	make -C kernel

$(PREFIX)/lib/libfrosted.a:
	make -C libfrosted

image.bin: kernel.elf apps.elf
	export PADTO=`python -c "print ( $(KMEM_FLASH_SIZE) * 1024) + int('$(FLASH_ORIGIN)', 16)"`;	\
	$(CROSS_COMPILE)objcopy -O binary --pad-to=$$PADTO kernel.elf $@
	$(CROSS_COMPILE)objcopy -O binary apps.elf apps.bin
	cat apps.bin >> $@


apps/apps.ld: apps/apps.ld.in
	export KMEM_SIZE_B=`python -c "print '0x%X' % ( $(KMEM_SIZE) * 1024)"`;	\
	export AMEM_SIZE_B=`python -c "print '0x%X' % ( ($(RAM_SIZE) - $(KMEM_SIZE)) * 1024)"`;	\
	export KFLASHMEM_SIZE_B=`python -c "print '0x%X' % ( $(KMEM_FLASH_SIZE) * 1024)"`;	\
	export AFLASHMEM_SIZE_B=`python -c "print '0x%X' % ( ($(FLASH_SIZE) - $(KMEM_FLASH_SIZE)) * 1024)"`;	\
	cat $^ | sed -e "s/__FLASH_ORIGIN/$(FLASH_ORIGIN)/g" | \
			 sed -e "s/__KFLASHMEM_SIZE/$$KFLASHMEM_SIZE_B/g" | \
			 sed -e "s/__AFLASHMEM_SIZE/$$AFLASHMEM_SIZE_B/g" | \
			 sed -e "s/__RAM_BASE/$(RAM_BASE)/g" |\
			 sed -e "s/__KMEM_SIZE/$$KMEM_SIZE_B/g" |\
			 sed -e "s/__AMEM_SIZE/$$AMEM_SIZE_B/g" \
			 >$@

apps.elf: $(PREFIX)/lib/libfrosted.a $(APPS-y) apps/apps.ld
	$(CC) -o $@  $(APPS-y) -Tapps/apps.ld -lfrosted -lc -lfrosted -Wl,-Map,apps.map  $(LDFLAGS) $(CFLAGS) $(EXTRA_CFLAGS)

kernel/hal/arch/$(CHIP)/$(CHIP).ld: kernel/hal/arch/$(CHIP)/$(CHIP).ld.in
	export KMEM_SIZE_B=`python -c "print '0x%X' % ( $(KMEM_SIZE) * 1024)"`;	\
	export KFLASHMEM_SIZE_B=`python -c "print '0x%X' % ( $(KMEM_FLASH_SIZE) * 1024)"`;	\
	cat $^ | sed -e "s/__FLASH_ORIGIN/$(FLASH_ORIGIN)/g" | \
			 sed -e "s/__KFLASHMEM_SIZE/$$KFLASHMEM_SIZE_B/g" | \
			 sed -e "s/__RAM_BASE/$(RAM_BASE)/g" |\
			 sed -e "s/__KMEM_SIZE/$$KMEM_SIZE_B/g" \
			 >$@

kernel.elf: $(PREFIX)/lib/libkernel.a $(OBJS-y) kernel/hal/arch/$(CHIP)/$(CHIP).ld
	$(CC) -o $@   -Tkernel/hal/arch/$(CHIP)/$(CHIP).ld $(OBJS-y) -lkernel -Wl,-Map,kernel.map  $(LDFLAGS) $(CFLAGS) $(EXTRA_CFLAGS)

qemu: image.bin 
	qemu-system-arm -semihosting -M lm3s6965evb --kernel image.bin -serial stdio -S -gdb tcp::3333

qemu2: image.bin
	qemu-system-arm -semihosting -M lm3s6965evb --kernel image.bin -serial stdio

menuconfig:
	@$(MAKE) -C kconfig/ menuconfig -f Makefile.frosted

clean:
	@make -C kernel clean
	@make -C libfrosted clean
	@rm -f $(OBJS-y)
	@rm -f *.map *.bin *.elf
	@rm -f apps/apps.ld
	@rm -f kernel/hal/arch/$(CHIP).ld
	@find . |grep "\.o" | xargs -x rm -f

