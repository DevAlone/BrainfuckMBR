org 0x7C00; смещение, по которому будет лежать программа в оперативной памяти

; константы, описывающее место в памяти, куда пихаем данные для интерпретатора
bf_mem_seg equ 0x100
bf_mem_offset equ 0x0
bf_code_pos equ 0
bf_code_size equ 10000
bf_data_pos equ bf_code_size 
bf_data_size equ 10000

VIDEO_PAGE equ 0

section .text
start:
    mov ax, cs
    mov ds, ax
    
    %ifdef DEBUG
        mov dx, 0
        mov ax, 0000000011100011b
        int 0x14
    %endif

    mov ax, 0x03; установить видео режим 0x0
    int 0x10; вызываем прерывание
    
    mov ax, 0x500; выбрать страницу видеопамяти 0x0
    int 0x10

    .main:
        call clearScreen
        
        push word 0
        call setCursor
        add sp, 2
       
        
; выводим стартовое сообщение               
        push word start_message
        call print
        add sp, 2
              
       ; меняем сегменты данных
        mov ax, bf_mem_seg
        mov es, ax
        mov ds, ax
        
; вводим программу
        lea di, [bf_mem_offset +bf_code_pos]; куда пишем
        xor cx, cx; счётчик записанных символов

        .lp:
            %ifdef DEBUG
                ; читаем из 0 serial port'а
                mov ah, 0x02
                mov dx, 0
                int 0x14
            %else
                mov ah, 0x00; читаем символ
                int 0x16
            %endif
            
            cmp al, 10; перенос строки
            jz .endlp
            cmp al, 13; возврат каретки
            jz .endlp
            ; разрешаем только символы bf кода
            ; убрал т.к. это занимает аж 32 байта!
            ;cmp al, 43; +
            ;jz .print_sym
            ;cmp al, 45; -
            ;jz .print_sym
            ;cmp al, 46; .
            ;jz .print_sym
            ;cmp al, 44; ,
            ;jz .print_sym
            ;cmp al, 91; [
            ;jz .print_sym
            ;cmp al, 93; ]
            ;jz .print_sym
            ;cmp al, 60; <
            ;jz .print_sym
            ;cmp al, 62; >
            ;jz .print_sym
            
            
            ;jmp .do_not_print_sym    
            
            .print_sym:
                mov ah, 0x0E; номер функции BIOS
                mov bh, VIDEO_PAGE; страница видеопамяти
                int 0x10; выводим символ
                        
            ; в al ascii код символа
            mov [di], byte al
            inc di
            
            
            inc cx
            .do_not_print_sym:
            cmp cx, bf_code_size
            jng .lp
            
        .endlp:
        mov [di+1], byte 0; пишем конец строки
        cmp cx, 0
        ;если пользователь ничего не ввёл, ошибка
        je .end_with_error
;; проверяем баланс скобок

        lea di, [bf_mem_offset +bf_code_pos]; куда пишем
        xor cx, cx
        .br_balance_lp:
            mov al, [di]
            cmp al, 0
            jz .end_br_balance_lp
            cmp al, '['
            jnz .else_if
            inc cx
            .else_if:
            cmp al, ']'
            jnz .end_if
            dec cx
            .end_if:
            inc di
            cmp cx, 0
            jl .end_with_error
            jmp .br_balance_lp
        .end_br_balance_lp: 
        cmp cx, 0
        jnz .end_with_error           

; создаём массив для хранения данных и зануляем его
        
        lea di, [bf_mem_offset +bf_data_pos]; тут будет храниться массив с которым работает bf
        mov cx, bf_data_size
        .data_null_lp:
            mov [di], byte 0
            inc di
            loop .data_null_lp
           
        
; интерпретируем
        call clearScreen
       
        push word 0
        call setCursor
        add sp, 2
        
        
        lea di, [bf_mem_offset+bf_data_pos]; массив 
        xor bx, bx; указатель на ячейку массива
        lea si, [bf_mem_offset +bf_code_pos] ; откуда берём команды
        .interpreter:
            mov al, byte [si]; загружаем символ
            cmp al, 0; 
            je .end_interpreter
            
            cmp al, 43; +
            je .C0
            cmp al, 45; -
            je .C1
            cmp al, 62; >
            je .C2
            cmp al, 60; <
            je .C3
            cmp al, 46; .
            je .C4
            cmp al, 44; ,
            je .C5
            cmp al, 91; [
            je .C6
            cmp al, 93; ]
            je .C7
            jmp .def
            .C0:; +
                inc byte [di+bx]
                jmp .sw_end
            .C1:; -
                dec byte [di+bx]
                jmp .sw_end
            .C2:; >
                cmp bx, bf_data_size-1
                jnl .sw_end; если >= size-1
                inc bx; иначе увеличиваем номер ячейки
                jmp .sw_end
            .C3:; <
                cmp bx, 0
                je .sw_end; если ноль выходим
                dec bx; иначе уменьшаем номер ячейки
                jmp .sw_end
            .C4:; .
                pusha; пушим всё в стек, чтоб случайно не поломать bx, cx и прочие нужные регистры
                ; делаем интерапт биоса
                mov al, [di+bx]
                mov ah, 0x0E; номер функции BIOS
                mov bh, VIDEO_PAGE; страница видеопамяти
                int 0x10; выводим символ
                popa
                jmp .sw_end
            .C5:; ,
                pusha
                mov ah, 0x03; читаем позицию курсора
                mov bh, VIDEO_PAGE; видео страница
                int 0x10
                ;dh - строка
                ;dl - колонка
                ; положили в стек старые значения
                push word dx
                ; перемещаем курсор в нижнюю строку экрана
                push word 0x1800; 24 строка 0 столбец
                call setCursor
                add sp, 2

                push word input_message
                call print
                add sp, 2                
                
                mov ah, 0x00; читаем символ
                int 0x16
                ;cmp al, 0
                ;je .c5_end
                ;al
                mov [di+bx], al; записываем в массив
                ; выводим его же
                mov ah, 0x0E; 
                mov bh, VIDEO_PAGE; 
                int 0x10; 
                
                call setCursor; исплользуются те значения, что были занесены в стек
                add sp, 2
                .c5_end:
                popa
                jmp .sw_end
            .C6:; [
                cmp [di+bx], byte 0; 
                jnz .sw_end; если в текущей ячейке массива не ноль, выполняем то, что в теле цикла
                ; переходим на следующую ] с учётом вложенности
                mov ax, 1; в прямом направлении
                call loops_handler
                dec si; на одну назад                
	        jmp .sw_end
            .C7:; ]
                mov ax, -1; в обратном направлении
                call loops_handler                
                jmp .sw_end
            .def:
                ;jmp .error
            .sw_end:
                      
            
            inc si
            jmp .interpreter
            
            .end_with_error:
            mov bx, -1
            jmp .end_prog
            .end_interpreter:
            mov bx, 0
            
            .end_prog:
            ; возвращаем сегменты в прежнее состояние
            push bx
                mov ax, cs
                mov es, ax; меняем сегмент памяти
                mov ds, ax
                
                ; перемещаем курсор в нижнюю строку экрана
                push word 0x1800; 24 строка 0 столбец
                call setCursor
                add sp, 2
            pop bx
            cmp bx, 0
            jz .no_error
            push word error_message
            call print
            add sp, 2
            .no_error:
            
            push finish_message
            call print
            add sp, 2
            
            ; ждём нажатия
            mov ah, 0x00
            int 0x16
            
            jmp .main
            .error:; пока не нужен
                ; handle error
                ;jmp .main
            
        ; end
        
        
; переходит на соответствующую скобку с учётом вложенности
; т.е. если в [si] находится '[', переходит на ']' и наоборот
; направление задаётся первым аргументом переданным через ax (1 или -1)
; меняет si
loops_handler:
    ;push bp
    ;mov bp, sp
    enter 0, 0
    push cx
    xor cx, cx
    .lp_br1:
        cmp [si], byte '['
        jnz .else_if1
        inc cx
        .else_if1: 
        cmp [si], byte ']'
        jnz .end_if1
        dec cx
        .end_if1:
        add si, ax
                            
        cmp cx, 0
        jnz .lp_br1
    pop cx
    leave
    ;mov sp, bp
    ;pop bp
    ret
    
    
print:
    enter 0, 0
    pusha
    push ds; запоминаем сегмент
    mov ax, 0; меняем на нулевой, где хранятся все сообщения
    ;mov es, ax
    mov ds, ax
    
    mov si, [bp+2+2]; первый аргумент
    cld
    mov ah, 0x0E; номер функции BIOS
    mov bh, VIDEO_PAGE; страница видеопамяти
    
    
    .puts_loop:
        lodsb; загружаем очередной символ в al
        test al, al; если 0, выходим
        jz .exit_loop
        int 0x10; иначе вызываем функцию bios
        jmp .puts_loop
    .exit_loop:
    
    pop ds; восстанавливаем сегмент
    ;pop ax
    ;mov es, ax
    
    popa
    leave
    ret
clearScreen:
    pusha
    ;mov ah, 0x06; листать окно вверх
    ;mov al, 0; очистить окно
    mov ax, 0x0600; 
    ; левый верхний угол
    ;mov cx, 0
    xor cx, cx
    ; правый нижний угол
    ;mov dh, 25
    ;mov dl, 80
    mov dx, 0x2580    
    mov bh, 00000010b; цвет
    int 0x10
    popa
    ret
; void setCursor(dword xy)
setCursor:
    enter 0, 0
    
    pusha
    
    ; устанавливаем курсор в 0 0
        mov ah, 0x02
        mov bh, VIDEO_PAGE; страница видеопамяти
        mov dx, [bp+2+2]; первый аргумент
        ;dh line
        ;dl collumn
        int 0x10
        
    popa
    
    leave
    ret
; просто функция для отладки
debug:
    pusha
    mov al, '&'
    mov ah, 0x0E; номер функции BIOS
    mov bh, VIDEO_PAGE; страница видеопамяти
    int 0x10; выводим символ
    jmp $
    popa
    ret
    
section .data
    start_message db '$ ', 0
    finish_message db 'press key to cont', 0
    input_message db '> ', 0    
    error_message db 'err ', 0

   
;finish:
;    times 512-finish-start db 0
;    db 0x55, 0xAA; сигнатура загрузочного сектора
