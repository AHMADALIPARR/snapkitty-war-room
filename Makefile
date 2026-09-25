NASM ?= nasm
LD ?= ld
ASM_SRC = asm/mcpd.asm
BIN = build/mcpd

all: $(BIN)

$(BIN): $(ASM_SRC)
	mkdir -p build
	$(NASM) -f elf64 -o build/mcpd.o $(ASM_SRC)
	$(LD) -o $(BIN) build/mcpd.o

clean:
	rm -rf build

serve: $(BIN)
	./$(BIN)

harness: $(BIN)
	python3 harness/harness.py

.PHONY: all clean serve harness
