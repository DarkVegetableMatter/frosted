#Common code used to read the .config
ifeq ($(ARCH_LPC176X),y)
	CPU=cortex-m
	CHIP=lpc176x
	FLASH_ORIGIN=0x00000000
	RAM_BASE=0x10000000
	CFLAGS+=-DSEEEDPRO -mcpu=cortex-m3
endif

ifeq ($(ARCH_QEMU),y)
	CPU=cortex-m
	CHIP=stellaris
	FLASH_ORIGIN=0x00000000
	RAM_BASE=0x20000000
	CFLAGS+=-mcpu=cortex-m3
endif

ifeq ($(ARCH_STM32F4),y)
	CPU=cortex-m
	CHIP=stm32f4
	FLASH_ORIGIN=0x08000000
	RAM_BASE=0x20000000
	CFLAGS+=-DSTM32F4 -mcpu=cortex-m4 -mfloat-abi=soft
endif

ifeq ($(FLASH_SIZE_2MB),y)
	FLASH_SIZE=2048
endif
ifeq ($(FLASH_SIZE_1MB),y)
	FLASH_SIZE=1024
endif
ifeq ($(FLASH_SIZE_512KB),y)
	FLASH_SIZE=512
endif
ifeq ($(FLASH_SIZE_256KB),y)
	FLASH_SIZE=256
endif
ifeq ($(FLASH_SIZE_128KB),y)
	FLASH_SIZE=128
endif

ifeq ($(RAM_SIZE_192KB),y)
	RAM_SIZE=192
endif
ifeq ($(RAM_SIZE_128KB),y)
	RAM_SIZE=128
endif
ifeq ($(RAM_SIZE_32KB),y)
	RAM_SIZE=32
endif
ifeq ($(RAM_SIZE_16KB),y)
	RAM_SIZE=16
endif


RAM_BASE?=0x20000000
FLASH_ORIGIN?=0x0
FLASH_SIZE?=256K
APPS_ORIGIN=$$(( $(KMEM_FLASH_SIZE) * 1024))
CFLAGS+=-DFLASH_ORIGIN=$(FLASH_ORIGIN)
CFLAGS+=-DAPPS_ORIGIN=$(APPS_ORIGIN)
