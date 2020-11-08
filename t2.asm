includelib legacy_stdio_definitions.lib
extrn printf:near
extern scanf:near

.data
	user_input_value QWORD 0
	please_enter BYTE "Please enter an integer: ", 0Ah, 00h
	scan_string BYTE "%lld", 00h
	out_string BYTE "The sum of proc. and user inputs (%lld, %lld, %lld, %lld) : %lld", 0Ah, 00h
	lvlRecursion QWORD 0
.code

public fibX64_old

fibX64_old:
	sub rsp, 8					; align 16-bytes
	sub rsp, 32					; 32 byte shadow space for our recursive function, both calls of recurisve
								; function will use the same shadow space
	;; parameter fin is inputted in RCX
	cmp rcx, 0					; if(fin <= 0) 
	jg fr1_old
	mov rax, rcx				; return fin
	jmp fr_ret_old
fr1_old:
	cmp rcx, 1					; if(fin == 1)
	jne fr2_old
	mov rax, 1					; return 1
	jmp fr_ret_old
fr2_old:
	dec rcx						; fin-1
	mov [rsp + 16], rcx			; preserve current value of f-1
	call fibX64_old
	mov [rsp + 8], rax			; move result to shadow stack to preserve
	mov rcx, [rsp + 16]			; return preserved f-1
	dec rcx						; rcx = fin-2
	call fibX64_old
	add rax, [rsp + 8]			; rax = fib_rec(fin-1) + fib_rec(fin-2)
fr_ret_old:
	add rsp, 32					; remove shadow stack
	add rsp, 8					; remove 16-byte allignment
	ret

public fibX64		;; more efficient implementation of Fib Recursion

fibX64:
	;; parameter fin is inputted in RCX
	cmp rcx, 0					; if(fin <= 0), we jump to the recursive section
	jg if_gr_0
	cmp rcx, 0					; if(fin == 0)...
	jl if_ls_0 
	mov rax, 0					; ...return 0
	ret
if_ls_0:						; if(fin < 0)...
	mov rax, rcx				; ...return fin
	ret
if_gr_0:
	mov lvlRecursion, 0			; reset lvlRecursion value
	sub rsp, 8					; align 16-bytes
	sub rsp, 32					; 32 byte shadow space for our recursive function, all recursion uses same shadow space
	call fibX64R				; call the recursive function
	add rsp, 32					; remove shadow space
	add rsp, 8					; remove 16-byte allignment
	ret

	;; we will use two areas of shadow space, we'll call them valueNminus1 (found in [rsp+8]), 
	;; and valueNminus2 (found in [rsp+16]). this will tell us what fib(n-1) and fib(n-2) are, 
	;; and can be easily accessed by the level of recursion one level up to produce the next 
	;; fibonacci number, and will save us many unnecessary recursion calls to calculate values 
	;; we've already calculated, and save a huge amount of stack space. This is not visible to 
	;; our C++ code, only the above function is visible. We use the variable lvlRecursion to 
	;; know how far up the stack we have to go to get the values of valueNminus1 and valueNminus2
	;; when considering the return value that is being pushed on stack for every call

fibX64R:						; the recursive function, parameter num is in RCX
	cmp rcx, 1					; base case - if num = 1
	jne	if_ne_1
	mov r8, lvlRecursion
	lea r8, [rsp+r8*TYPE QWORD+8]
	mov rdx, 1
	mov [r8], rdx				; valueNminus1 = 1	- fib(1) = 1
	mov rdx, 0
	mov [r8+8], rdx				; valueNminus2 = 0  - fib(0) = 0
	mov rax, 1					; fib(1) = 1, which will be the return value
	ret
if_ne_1:
	dec rcx						; get N-1 for recursive call, we won't need either N or N-1
	inc lvlRecursion
	call fibX64R				; call recursive function
	dec lvlRecursion
	mov r8, lvlRecursion
	lea r8, [rsp+r8*TYPE QWORD+8] ; this is getting the address of valueNminus1
	mov rax, [r8]				; RAX = valueNminus1
	add rax, [r8+8]				; this is the equivalent of "return fibonacci_recursion(fin_1) + fibonacci_recursion(fin_2);" in the pseudocode
	mov rdx, [r8]				; getting the value of valueNminu1 again and storing it in RDX
	mov [r8+8], rdx			; putting the old value of valueNminus1 into valueNminus2
	mov [r8], rax				; putting the result of this fib number in valueNminus1
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