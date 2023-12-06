t =
TARGET = $(t)

# compilador
CC = gcc
SC = as

# flags
FLAGS_C = -g
FLAGS_S = -g

# bibliotecas dinamicas
DYNAMIC_LINKER = -dynamic-linker $(LINK_LIBS) $(OTHER_LIBS)
OTHER_LIBS = -lc
LINK_LIBS = \
/lib/x86_64-linux-gnu/ld-linux-x86-64.so.2 \
/usr/lib/x86_64-linux-gnu/crt1.o \
/usr/lib/x86_64-linux-gnu/crti.o \
/usr/lib/x86_64-linux-gnu/crtn.o

# diretorios
SOURCE_DIR = src
OBJECT_DIR = bin

# arquivos c
SOURCE_FILES_C = $(wildcard $(SOURCE_DIR)/*.c)
HEADER_FILES_C = $(wildcard $(SOURCE_DIR)/*.h)
OBJECT_FILES_C = $(patsubst $(SOURCE_DIR)/%,$(OBJECT_DIR)/%,$(SOURCE_FILES_C:.c=.o))

# arquivos s
SOURCE_FILES_S = $(wildcard $(SOURCE_DIR)/*.s)
OBJECT_FILES_S = $(patsubst $(SOURCE_DIR)/%,$(OBJECT_DIR)/%,$(SOURCE_FILES_S:.s=.o))

# validando entrada
ifeq ($(MAKECMDGOALS),clean)
    # caso o alvo seja clean, nao mostra erro
else ifeq ($(MAKECMDGOALS),purge)
    # caso o alvo seja purge, nao mostra erro
else ifeq ($(TARGET),)
    $(error O target não foi especificado. Use 'make a t=alvo' ou 'make lds t=alvo')
endif

all: mkdir_obj alloc

# for c implementation
c: FLAGS_C += -D C_IMPLEMENTATION
c: gcc

# ligação .s e .c
alloc: $(OBJECT_FILES_C) $(OBJECT_FILES_S)
	$(CC) $^ -o $(TARGET) -no-pie

# compilação c
$(OBJECT_FILES_C): $(SOURCE_FILES_C)
	$(CC) $(FLAGS_C) -c $< -o $@

# compilação s
$(OBJECT_FILES_S): $(SOURCE_FILES_S)
	$(SC) $(FLAGS_S) $< -o $@

as:
	as $(SOURCE_DIR)/$(TARGET).s -o $(TARGET).o $(FLAGS_S)

ld: as
	ld $(TARGET).o -o $(TARGET) $(DYNAMIC_LINKER) $(FLAGS_S)

gcc:
	$(CC) src/$(TARGET).c -o $(TARGET) $(FLAGS_C)

mkdir_obj:
	mkdir -p $(OBJECT_DIR)

clean:
	rm -f $(OBJECT_FILES_C) $(OBJECT_FILES_S)
	rm -r $(OBJECT_DIR)

purge: clean
	rm -f $(TARGET)
