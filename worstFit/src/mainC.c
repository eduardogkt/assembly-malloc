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
    printf("*************** allocator worst-fit c ***************\n");
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

    long int sizeBiggest = 0;
    void *ptrBiggest = NULL;

    while (ptr < heapTop) {
        long int state, size;
        assign(&state, ptr);       // state = ptr
        assign(&size, (ptr + 8));  // size = ptr + 8

        if (numBytes <= size && state == FREED) {
            if (size > sizeBiggest) {
                sizeBiggest = size;
                ptrBiggest = ptr;
            }
        }
        ptr = ptr + 16 + size;
    }

    if (ptrBiggest != NULL) {
        long int tam_prox_bloco = (sizeBiggest - numBytes) - 16;
        
        fillBlock(ptrBiggest, FILLED, numBytes);

        // caso o bloco seguinte tenha menos de 16 bytes
        // considera como se tivesse alocado o size do bloco
        if (tam_prox_bloco >= 1) {
            // arrumando informações do proximo bloco
            void *prox = ptrBiggest + 16 + numBytes;
            fillBlock(prox, FREED, tam_prox_bloco);
        }
        else {
            // colocando size completo do bloco
            (*(long int *)(ptrBiggest + 8)) = sizeBiggest;  // *(maior_ptr + 8) = size
        }

        return (ptrBiggest + 16);
    }

    // aloca espaco no final 
    void *heapTopNew = heapTop + numBytes + 16;
    brk(heapTopNew);
    fillBlock(heapTop, FILLED, numBytes);
    void *ini_bloco = heapTop + 16;
    heapTop = heapTopNew;
    
    return ini_bloco;
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
    long int *k, *l, *m, *n, *o, *p, *q;

    asMalloc_initAllocator();
    
    k = asMalloc_allocMem(50);
    l = asMalloc_allocMem(100);
    m = asMalloc_allocMem(150);
    n = asMalloc_allocMem(200);
    asMalloc_printMap();
    printf("\n\n");

    asMalloc_freeMem(k);
    asMalloc_freeMem(n);
    asMalloc_printMap();
    printf("\n\n");

    o = asMalloc_allocMem(10);
    asMalloc_printMap();
    printf("\n\n");

    p = asMalloc_allocMem(10);
    asMalloc_printMap();
    printf("\n\n");
    
    q = asMalloc_allocMem(10);
    asMalloc_printMap();
    printf("\n\n");

    q = asMalloc_allocMem(10);
    asMalloc_printMap();
    printf("\n\n");

    q = asMalloc_allocMem(10);
    asMalloc_printMap();
    printf("\n\n");

    q = asMalloc_allocMem(10);
    asMalloc_printMap();
    printf("\n\n");

    q = asMalloc_allocMem(10);
    asMalloc_printMap();
    printf("\n\n");

    q = asMalloc_allocMem(10);
    asMalloc_printMap();
    printf("\n\n");

    q = asMalloc_allocMem(10);
    asMalloc_printMap();
    printf("\n\n");

    q = asMalloc_allocMem(10);
    asMalloc_printMap();
    printf("\n\n");

    asMalloc_finishAllocator();
}
#endif

#ifndef C_IMPLEMENTATION

#include <stdio.h>

int main(int argc, char **argv) {
    long int *k, *l, *m, *n, *o, *p, *q;

    asMalloc_initAllocator();
    
    k = asMalloc_allocMem(50);
    l = asMalloc_allocMem(100);
    m = asMalloc_allocMem(150);
    n = asMalloc_allocMem(200);
    asMalloc_printMap();
    printf("\n\n");

    asMalloc_freeMem(k);
    asMalloc_freeMem(n);
    asMalloc_printMap();
    printf("\n\n");

    o = asMalloc_allocMem(10);
    asMalloc_printMap();
    printf("\n\n");

    p = asMalloc_allocMem(10);
    asMalloc_printMap();
    printf("\n\n");
    
    q = asMalloc_allocMem(10);
    asMalloc_printMap();
    printf("\n\n");

    o = asMalloc_allocMem(10);
    asMalloc_printMap();
    printf("\n\n");

    p = asMalloc_allocMem(10);
    asMalloc_printMap();
    printf("\n\n");
    
    q = asMalloc_allocMem(10);
    asMalloc_printMap();
    printf("\n\n");

    o = asMalloc_allocMem(10);
    asMalloc_printMap();
    printf("\n\n");

    p = asMalloc_allocMem(10);
    asMalloc_printMap();
    printf("\n\n");
    
    q = asMalloc_allocMem(10);
    asMalloc_printMap();
    printf("\n\n");

    q = asMalloc_allocMem(10);
    asMalloc_printMap();
    printf("\n\n");

    q = asMalloc_allocMem(10);
    asMalloc_printMap();
    printf("\n\n");

    asMalloc_finishAllocator();
}

#endif
