section .data
  argc dd 0 ; NOTE: 4 bytes wide

  default_txt db "yes", 10
  default_txt_len equ $ - default_txt

section .text
  global _start

_start:

  mov rdi, [rsp] ;argc
  cmp rdi, 1     ;if argc -lt 2 then use default_txt
  jg read_arg
  
  mov rdx, default_txt_len
  mov rsi, default_txt
  jmp continue

read_arg:

  mov rsi, [rsp + 16] ;argv[1]
  mov rdx, 0          ;length of argv[1]
  count:
    movzx eax, byte [rsi + rdx] ;get byte at idx rdi
    test al, al                 ;set zero flag if byte is 0 (NUL)
    jz counted                  ;end loop on zero (NUL) byte
    inc rdx                     ;increment counter
    jmp count                   ;continue loop
  counted:

  mov byte [rsi + rdx], 10 ;replace NUL byte with newline
  inc rdx                  ;counter (len of argv[1]) to include newline

  continue:
    mov rax, 1 ;write
    mov rdi, 1 ;stdout
    syscall
  jmp continue ;loop indefinitely

  mov rdi, 0 ;set exit code
  jmp exit   ;jmp to exit

exit:
  mov rax, 60 ;exit
  syscall
