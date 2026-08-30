# Makefile for Tamper Logging Library with Real-time Alerts

CC = gcc
CFLAGS = -Wall -O2
LIBS = -lcurl -lssl -lcrypto -lsqlite3 -lpthread

# Database path
DB_PATH = /home/pico/calibris/data/mydata.db

all: libtamper_realtime.a test_tamper

# Compile library object file
tamper_logs_realtime.o: tamper_logs_realtime.c tamper_logs_realtime.h
	$(CC) $(CFLAGS) -c tamper_logs_realtime.c -o tamper_logs_realtime.o

# Create static library
libtamper_realtime.a: tamper_logs_realtime.o
	ar rcs libtamper_realtime.a tamper_logs_realtime.o
	@echo "✅ Library created: libtamper_realtime.a"

# Compile test/example program
test_tamper: example_usage.c tamper_logs_realtime.o
	$(CC) $(CFLAGS) example_usage.c tamper_logs_realtime.o -o test_tamper $(LIBS)
	@echo "✅ Test program created: ./test_tamper"

# Clean build files
clean:
	rm -f *.o *.a test_tamper
	@echo "🧹 Cleaned build files"

# Install library (copy to /usr/local/lib)
install: libtamper_realtime.a
	sudo cp libtamper_realtime.a /usr/local/lib/
	sudo cp tamper_logs_realtime.h /usr/local/include/
	@echo "✅ Library installed to /usr/local/lib"

# Uninstall library
uninstall:
	sudo rm -f /usr/local/lib/libtamper_realtime.a
	sudo rm -f /usr/local/include/tamper_logs_realtime.h
	@echo "🗑️  Library uninstalled"

# Run test
test: test_tamper
	@echo "🧪 Running test..."
	./test_tamper

# Create database directory
init-db:
	mkdir -p $(dir $(DB_PATH))
	@echo "✅ Database directory created"

# Help
help:
	@echo "Tamper Logging Library - Build Commands"
	@echo "========================================"
	@echo "make              - Build library and test program"
	@echo "make clean        - Remove build files"
	@echo "make test         - Build and run test program"
	@echo "make install      - Install library system-wide"
	@echo "make uninstall    - Remove installed library"
	@echo "make init-db      - Create database directory"
	@echo "make help         - Show this help message"

.PHONY: all clean install uninstall test init-db help
