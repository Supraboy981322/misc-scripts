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
  jl bad

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

  ;add rdi, 48 ;
  ;mov [argc], rdi

  continue:
    mov rax, 1 ;write
    mov rdi, 1 ;stdout
    ;mov rdx, 3
    syscall
  jmp continue

  mov rdi, 0
  jmp end

bad:
  mov rax, 1
  mov rdi, 2
  mov rsi, not_enough_args
  mov rdx, not_enough_args_len
  syscall

  mov rdi, 1
  jmp end

end:
  
  mov rax, 60
  syscall
