add-symbol-file img/boot/kernel 0xFFFFFFFF80100000
set disassembly-flavor intel
target remote | qemu-system-x86_64 -cdrom Daisogen.iso -S -gdb stdio