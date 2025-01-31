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
    cmp eax, 8
    je .backspace
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

    .backspace:
    call mio_writechar
    mov eax, ' '
    call mio_writechar
    mov eax, 8
    call mio_writechar
    push edx
    mov eax, ebx
    mov ebx, 10
    cdq
    idiv ebx
    mov ebx, eax
    pop edx
    cmp ebx, 0
    jle .reset
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
    jg .positive
    cmp eax, 0
    jl .negative
    cmp eax, 0
    je .zero

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
    jmp .nz

    .zero:
    mov eax, '0'
    call mio_writechar
    mov eax, 13
    call mio_writechar
    mov eax, 10
    call mio_writechar
    
    .nz:
    pop eax ;pop the previous values of the registers

    ret

ReadBin:

    push ebx
    push ecx
    push edx

    .reset:
    XOR eax, eax
    XOR ebx, ebx
    XOR ecx, ecx
    XOR edx, edx
    
    .read_number:
    call mio_readchar
    cmp eax, 13
    je .end
    cmp eax, 8
    je .backspace
    call mio_writechar
    cmp eax, '0'
    jl .error_trigger
    cmp eax, '1'
    jg .error_trigger
    inc edx
    shr eax, 1
    adc ebx, 0
    cmp edx, 32
    je .skipleftshift
    shl ebx, 1
    .skipleftshift:
    jmp .read_number

    .backspace:
    call mio_writechar
    mov eax, ' '
    call mio_writechar
    mov eax, 8
    call mio_writechar
    dec edx
    shr ebx, 1
    jmp .read_number

    .error_bin:
    mov eax, str_error_nan
    call mio_writestr
    mov eax, 13
    call mio_writechar
    mov eax, 10
    call mio_writechar
    jmp .reset

    .error_trigger:
    mov ecx, 1
    jmp .read_number

    .end:
    cmp ecx, 1
    je .error_bin
    cmp edx, 32
    jg .error_bin
    mov eax, 13
    call mio_writechar
    mov eax, 10
    call mio_writechar
    XOR eax, eax
    mov eax, ebx
    cmp edx, 32
    je .skiprightshift
    shr eax, 1
    .skiprightshift:

    pop edx
    pop ecx
    pop ebx

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
    mov eax, 13
    call mio_writechar
    mov eax, 10
    call mio_writechar
    pop edx
    pop ecx
    pop ebx
    pop eax

ret

ReadHex:

    push ebx
    push ecx
    push edx

    .reset:
    XOR eax, eax
    XOR ebx, ebx
    XOR ecx, ecx
    XOR edx, edx

    .h_read_number:
    XOR eax, eax
    call mio_readchar
    cmp eax, 13
    je .h_endh
    ;cmp eax, 8
    ;je .backspace
    cmp eax, '0'
    jl .h_error_nan
    cmp eax, '9'
    jg .h_correct_letter
    cmp eax, '9'
    jle .h_number

    .h_letter:
    cmp eax, 'F'
    jle .h_c_letter
    cmp eax, 'f'
    jle .h_nc_letter

    .h_number:
    call mio_writechar
    sub eax, '0'
    jmp .h_store

    .h_c_letter:
    sub eax, 55
    jmp .h_store

    .h_nc_letter:
    sub eax, 87
    jmp .h_store

    .h_store:
    push eax
    add ecx, 1
    jmp .h_read_number

    .h_correct_letter_wr:
    call mio_writechar
    jmp .h_letter

    .h_correct_letter:
    cmp eax, 'A'
    jl .h_error_nan
    cmp eax, 'F'
    jle .h_correct_letter_wr
    cmp eax, 'a'
    jl .h_error_nan
    cmp eax, 'f'
    jle .h_correct_letter_wr
    jmp .h_error_nan

    .h_endh:
    cmp ecx, 0
    je .h_end
    XOR eax, eax
    mov ebx, 1

    .h_process:
    pop edx
    sub ecx, 1
    imul edx, ebx
    add eax, edx
    imul ebx, 16
    cmp ecx, 0
    jne .h_process
    push eax
    jmp .h_end

    ;.backspace:
    ;call mio_writechar
    ;mov eax, ' '
    ;call mio_writechar
    ;mov eax, 8
    ;call mio_writechar
    ;push edx
    ;mov eax, ebx
    ;mov ebx, 16
    ;cdq
    ;idiv ebx
    ;mov ebx, eax
    ;pop edx
    ;cmp ebx, 0
    ;jle .reset
    ;jmp .h_read_number
    
    .h_error_nan:
    jmp .read_error
    
    .h_end:
    mov eax, 13
    call mio_writechar
    mov eax, 10
    call mio_writechar
    XOR eax, eax
    pop eax
    pop edx
    pop ecx
    pop ebx
    jmp .noerror

    .read_error:
    mov     al, 13
    call    mio_writechar
    mov     al, 10
    call    mio_writechar
    mov eax, str_error_nan
    call mio_writestr
    mov     al, 13
    call    mio_writechar
    mov     al, 10
    call    mio_writechar

    .noerror:

    ret

WriteHex:

    push ebx
    push ecx
    push edx
    push eax

    mov eax, '0'
    call mio_writechar
    mov eax, 'x'
    call mio_writechar
    XOR eax, eax
    pop eax
    push eax
    mov ecx, 8
    .loop1:
    mov ebx, 15
    and ebx, eax
    push ebx
    shr eax, 4
    loop .loop1
    mov ecx, 8
    .loop2:
    pop eax
    cmp eax, 9
    jg .letter
    add eax, 48
    jmp .letter_end
    .letter:
	add eax, 55
    .letter_end:
	call mio_writechar
    loop .loop2

    pop eax
    pop edx
    pop ecx
    pop ebx
    push eax
    mov     al, 13 ;Uj sor
    call    mio_writechar
    mov     al, 10
    call    mio_writechar
    pop eax

    ret


main:

    call ReadInt
    push eax
    call WriteInt
    call WriteHex
    call WriteBin
    mov     al, 13
    call    mio_writechar
    mov     al, 10
    call    mio_writechar
    mov     al, 13
    call    mio_writechar
    mov     al, 10
    call    mio_writechar
    call ReadHex
    push eax
    call WriteInt
    call WriteHex
    call WriteBin
    mov     al, 13
    call    mio_writechar
    mov     al, 10
    call    mio_writechar
    mov     al, 13
    call    mio_writechar
    mov     al, 10
    call    mio_writechar
    call ReadBin
    push eax
    call WriteInt
    call WriteHex
    call WriteBin

    pop eax
    pop ebx
    pop ecx
    add eax, ebx
    add eax, ecx
    call WriteInt
    call WriteHex
    call WriteBin

    ret

section .data

    str_error_nan db ' Hiba', 0

section .bss