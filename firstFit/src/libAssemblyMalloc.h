/*
 * library of procedures utilized by the allocator 
 * implemented in assembly
*/

#ifndef _ASSEMBLY_MALLOC_H_
#define _ASSEMBLY_MALLOC_H_

// execute syscall brk to obtain the address of the 
// current top of the heap and stores it in a
// global variable, heapTopInitial
void asMalloc_initAllocator();

// execute syscall brk to restore the original
// value of the heap, that is in heapTopInitial
void asMalloc_finishAllocator();

// 1. searches for a free block with size bigger or
//    equal to num_bytes;
// 2. if found, mark the block as filled and
//    returns the block's initial address;
// 3. if not found, opens space for a new block,
//    mark the block as filled and returns the
//    block's initial address.
void *asMalloc_allocMem(long int numBytes);

// mark the block as freed and merge the free the 
// consecutive free blocks
int asMalloc_freeMem(void *block);

// prints a map of the heap memory region.
// each byte of the node's gerencial part must be
// printted with a "#" char. the char used to print
// the bytes of each node's block depends whether the
// is freed ("-"), or filled ("+")
void asMalloc_printMap();

#endif // _ASSEMBLY_MALLOC_H_