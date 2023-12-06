.section .data
    HEAP_TOP_INITIAL: .quad 0
    HEAP_TOP:         .quad 0

    STR_BUFFER_INIT: .string "*************** allocator first-fit assembly ***************\n"
    STR_HEADER:      .string "################"
    STR_PRINT:       .string "%s"
    STR_FILLED:      .string "+"
    STR_FREED:       .string "-"
    STR_NEWLINE:     .string "\n"

# constants
    .equ FREED, 0
    .equ FILLED, 1

.section .text

.globl asMalloc_initAllocator 
.globl asMalloc_finishAllocator
.globl asMalloc_allocMem
.globl asMalloc_freeMem
.globl asMalloc_printMap
.globl main

# void brk_set(long int valor_brk)
# set the new heap size
brk_set:
    pushq %rbp
    movq %rsp, %rbp

    # new value of brk is already in %rdi
    movq $12, %rax
    syscall

    popq %rbp
    ret


# void printfBufferInit()
# prints something random to initialize
# the printf buffer
printfBufferInit:
    pushq %rbp
    movq %rsp, %rbp

    movq $STR_BUFFER_INIT, %rdi
    call printf

    popq %rbp
    ret


# void asMalloc_initAllocator()
# initializes the allocator
asMalloc_initAllocator:
    pushq %rbp
    movq %rsp, %rbp

    call printfBufferInit

    # HEAP_TOP_INITIAL = brk(0)
    movq $0, %rdi
    call brk_set
    movq %rax, HEAP_TOP_INITIAL

    # HEAP_TOP = HEAP_TOP_INITIAL
    movq HEAP_TOP_INITIAL, %rax
    movq %rax, HEAP_TOP

    popq %rbp
    ret


# void asMalloc_finishAllocator()
# finishes the allocator
asMalloc_finishAllocator:
    pushq %rbp
    movq %rsp, %rbp

    # brk(HEAP_TOP_INITIAL)
    movq HEAP_TOP_INITIAL, %rdi
    call brk_set

    # HEAP_TOP = HEAP_TOP_INITIAL
    movq HEAP_TOP_INITIAL, %rax
    movq %rax, HEAP_TOP

    popq %rbp
    ret


# void fillBlock(void *ptr, long int state, long int size)
# auxiliary function to fill the
# gerencial infos of the block
fillBlock:
    pushq %rbp
    movq %rsp, %rbp

    # *(ptr) = state
    movq %rsi, (%rdi)

    # *(ptr + 8) = size
    movq %rdx, 8(%rdi)

    popq %rbp
    ret


# void *asMalloc_allocMem(long int numBytes)
# allocates a block of numBytes bytes in the heap
# reuse freed blocks
#   local variables and return value:
#   -8(%rbp)  = ptr
#   -16(%rbp) = state
#   -24(%rbp) = size
#   -32(%rbp) = next
#   return    = blockStart (start of the allocated block)
asMalloc_allocMem:
    pushq %rbp
    movq %rsp, %rbp
    pushq %r12       # saving %12, used by the callee
    subq $24, %rsp   # alocating LVs
    
    # void *ptr = HEAP_TOP_INITIAL
    movq HEAP_TOP_INITIAL, %rbx
    movq %rbx, -8(%rbp)

while_1: # (ptr < HEAP_TOP)
    movq -8(%rbp), %rbx
    cmpq HEAP_TOP, %rbx
    jge end_while_1
    
    # state = *ptr
    movq -8(%rbp), %rbx
    movq (%rbx), %rbx
    movq %rbx, -16(%rbp)

    # size = *(ptr + 8)
    movq -8(%rbp), %rbx
    addq $8, %rbx
    movq (%rbx), %rbx
    movq %rbx, -24(%rbp)

# if_1: (numBytes <= size && state == FREED)
    movq -24(%rbp), %rbx  # %rbx = size
    cmpq %rbx, %rdi
    jg end_if_1

    movq -16(%rbp), %rbx  # %rbx = state
    cmpq $FREED, %rbx
    jne end_if_1
    
    # fillBlock(ptr, FILLED, numBytes);
    pushq %rdi           # saving %rdi
    movq %rdi, %rdx      # param3: numBytes
    movq $FILLED, %rsi   # prarm2: state FILLED
    movq -8(%rbp), %rdi  # param1: ptr 
    call fillBlock       # %rax contains the start of the allocated block
    popq %rdi            # restoring %rdi

    # sizeNext = (size - numBytes - 16)
    movq -24(%rbp), %rbx  # %rbx = size
    movq %rdi, %rcx       # %rcx = numBytes
    subq %rcx, %rbx       # %rcx = size - numBytes
    subq $16, %rbx        # %rbx = size - numBytes - 16

# if_2: (sizeNext >= 1)
    cmpq $1, %rbx
    jl else_2

    # void *next = ptr + 16 + numBytes;
    movq -8(%rbp), %rcx  # %rcx = ptr
    addq $16, %rcx       # %rcx = ptr + 16
    addq %rdi, %rcx      # %rcx = ptr + 16 + numBytes

    # fillBlock(next, FREED, sizeNext);
    pushq %rdi         # saving %rdi
    movq %rbx, %rdx    # param3: sizeNext
    movq $FREED, %rsi  # prarm2: state FREED
    movq %rcx, %rdi    # param1: next 
    call fillBlock     # %rax contains the start of the allocated block
    popq %rdi          # restoring %rdi

    jmp end_if_2

else_2:
    # *(ptr + 8) = size
    movq -8(%rbp), %rbx   # %rbx = ptr
    movq -24(%rbp), %rcx  # %rcx = size
    movq %rcx, 8(%rbx)    # *(ptr + 8) = size

end_if_2:
    # %rax = (ptr + 16)
    movq -8(%rbp), %rax
    addq $16, %rax

    # return (ptr + 16)
    jmp return_asMalloc_allocMem

end_if_1:
    # ptr = ptr + 16 + size
    movq -8(%rbp), %rbx   # %rbx = ptr
    addq -24(%rbp), %rbx  # %rbx = ptr + size
    addq $16, %rbx        # %rbx = ptr + size + 16
    movq %rbx, -8(%rbp)   # ptr  = ptr + size + 16

    jmp while_1

end_while_1:

    # allocates space at the end of the heap
    # heapTopNew em %r12
    # heapTopNew = HEAP_TOP + numBytes + 16
    movq %rdi, %rbx      # %rbx = numBytes
    movq HEAP_TOP, %r12  # %r12 = HEAP_TOP
    addq %rbx, %r12      # %r12 = HEAP_TOP + numBytes
    addq $16, %r12       # %r12 = HEAP_TOP + numBytes + 16

    # brk(heapTopNew)
    pushq %rdi       # saving %rdi
    movq %r12, %rdi  # %rdi = heapTopNew
    call brk_set
    popq %rdi        # restoring %rdi

    # fillBlock(HEAP_TOP, FILLED, numBytes);
    pushq %rdi           # saving %rdi
    movq %rdi, %rdx      # param3: numBytes
    movq $FILLED, %rsi   # prarm2: state FILLED
    movq HEAP_TOP, %rdi  # param1: HEAP_TOP 
    call fillBlock       # %rax contains the start of the allocated block
    popq %rdi            # recuperando %rdi

    # blockStart = (ptr + 16)
    movq -8(%rbp), %rax
    addq $16, %rax

    # HEAP_TOP = heapTopNew
    movq %r12, HEAP_TOP

    # return blockStart (strored in %rax by fillBlock)
    jmp return_asMalloc_allocMem

return_asMalloc_allocMem:
    addq $24, %rsp  # retoring pilha
    popq %r12       # retoring %r12, used by the callee
    popq %rbp       # popping %rbp
    ret


# int asMalloc_freeMem(void *block)
# frees the memory of the block
#   local variables and return value:
#   -8(%rbp)  = ptr
#   -16(%rbp) = state
#   -24(%rbp) = size
#   -32(%rbp) = next
#   -40(%rbp) = stateNext
#   -48(%rbp) = sizeNext
#   return    = 0 (fail), 1 (success)
asMalloc_freeMem:
    pushq %rbp
    movq %rsp, %rbp
    subq $48, %rsp   # allocating LVs

# if_3: (block < heapTopInitial || block > heapTop) return 0
    cmpq HEAP_TOP_INITIAL, %rdi
    movq $0, %rax
    jl return_asMalloc_freeMem

    cmpq HEAP_TOP, %rdi
    movq $0, %rax
    jg return_asMalloc_freeMem

    # marck block as freed
    # void *ptr = block
    movq %rdi, -8(%rbp)
    
    # ptr = ptr - 16
    movq -8(%rbp), %rbx
    subq $16, %rbx
    movq %rbx, -8(%rbp)
    
    # *ptr = FREED
    movq -8(%rbp), %rbx
    movq $FREED, (%rbx)

    # void *ptr = HEAP_TOP_INITIAL
    movq HEAP_TOP_INITIAL, %rbx
    movq %rbx, -8(%rbp)

while_2: # (ptr < HEAP_TOP)
    movq -8(%rbp), %rbx
    cmpq HEAP_TOP, %rbx
    jge end_while_2

    # state = *ptr
    movq -8(%rbp), %rbx
    movq (%rbx), %rbx
    movq %rbx, -16(%rbp)

    # size = *(ptr + 8)
    movq -8(%rbp), %rbx
    addq $8, %rbx
    movq (%rbx), %rbx
    movq %rbx, -24(%rbp)

# if_4: (state == FREED)
    movq -16(%rbp), %rbx
    cmpq $FREED, %rbx
    jne end_if_4

    # void *next = ptr + 16 + size;
    movq -8(%rbp), %rcx   # %rcx = ptr
    movq -24(%rbp), %rdx  # %rdx = size
    addq $16, %rcx        # %rcx = ptr + 16
    addq %rdx, %rcx       # %rcx = ptr + 16 + size
    movq %rcx, -32(%rbp)  # next = %rcx

while_3: # (next < HEAP_TOP)
    movq -32(%rbp), %rbx
    cmpq HEAP_TOP, %rbx
    jge end_while_3

    # stateNext = *next
    movq -32(%rbp), %rbx
    movq (%rbx), %rbx
    movq %rbx, -40(%rbp)

    # sizeNext = *(next + 8)
    movq -32(%rbp), %rbx
    addq $8, %rbx
    movq (%rbx), %rbx
    movq %rbx, -48(%rbp)

# if_5: (stateNext == FREED)
    movq -40(%rbp), %rbx
    cmpq $FREED, %rbx
    jne esle_5

    # size = size + sizeNext + 16
    movq -24(%rbp), %rbx  # %rbx = size
    addq -48(%rbp), %rbx  # %rbx = size + sizeNext
    addq $16, %rbx        # %rbx = size + sizeNext + 16
    movq %rbx, -24(%rbp)  # size = %rbx

    # next = next + sizeNext + 16
    movq -32(%rbp), %rbx  # %rbx = next
    addq -48(%rbp), %rbx  # %rbx = next + sizeNext
    addq $16, %rbx        # %rbx = next + sizeNext + 16
    movq %rbx, -32(%rbp)  # next = %rbx

    jmp end_if_5

esle_5:
    jmp end_while_3  # break

end_if_5:
    jmp while_3

end_while_3:

    movq -8(%rbp), %rbx  # %rbx = ptr

    # fillBlock(ptr, FREED, size)
    pushq %rdi            # saving %rdi
    movq -24(%rbp), %rdx  # param3: size
    movq $FREED, %rsi     # prarm2: state FREED
    movq -8(%rbp), %rdi   # param1: ptr 
    call fillBlock        # %rax contains the start of the allocated block
    popq %rdi             # restoring %rdi

end_if_4:
    # ptr = ptr + 16 + size
    movq -8(%rbp), %rbx   # %rbx = ptr
    addq -24(%rbp), %rbx  # %rbx = ptr + size
    addq $16, %rbx        # %rbx = ptr + size + 16
    movq %rbx, -8(%rbp)   # ptr  = ptr + size + 16

    jmp while_2

end_while_2:
    # return 1
    movq $1, %rax
    jmp return_asMalloc_freeMem

return_asMalloc_freeMem:
    addq $48, %rsp  # restoring pilha
    popq %rbp       # popping %rbp
    ret


# void asMalloc_printMap()
# prints the map of the heap
# local variables and return value:
#   -8(%rbp)  = ptr
#   -16(%rbp) = state
#   -24(%rbp) = size
asMalloc_printMap:
    pushq %rbp
    movq %rsp, %rbp
    pushq %r12       # saving %12, used by the callee
    subq $24, %rsp   # allocating LVs
    
    # void *ptr = HEAP_TOP_INITIAL
    movq HEAP_TOP_INITIAL, %rbx
    movq %rbx, -8(%rbp)

while_4: # (ptr < HEAP_TOP)
    movq -8(%rbp), %rbx
    cmpq HEAP_TOP, %rbx
    jge end_while_4

    # state = *ptr
    movq -8(%rbp), %rbx
    movq (%rbx), %rbx
    movq %rbx, -16(%rbp)

    # size = *(ptr + 8)
    movq -8(%rbp), %rbx
    addq $8, %rbx
    movq (%rbx), %rbx
    movq %rbx, -24(%rbp)

    # printf("################")
    movq $STR_HEADER, %rdi
    call printf

# if_6: (state == FREED)
    movq -16(%rbp), %rbx
    cmp $FREED, %rbx
    jne else_6

    # chatState = "-"
    movq $STR_FREED, %rcx
    jmp end_if_6

else_6:
    # chatState = "+"
    movq $STR_FILLED, %rcx

end_if_6:
    movq $0, %rdi         # i = 0
    movq -24(%rbp), %rbx  # %rbx = size

for_1: # (int i = 0; i < size; i++)
    cmpq %rbx, %rdi
    jge fim_for_1

    pushq %rdi             # saving %rdi
    pushq %rcx             # saving %r12
    movq %rcx, %rsi        # param 2: chatState
    movq $STR_PRINT, %rdi  # param 1: "%s"
    call printf            # printf(chatState)
    popq %rcx              # restoring %r12
    popq %rdi              # restoring %rdi
    addq $1, %rdi          # i++
    
    jmp for_1

fim_for_1:
    # ptr = ptr + 16 + size
    movq -8(%rbp), %rbx   # %rbx = ptr
    addq -24(%rbp), %rbx  # %rbx = ptr + size
    addq $16, %rbx        # %rbx = ptr + size + 16
    movq %rbx, -8(%rbp)   # ptr  = ptr + size + 16
    
    jmp while_4
    
end_while_4:
    # printf("\n")
    movq $STR_NEWLINE, %rdi  # "\n"
    call printf

    addq $24, %rsp  # restoring pilha
    popq %r12       # restoring %r12, used by the callee
    popq %rbp       # popping %rbp
    ret
