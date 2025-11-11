#!/bin/bash
# Test script to verify GetBaseCountsCram produces identical results to GetBaseCountsMultiSample

set -e

echo "=== Testing GetBaseCountsCram with demo data ==="
echo ""

# Check if executable exists
if [ ! -f GetBaseCountsCram ]; then
    echo "Error: GetBaseCountsCram not found. Please run ./build.sh first."
    exit 1
fi

# Check if demo directory exists
if [ ! -d demo ]; then
    echo "Error: demo directory not found."
    exit 1
fi

cd demo

# Check required files
REQUIRED_FILES=(
    "hs37d5.fa"
    "hs37d5.fa.fai"
    "BC250P0506-Q1APP92KXF1-L000KBP1.final.bam"
    "BC250P0506-Q1APP92KXF1-L000KBP1.final.bam.bai"
    "tmpin.vcf"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "Error: Required file not found: $file"
        exit 1
    fi
done

echo "Running GetBaseCountsCram..."
../GetBaseCountsCram \
    --fasta hs37d5.fa \
    --bam BC250P0506-Q1APP92KXF1-L000KBP1:BC250P0506-Q1APP92KXF1-L000KBP1.final.bam \
    --vcf tmpin.vcf \
    --output tmpout_new.vcf \
    --thread 8

if [ ! -f tmpout_new.vcf ]; then
    echo "Error: Output file tmpout_new.vcf was not created."
    exit 1
fi

echo ""
echo "Output file created: tmpout_new.vcf"
echo ""

# If original output exists, compare
if [ -f tmpout.vcf ]; then
    echo "Comparing with original output (tmpout.vcf)..."
    echo ""
    
    if diff -q tmpout.vcf tmpout_new.vcf > /dev/null 2>&1; then
        echo "✓ SUCCESS: Results are identical to original GetBaseCountsMultiSample!"
        echo ""
        
        # Show some statistics
        echo "Statistics:"
        echo "  Total lines: $(wc -l < tmpout_new.vcf)"
        echo "  Header lines: $(grep -c "^#" tmpout_new.vcf || echo 0)"
        echo "  Variant lines: $(grep -vc "^#" tmpout_new.vcf || echo 0)"
    else
        echo "✗ WARNING: Results differ from original output"
        echo ""
        echo "Showing first 10 differences:"
        diff tmpout.vcf tmpout_new.vcf | head -20
        echo ""
        echo "Full diff saved to: diff_output.txt"
        diff tmpout.vcf tmpout_new.vcf > diff_output.txt || true
    fi
else
    echo "Note: Original output file (tmpout.vcf) not found for comparison."
    echo "New output statistics:"
    echo "  Total lines: $(wc -l < tmpout_new.vcf)"
    echo "  Header lines: $(grep -c "^#" tmpout_new.vcf || echo 0)"
    echo "  Variant lines: $(grep -vc "^#" tmpout_new.vcf || echo 0)"
fi

echo ""
echo "=== Test completed ==="

