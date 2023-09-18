; Compile:
; nasm -f win32 IONUM.asm
; nlink IONUM.obj -lmio -o IONUM.exe

;%include 'IONUM.inc'
%include 'mio.inc'

global main

section .text

ReadInt:


    push ebx
    push ecx
    push edx ;store the previous values of the registers

    .reset:
    XOR eax, eax
    XOR ebx, ebx
    call mio_readchar
    cmp eax, '-'
    je .negative
    mov edx, 1
    jmp .positive

    .negative:
    mov edx, -1
    call mio_writechar

    .read_number:
    XOR eax, eax
    call mio_readchar
    .positive:
    cmp eax, 13
    je .end
    cmp eax, '0'
    jl  .error_set
    cmp eax, '9'
    jg .error_set
    .error_trigger:
    call mio_writechar
    XOR ecx, ecx
    mov ecx, eax
    mov eax, ebx
    imul eax, 10
    jo .error_overflow
    sub ecx, '0'
    add eax, ecx
    jo .error_overflow
    mov ebx, eax
    jmp .read_number

    .error_set:
    XOR edx, edx
    stc ;set carry flag to 1(?)
    jmp .error_trigger

    .error_nan:
    mov eax, str_error_nan
    call mio_writestr
    mov eax, 13
    call mio_writechar
    mov eax, 10
    call mio_writechar
    jmp .reset

    .error_overflow:
    XOR eax, eax
    call mio_readchar
    cmp eax, 13
    je .error_nan
    call mio_writechar
    jmp .read_number

    .end:
    cmp edx, 0
    je .error_nan
    mov eax, 13
    call mio_writechar
    mov eax, 10
    call mio_writechar
    mov eax, ebx
    imul eax, edx
    pop edx
    pop ecx
    pop ebx ;pop the previous values of the registers

    ret

WriteInt:
    push eax
    cmp eax, 0
    jge .positive
    cmp eax, 0
    jl .negative

    .negative:
    push eax
    mov eax, '-'
    call mio_writechar
    pop eax
    imul eax, -1

    .positive:
    push ebx
    push ecx
    push edx ;store the previous values of the registers

    XOR edx, edx
    XOR ecx, ecx
    mov ebx, 10
    .process:
    cmp eax, 0
    je .write
    cdq
    idiv ebx
    push edx
    inc ecx
    jmp .process

    .write:
    XOR eax, eax
    cmp ecx, 0
    je .end
    pop eax
    add eax, '0'
    call mio_writechar
    dec ecx
    jmp .write

    .end:
    mov eax, 13
    call mio_writechar
    mov eax, 10
    call mio_writechar

    pop edx
    pop ecx
    pop ebx
    pop eax ;pop the previous values of the registers

    ret

WriteBin:

    push eax
    push ebx
    push ecx
    push edx

    XOR ebx, ebx
    mov ebx, eax
    mov ecx, 32
    mov edx, 4

    .process:
    XOR eax, eax
    shl ebx, 1
    adc eax, 0
    add eax, '0'
    call mio_writechar
    dec ecx
    dec edx
    cmp edx, 0
    je .setfour
    .setfourend:
    cmp ecx, 0
    jne .process
    jmp .end

    .setfour:
    mov edx, 4
    mov al, ' '
    call mio_writechar
    jmp .setfourend

    .end:
    pop edx
    pop ecx
    pop ebx
    pop eax

ret


main:

    call ReadInt
    call WriteInt
    call WriteBin

    ret

section .data

    str_error_nan db ' Hiba', 0

section .bss