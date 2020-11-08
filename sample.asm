includelib legacy_stdio_definitions.lib
extrn printf:near


;; Data segment
.data

	print_string BYTE "Sum of i: %I64d and j: %lld is: %I64d", 0Ah, 00h
	print_string2 BYTE "Sum of i: %I64d, j: %lld and bias: %lld is: %I64d", 0Ah, 00h
	bias QWORD 50
	sum2 QWORD 0

;; Code segment
.code

;; address of the array: RDX
;; size of the array: RCX
public array_proc

array_proc:
			;; RAX is the accumulator
			xor rax, rax

			;; the main loop
L1:			add rax, [rdx] ;; access and add contents
			add rdx, TYPE QWORD	;; TYPE operator returns the number of bytes used by the identified QWORD
			loop L1 ;; RCX as the loop counter

			;; returning from the function/procedure
			ret

;; i in RCX (arg1)
;; j in RDX (arg2)
;; print_proc: adds the two arguments and prints it through printf
public print_proc

print_proc:
			lea rax, [rcx+rdx]		;; a way to add two regs and place it in rax
			mov [rsp+24], rax		;; preserving rax in shadow space
			mov [rsp+16], rcx		;; preserving i
			mov [rsp+8], rdx		;; preserving j

			;; Calling our printf function
			sub rsp, 40				;; the shadow space
			mov r9, rax				;; 4th argument
			mov r8, rdx				;; 3rd argument: j
			mov rdx, rcx			;; 2nd argument: i
			lea rcx, print_string	;; 1st argument: string
			call printf				;; call the function

			;; 2nd call to printf
			;; RSP has changed, so the displacements have also changed
			mov rax, [rsp+64]		;; restoring the sum
			add rax, bias			;; adding the bias
			mov [rsp+72], rax			;; preserving rax
			mov [rsp+32], rax		;; the 5th argument on stack
			mov r9, bias			;; the 4th argument
			mov r8, [rsp+48]		;; restoring j, the 3rd arg
			mov rdx, [rsp+56]		;; restoring i, the 2nd arg
			lea rcx, print_string2 ;; 1st argument: string
			call printf				;; call the function
			
			add rsp, 40				;; deallocate the shadow space
			
			;; restore rax
			mov rax, [rsp+32]
			ret

end