section .data
  argc dd 0 ; NOTE: 4 bytes wide

  default_txt db "yes", 10
  not_enough_args db "not enough args", 10
  not_enough_args_len equ $ - not_enough_args

section .text
  global _start

_start:

  mov rdi, [rsp] ;argc
  cmp rdi, 1     ;if argc -lt 2 then need_args
  jg read_arg
  
  mov rdx, 4
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


;prints "not enough args" (followed by newline) then exits with code '1'
need_args:
  mov rax, 1
  mov rdi, 2 ;stderr
  mov rsi, not_enough_args
  mov rdx, not_enough_args_len
  syscall

  mov rdi, 1
  jmp exit


exit:
  mov rax, 60 ;exit
  syscall
