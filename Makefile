# Makefile for GetBaseCountsCram
# Uses local htslib directory

CXX = g++
CXXFLAGS = -O3 -std=c++11 -fopenmp -Wall

# Use local htslib
HTSLIB_DIR = ./htslib
INCLUDES = -I$(HTSLIB_DIR)
HTSLIB = $(HTSLIB_DIR)/libhts.a

# Static linking flags (disable if causing issues)
# STATIC_FLAGS = -static -static-libgcc -static-libstdc++
STATIC_FLAGS = 
LIBS = $(HTSLIB) -lz -lpthread -lm

# Target executable
TARGET = GetBaseCountsCram

# Source files
SOURCES = GetBaseCountsMultiSample.cpp

# Object files
OBJECTS = $(SOURCES:.cpp=.o)

# Default target
all: check_htslib $(TARGET)

# Check if htslib is built
check_htslib:
	@if [ ! -f $(HTSLIB) ]; then \
		echo "Error: $(HTSLIB) not found. Please build htslib first:"; \
		echo "  cd $(HTSLIB_DIR) && make"; \
		exit 1; \
	fi

# Link the executable (static)
$(TARGET): $(OBJECTS)
	$(CXX) $(CXXFLAGS) $(STATIC_FLAGS) -o $@ $^ $(LIBS)

# Compile source files
%.o: %.cpp
	$(CXX) $(CXXFLAGS) $(INCLUDES) -c $< -o $@

# Clean build files
clean:
	rm -f $(OBJECTS) $(TARGET)

# Install target (optional)
install: $(TARGET)
	install -m 0755 $(TARGET) /usr/local/bin/

# Uninstall target (optional)
uninstall:
	rm -f /usr/local/bin/$(TARGET)

# Build htslib
build_htslib:
	@echo "Building htslib..."
	cd $(HTSLIB_DIR) && make clean && ./configure --disable-libcurl --disable-s3 --disable-gcs --disable-bz2 --disable-lzma && make CFLAGS="-g -Wall -O2 -fvisibility=hidden"
	
# Rebuild htslib from scratch
rebuild_htslib:
	@echo "Rebuilding htslib from scratch..."
	cd $(HTSLIB_DIR) && make clean && rm -f config.h Makefile && ./configure --disable-libcurl --disable-s3 --disable-gcs --disable-bz2 --disable-lzma && make CFLAGS="-g -Wall -O2 -fvisibility=hidden"

.PHONY: all clean install uninstall check_htslib build_htslib

