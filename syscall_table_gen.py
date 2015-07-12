#!/usr/bin/python2
#
#
#
# Add your syscalls here
#######
 #####
  ###
   #

syscalls = [
    ("setclock", 1),
    ("start", 0),
    ("stop", 0),
    ("sleep", 1),
    ("thread_create", 3),
    ("test", 5)
]

   #
  ###
 #####
#######
#################################################################
hdr = open("syscall_table.h", "w")
code = open("syscall_table.c", "w")

hdr.write("/* The file syscall_table.h is auto generated. DO NOT EDIT, CHANGES WILL BE LOST. */\n/* If you want to add syscalls, use syscall_table_gen.py  */\n\n#include \"frosted.h\"\n\n")
code.write("/* The file syscall_table.c is auto generated. DO NOT EDIT, CHANGES WILL BE LOST. */\n/* If you want to add syscalls, use syscall_table_gen.py  */\n\n#include \"frosted.h\"\n#include \"syscall_table.h\"\n")

for n in range(len(syscalls)):
    name = syscalls[n][0]
    hdr.write("#define SYS_%s \t\t\t(%d)\n" % (name.upper(), n))
hdr.write("#define _SYSCALLS_NR %d\n" % len(syscalls))

for n in range(len(syscalls)):
    name = syscalls[n][0]
    tp = syscalls[n][1]
    code.write("\n\n")
    code.write( "/* Syscall: %s(%d arguments) */\n" % (name, tp))
    if (tp == 0):
        code.write( "int sys_%s(void){\n" % name)
        code.write( "    syscall(SYS_%s, 0, 0, 0, 0, 0); \n" % name.upper())
        code.write( "}\n")
        code.write("\n")
    if (tp == 1):
        code.write( "int sys_%s(uint32_t arg1){\n" % name)
        code.write( "    syscall(SYS_%s, arg1, 0, 0, 0, 0); \n" % name.upper())
        code.write( "}\n")
        code.write("\n")
    if (tp == 2):
        code.write( "int sys_%s(uint32_t arg1, uint32_t arg2){\n" % name)
        code.write( "    syscall(SYS_%s, arg1, arg2, 0, 0, 0); \n" % name.upper())
        code.write( "}\n")
        code.write("\n")
    if (tp == 3):
        code.write( "int sys_%s(uint32_t arg1, uint32_t arg2, uint32_t arg3){\n" % name)
        code.write( "    syscall(SYS_%s, arg1, arg2, arg3, 0,  0); \n" % name.upper())
        code.write( "}\n")
        code.write("\n")
    if (tp == 4):
        code.write( "int sys_%s(uint32_t arg1, uint32_t arg2, uint32_t arg3, uint32_t arg4){\n" % name)
        code.write( "    syscall(SYS_%s, arg1, arg2, arg3, arg4, 0); \n" % name.upper())
        code.write( "}\n")
        code.write("\n")
    if (tp == 5):
        code.write( "int sys_%s(uint32_t arg1, uint32_t arg2, uint32_t arg3, uint32_t arg4, uint32_t arg5){\n" % name)
        code.write( "    syscall(SYS_%s, arg1, arg2, arg3, arg4, arg5); \n" % name.upper())
        code.write( "}\n")
        code.write("\n")
    code.write( "int __attribute__((weak)) _sys_%s(uint32_t arg1, uint32_t arg2, uint32_t arg3, uint32_t arg4, uint32_t arg5){\n" % name)
    code.write( "   return -1;\n")
    code.write( "}\n")
    code.write("\n")

