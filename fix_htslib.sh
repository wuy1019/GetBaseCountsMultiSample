#!/bin/bash
# Fix htslib 1.22.1 compilation issues

set -e

echo "=== Fixing htslib 1.22.1 for compilation ==="

cd htslib

# Fix 1: Create missing htslib.pc.in file
if [ ! -f "htslib.pc.in" ]; then
    echo "Creating missing htslib.pc.in..."
    cat > htslib.pc.in << 'EOF'
prefix=@prefix@
exec_prefix=@exec_prefix@
libdir=@libdir@
includedir=@includedir@
datarootdir=@datarootdir@

Name: htslib
Description: C library for high-throughput sequencing data formats
Version: @PACKAGE_VERSION@
Requires:
Libs: -L${libdir} -lhts @static_ldflags@
Libs.private: @static_LIBS@
Cflags: -I${includedir}
EOF
fi

# Fix 2: Patch simd.c to add missing header
if [ -f "simd.c" ]; then
    echo "Patching simd.c to add missing SSE3 header..."
    # Check if already patched
    if ! grep -q "#include <tmmintrin.h>" simd.c; then
        # Add the header after emmintrin.h
        sed -i '/#include <emmintrin.h>/a #include <tmmintrin.h>  \/\/ For SSSE3 intrinsics' simd.c
        echo "simd.c patched successfully"
    else
        echo "simd.c already patched"
    fi
fi

# Fix 3: Create a simple config.h if needed
if [ ! -f "config.h" ]; then
    echo "Creating minimal config.h..."
    cat > config.h << 'EOF'
/* Minimal config.h for htslib compilation */
#ifndef _XOPEN_SOURCE
#define _XOPEN_SOURCE 600
#endif
#define HTS_VERSION_TEXT "1.22.1"
#define HAVE_DRAND48 1
#define HAVE_LIBZ 1
EOF
fi

cd ..

echo "htslib fixes applied successfully"

