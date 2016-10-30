# BrainfuckMBR
Brainfuck interpreter written on NASM size of 512 bytes.

Execute  "./just_do_it" to start interpreter or "./just_debug_it bf_code" to debug(in debug mode you can send bf code using serial port). Also you can write it to flash drive and to start as a real system like windows or linux! 

For program recording on a flash drive, use the following command:

nasm -f bin minibrainfuck.asm -o minibrainfuck && dd if=minibrainfuck of=disk.img bs=510 count=1 conv=sync && cat 55haah >> disk.img && sudo dd if=disk.img of=/dev/you_flash_drive(for me it sdb)

To run the programs from a file, use the following command:

./just_debug_it \`cat path_to_bf_program\`

For example:

./just_debug_it \`cat programs/helloworld\`

-----------------------------------------------------------------------------------------------------------------------

Интерпретатор brainfuck написанный на NASM размером в 512 байт.

Для запуска интерпретатора, исполните файл "./just_do_it" или "./just_debug_it bf_code" для отладки(в режиме отладки вы можете посылать bf код через serial порт). Также вы можете записать этот интерпретатор на флешку и запустить прям как настоящую систему windows или linux!

Для записи программы на флешку, воспользуйтесь следующей командой:
nasm -f bin minibrainfuck.asm -o minibrainfuck && dd if=minibrainfuck of=disk.img bs=510 count=1 conv=sync && cat 55haah >> disk.img && sudo dd if=disk.img of=/dev/ваша_флешка(у меня это sdb)

Для запуска программ из файла, воспользуйтесь следующей командой:

./just_debug_it \`cat путь_к_программе\`

Например:

./just_debug_it \`cat programs/helloworld\`
