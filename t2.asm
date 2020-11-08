includelib legacy_stdio_definitions.lib
extrn printf:near
extern scanf:near

.data
	user_input_value QWORD 0
	please_enter BYTE "Please enter an integer: ", 0Ah, 00h
	scan_string BYTE "%lld", 00h
	out_string BYTE "The sum of proc. and user inputs (%lld, %lld, %lld, %lld) : %lld", 0Ah, 00h
.code

public fibX64

fibX64:
	sub rsp, 8					; align 16-bytes
	sub rsp, 32					; 32 byte shadow space for our recursive function, both calls of recurisve
								; function will use the same shadow space
	;; parameter fin is inputted in RCX
	cmp rcx, 0					; if(fin <= 0) 
	jg fr1
	mov rax, rcx				; return fin
	jmp fr_ret
fr1:
	cmp rcx, 1					; if(fin == 1)
	jne fr2
	mov rax, 1					; return 1
	jmp fr_ret
fr2:
	dec rcx						; fin-1
	mov [rsp + 16], rcx			; preserve current value of f-1
	call fibX64
	mov [rsp + 8], rax			; move result to shadow stack to preserve
	mov rcx, [rsp + 16]			; return preserved f-1
	dec rcx						; rcx = fin-2
	call fibX64
	add rax, [rsp + 8]			; rax = fib_rec(fin-1) + fib_rec(fin-2)
fr_ret:
	add rsp, 32					; remove shadow stack
	add rsp, 8					; remove 16-byte allignment
	ret

public use_scanf

use_scanf:
	mov [rsp + 8], rcx				;; preserving a in shadow space
	mov [rsp + 16], rdx				;; preserving b in shadow space
	mov [rsp + 24], r8				;; preserving c in shadow space
	
	sub rsp, 48						;; the max num of arguments that our calls to printf or scanf
									;; will use is 6, so we'll create a shadow space with 6 spaces
	sub rsp, 8						;; align 16-bit
	lea rcx, please_enter			;; printf("Please enter an integer: ")
	call printf						;; call the function
	lea rcx, scan_string
	lea rdx, user_input_value		
	call scanf						;; take user input
	mov rcx, [rsp + 64]				;; sum = a + b + c
	add rcx, [rsp + 72]
	add rcx, [rsp + 80]
	add rcx, user_input_value		;; sum = sum + user_input_value
	mov [rsp + 40], rcx				;; parameter 6: sum
	mov rdx, user_input_value		;; parameter 5: input value
	mov [rsp + 32], rdx			
	mov r9, [rsp + 80]				;; parameter 4: c
	mov r8, [rsp + 72]				;; parameter 3: b
	mov rdx, [rsp + 64]				;; parameter 2: a
	lea rcx, out_string				;; parameter 1: output string
	call printf
	mov rax, [rsp + 40]				;; return sum value to main()
	add rsp, 48						;; removing shadow space
	add rsp, 8
	ret

public max
max:
	mov r9, rcx					;; v = a
	cmp rdx, r9
	jle m1
	mov r9, rdx
m1:	cmp r8, r9
	jle m2
	mov r9, r8
m2:
	mov rax, r9
	ret

public max5
max5:
	mov [rsp + 8], rcx			; preserve inputted parameters
	mov [rsp + 16], rdx
	mov [rsp + 24], r8
	mov [rsp + 32], r9
	sub rsp, 24					; shadow space = 3*8
	sub rsp, 8					; align
	mov r8, rdx
	mov rdx, rcx
	mov rcx, user_input_value
	call max
	mov rcx, rax
	mov rdx, [rsp + 56]
	mov	r8, [rsp + 64]
	call max
	add rsp, 24					; shadow space = 3*8
	add rsp, 8					; align
	ret

end