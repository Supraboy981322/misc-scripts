section .data
  argc dd 0 ;4 bytes wide
  not_enough_args db "not enough args", 10
  not_enough_args_len equ $ - not_enough_args
  exit_code db 0

section .text
  global _start

_start:

  mov rdi, [rsp] ;argc
  cmp rdi, 2
  jl need_args

  mov rsi, [rsp + 16]
  mov rdi, 0
  count:
    movzx eax, byte [rsi + rdi]
    test al, al
    jz counted
    inc rdi
    jmp count
  counted:
  mov rdx, rdi

  mov rsi, [rsp + 16]
  mov byte [rsi + rdx], 10
  add rdx, 1

  continue:
    mov rax, 1 ;write
    mov rdi, 1 ;stdout
    syscall
  jmp continue

  mov rdi, 0
  jmp exit


need_args:
  mov rax, 1
  mov rdi, 2
  mov rsi, not_enough_args
  mov rdx, not_enough_args_len
  syscall

  mov rdi, 1
  jmp exit


exit:
  mov rax, 60
  syscall
