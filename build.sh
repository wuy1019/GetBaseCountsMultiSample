#!/bin/bash
# Build script for GetBaseCountsCram

set -e

echo "=== Building GetBaseCountsCram with local htslib ==="
echo ""

# Check if htslib directory exists
if [ ! -d "htslib" ]; then
    echo "Error: htslib directory not found!"
    echo "Please ensure htslib source is in ./htslib/"
    exit 1
fi

# Apply fixes to htslib first
echo "Applying htslib 1.22.1 fixes..."
bash fix_htslib.sh

# Build htslib if needed
if [ ! -f "htslib/libhts.a" ]; then
    echo ""
    echo "Building htslib 1.22.1..."
    cd htslib
    
    # Clean any previous failed build
    make clean 2>/dev/null || true
    
    # Configure with minimal dependencies
    echo "Configuring htslib..."
    if [ ! -f "config.mk" ]; then
        ./configure --disable-libcurl --disable-s3 --disable-gcs --disable-bz2 --disable-lzma 2>&1 | tail -10
    fi
    
    # Build with proper flags
    echo ""
    echo "Compiling htslib (this may take a few minutes)..."
    make -j$(nproc) lib-static 2>&1 | tail -30
    
    cd ..
    
    if [ -f "htslib/libhts.a" ]; then
        echo ""
        echo "✓ htslib build complete: $(ls -lh htslib/libhts.a | awk '{print $5}')"
        echo ""
    else
        echo ""
        echo "✗ Error: Failed to build htslib/libhts.a"
        echo "Please check the error messages above"
        exit 1
    fi
else
    echo "htslib already built (libhts.a found)"
    echo ""
fi

# Clean previous build
echo "Cleaning previous GetBaseCountsCram build..."
make -f Makefile clean 2>/dev/null || true

# Build
echo "Compiling GetBaseCountsCram..."
make -f Makefile -j$(nproc)

if [ -f GetBaseCountsCram ]; then
    echo ""
    echo "=== Build Successful ==="
    echo "Executable: ./GetBaseCountsCram"
    echo ""
    
    # Show file info
    ls -lh GetBaseCountsCram
    echo ""
    
    # Check if it's statically linked
    if ldd GetBaseCountsCram 2>&1 | grep -q "not a dynamic executable"; then
        echo "✓ Static linking successful - fully portable"
    else
        echo "Note: Dynamic linking detected. Dependencies:"
        ldd GetBaseCountsCram
    fi
    
    echo ""
    echo "Run './GetBaseCountsCram --help' to see usage."
else
    echo ""
    echo "=== Build Failed ==="
    exit 1
fi

