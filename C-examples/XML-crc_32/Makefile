CC      ?= cc
CFLAGS  ?= -Wall -Wextra -O2 -std=c11
LDLIBS  := $(shell pkg-config --libs expat 2>/dev/null || echo -lexpat)
CFLAGS  += $(shell pkg-config --cflags expat 2>/dev/null)

TARGET  := build/xml_crc_32
SRC     := src/xml_crc_32.c

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) -o $@ $(SRC) $(LDLIBS)

clean:
	rm -f $(TARGET)
