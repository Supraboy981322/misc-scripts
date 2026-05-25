section .data
  consumed_msg db "resources consumed.", 10
  consumed_msg_len equ $ - consumed_msg

section .text
  global _start
_start:
  continue:
    mov rax, 57
    syscall
  jmp continue

exit:
  mov rax, 1
  mov rdx, consumed_msg_len
  mov rsi, consumed_msg
  mov rdi, 2
  syscall

  mov rax, 60
  mov rdi, 1
  syscall
