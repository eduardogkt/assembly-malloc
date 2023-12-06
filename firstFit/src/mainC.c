#include "libAssemblyMalloc.h"

#ifdef C_IMPLEMENTATION

#define _XOPEN_SOURCE
#define _XOPEN_SOURCE_EXTENDED
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>

#define FREED 0
#define FILLED 1

void *heapTopInitial;
void *heapTop;

void printfBufferInit() {
    printf("*************** allocator first-fit c ***************\n");
}

void asMalloc_initAllocator() {
    // alocating space for the printf buffer
    printfBufferInit();

    // initial value of heap
    heapTopInitial = sbrk(0);
    heapTop = heapTopInitial;
}

void asMalloc_finishAllocator() {
    brk(heapTopInitial);
    heapTop = heapTopInitial;
}

// auxiliary function to help visualize
void assign(long int *value, void *ptr) {
    *value = *(long int *) ptr;  // value = *(ptr)
}

void fillBlock(void *ptr, long int state, long int size) {
    (*(long int *)(ptr))     = state;  // *(ptr) = state
    (*(long int *)(ptr + 8)) = size;   // *(ptr + 8) = size
}

void *asMalloc_allocMem(long int numBytes) {
    void *ptr = heapTopInitial;
    while (ptr < heapTop) {
        long int state, size;
        assign(&state, ptr);       // state = ptr
        assign(&size, (ptr + 8));  // size = ptr + 8

        if (numBytes <= size && state == FREED) {
            fillBlock(ptr, FILLED, numBytes);
            long int sizeNext = (size - numBytes) - 16;

            // if the next block has only 1 byte alloc the whole block
            if (sizeNext >= 1) {
                // adjusting block info
                void *next = ptr + 16 + numBytes;
                fillBlock(next, FREED, sizeNext);
            }
            else {
                // assigning the size of the block
                (*(long int *)(ptr+8)) = size;  // *(ptr + 8) = size
            }

            return (ptr + 16);
        }
        ptr = ptr + 16 + size;
    }
    // allocate space at the end of the heap
    void *heapTopNew = heapTop + numBytes + 16;
    brk(heapTopNew);
    fillBlock(heapTop, FILLED, numBytes);
    void *blockStart = heapTop + 16;
    heapTop = heapTopNew;
    
    return blockStart;
}

int asMalloc_freeMem(void *block) {
    if (block < heapTopInitial || block > heapTop) {
        return 0;
    } 
    // mark block as freed
    void *ptr = block;
    ptr = ptr - 16;
    (*(long int *)ptr) = FREED;

    // goes from start to end until find the first free block
    // verify the blocks after the free block 
    // if free - merge with the free block found
    // if filled - create the block with the new size and pass to the next
    ptr = heapTopInitial;
    while (ptr < heapTop) {
        long int state, size;
        assign(&state, ptr);         // state = ptr
        assign(&size, (ptr + 8));  // size = ptr + 8

        if (state == FREED) {
            // verify the next nodes e colapse the free nodes
            void *next = ptr + 16 + size;

            while (next < heapTop) {
                long int stateNext, sizeNext;
                assign(&stateNext, next);       // state = ptr
                assign(&sizeNext, (next + 8));  // size = ptr + 8
                
                if (stateNext == FREED) {
                    // new size including 16 bytes of the header
                    size = size + sizeNext + 16;
                    // next node to verify if it's empty
                    next = next + sizeNext + 16;
                }
                else break;
            }
            fillBlock(ptr, FREED, size);
        }
        ptr = ptr + 16 + size; // move on to the next block
    }
    return 1;
}

void asMalloc_printMap() {
    void* ptr = heapTopInitial;

    while (ptr < heapTop) {
        long int state, size;
        assign(&state, ptr);       // state = ptr
        assign(&size, (ptr + 8));  // size = ptr + 8
        
        // header
        printf("################");
        
        char *charState = (state == FREED) ? "-" : "+";

        // prints block
        for (int i = 0; i < size; i++) {
            printf("%s", charState);
        }

        ptr = ptr + 16 + size;
    }
    printf("\n");
}

int main(int argc, char **argv) {
    void *a, *b, *c, *d, *e, *f;

    asMalloc_initAllocator();             // expected print
    asMalloc_printMap();                  // <empty>

    a = (void *) asMalloc_allocMem(10);
    asMalloc_printMap();                  // ################**********
    
    b = (void *) asMalloc_allocMem(4);
    asMalloc_printMap();                  // ################**********##############****
    
    asMalloc_freeMem(a);
    asMalloc_printMap();                  // ################----------##############****
    
    c = (void *) asMalloc_allocMem(8);
    asMalloc_printMap();                  // ################++++++++++##############**** (keep as if 10 bytes had been allocated)

    asMalloc_freeMem(b);
    asMalloc_printMap();                  // ################++++++++++##############----

    d = asMalloc_allocMem(75);
    asMalloc_printMap();                  // ################++++++++++################----################+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    e = asMalloc_allocMem(25);
    asMalloc_printMap();                  // ################++++++++++################----################+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++################+++++++++++++++++++++++++

    asMalloc_freeMem(d);
    asMalloc_printMap();                  // ################++++++++++################-----------------------------------------------------------------------------------------------################+++++++++++++++++++++++++

    f = asMalloc_allocMem(50);
    asMalloc_printMap();                  // ################++++++++++################++++++++++++++++++++++++++++++++++++++++++++++++++################-----------------------------################+++++++++++++++++++++++++

    asMalloc_freeMem(c);
    asMalloc_printMap();                  // ################----------################++++++++++++++++++++++++++++++++++++++++++++++++++################-----------------------------################+++++++++++++++++++++++++

    asMalloc_freeMem(f);
    asMalloc_printMap();                  // ################-------------------------------------------------------------------------------------------------------------------------################+++++++++++++++++++++++++

    asMalloc_freeMem(e);
    asMalloc_printMap();                  // ################------------------------------------------------------------------------------------------------------------------------------------------------------------------

    asMalloc_finishAllocator();
}
#endif

#ifndef C_IMPLEMENTATION
#include <stdio.h>

int main(int argc, char **argv) {
    void *a, *b, *c, *d, *e, *f;

    asMalloc_initAllocator();               // Impressão esperada
    asMalloc_printMap();                  // <vazio>

    a = (void *) asMalloc_allocMem(10);
    asMalloc_printMap();                  // ################**********
    
    b = (void *) asMalloc_allocMem(4);
    asMalloc_printMap();                  // ################**********##############****
    
    asMalloc_freeMem(a);
    asMalloc_printMap();                  // ################----------##############****
    
    c = (void *) asMalloc_allocMem(8);
    asMalloc_printMap();                  // ################++++++++++##############**** (mantem com se tivesse alocado 10)

    asMalloc_freeMem(b);
    asMalloc_printMap();                  // ################++++++++++##############----

    d = asMalloc_allocMem(75);
    asMalloc_printMap();                  // ################++++++++++################----################+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    e = asMalloc_allocMem(25);
    asMalloc_printMap();                  // ################++++++++++################----################+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++################+++++++++++++++++++++++++

    asMalloc_freeMem(d);
    asMalloc_printMap();                  // ################++++++++++################-----------------------------------------------------------------------------------------------################+++++++++++++++++++++++++

    f = asMalloc_allocMem(50);
    asMalloc_printMap();                  // ################++++++++++################++++++++++++++++++++++++++++++++++++++++++++++++++################-----------------------------################+++++++++++++++++++++++++

    asMalloc_freeMem(c);
    asMalloc_printMap();                  // ################----------################++++++++++++++++++++++++++++++++++++++++++++++++++################-----------------------------################+++++++++++++++++++++++++

    asMalloc_freeMem(f);
    asMalloc_printMap();                  // ################-------------------------------------------------------------------------------------------------------------------------################+++++++++++++++++++++++++

    asMalloc_freeMem(e);
    asMalloc_printMap();                  // ################------------------------------------------------------------------------------------------------------------------------------------------------------------------

    asMalloc_finishAllocator();
}

#endif
