# BrainfuckMBR
Brainfuck interpreter written on NASM size of 512 bytes.

Execute  "./just_do_it" to start interpreter or "./just_debug_it code" to debug(in debug mode you can send bf code using serial port). Also you can write it to flash drive and to start as a real system like windows or linux! 

for program recording on a disc, use the following command:
nasm -f bin minibrainfuck.asm -o minibrainfuck && dd if=minibrainfuck of=disk.img bs=510 count=1 conv=sync && cat 55haah >> disk.img && sudo dd if=disk.img of=/dev/you_flash_drive(for me it sdb)
