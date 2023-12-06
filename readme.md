# Malloc implementation in assembly

## Malloc API
  Implementaion of a malloc API in assembly using two methods of
allocation the block in the heap: *first-fit* and *worst-fit*.

---

## Execution
  Because this software package doesn't have a specific way to be 
used, it doesn't specify a form of execution of the main, besides
using `./main`. The source file .c are only used to prompt some 
tests used to understand the functioning of the API.

  The makefile inside a directory is specific of the method and it's
run using only `make` (inside the directory). The makefile outside 
the directories is run with `make t=target`, where target is the
path for the main file that implements *first-fit* (firstFit/src/
mainC) or *worst-fit* (worstFit/src/mainC).

---

## Structure and Functions
  The files are structured in 2 main directories, one for each
method implemented, as shown below:
```
|--- firstFit/
|     |--- makefile
|     |
|     |--- src/
|          |--- libAssemblyMalloc.h
|          |--- mainC.c
|  
|--- worstFit/
|     |--- makefile
|     |
|     |--- src/
|          |--- libAssemblyMalloc.h
|          |--- mainC.c
|
|--- makefile
|--- readme.md
```

  The functions used in this API are on the library 
*libAssemblyMalloc*:  
```
  void asMalloc_initAllocator();  

  void asMalloc_finishAllocator();  
  
  void *asMalloc_allocMem(long int numBytes);  
  
  int asMalloc_freeMem(void *block);  
  
  void asMalloc_printMap();  
```

---

## Implemention
  The implementation uses a linked list method, where the value of 
the initial top of the heap and current top are stores in global 
varialbes heapTopInitial and heapTop, respectively. Each node of 
the list have information about the size and state (filled/freed) 
of the space allocated by the node. The node is composed by this 
infos, that ocupy 16 bytes, and the block it self. There are two 
different forms of allocating memory that wore implemented: 
*first-fit* and *worst-fit*.

  In the program, *%rax* is utilized only to handle return values of
functions. This is made to avoid errors (like changing the value 
by accident). 

### First Fit
  Method where the block allocated is placed on the first space
found that fits the number of bytes needed. If no node with enough 
space is found, a new node is allocated at the end ot the list with
the necessary bytes.

### Worst Fit

  Method where the block allocated is placed on the biggest space
found that fits the number of bytes needed. If no node with enough 
space is found, a new node is allocated at the end ot the list with
the necessary bytes.
