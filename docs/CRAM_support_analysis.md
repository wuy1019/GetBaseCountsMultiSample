# GetBaseCountsMultiSample CRAM 格式支持分析报告

## 一、当前状态分析

### 1.1 程序使用的库
通过对源代码的分析，GetBaseCountsMultiSample程序使用的是 **BamTools** 库来处理BAM文件：

```cpp
#include "api/BamReader.h"
using namespace BamTools;

// 在代码中使用BamReader打开文件
BamReader my_bam_reader;
if(!my_bam_reader.Open(it_bam->second))
{
    cerr << "[ERROR] fail to open input bam file: " << it_bam->second << endl;
    exit(1);
}
```

### 1.2 BamTools库的局限性
**BamTools库不支持CRAM格式**，原因如下：
- BamTools是专门为BAM格式设计的库
- 底层使用标准C语言的 `fopen()` 函数直接读取文件
- 只能处理BAM格式的BGZF压缩数据
- 没有实现CRAM格式的解析逻辑

### 1.3 结论
**GetBaseCountsMultiSample程序目前不支持CRAM 3.0格式作为输入文件。**

---

## 二、解决方案

### 方案1：使用samtools转换CRAM到BAM（推荐的快速方案）

这是最简单且不需要修改程序的方案。

#### 2.1.1 转换单个文件
```bash
# 基本转换
samtools view -b -o output.bam input.cram

# 使用参考基因组（CRAM通常需要参考基因组）
samtools view -b -T reference.fa -o output.bam input.cram

# 使用多线程加速
samtools view -@ 8 -b -T reference.fa -o output.bam input.cram

# 转换后创建索引
samtools index output.bam
```

#### 2.1.2 批量转换脚本
```bash
#!/bin/bash
# batch_convert_cram_to_bam.sh

REF_GENOME="/path/to/reference.fa"
THREADS=8

for cram_file in *.cram; do
    bam_file="${cram_file%.cram}.bam"
    echo "Converting $cram_file to $bam_file..."
    samtools view -@ $THREADS -b -T $REF_GENOME -o $bam_file $cram_file
    echo "Creating index for $bam_file..."
    samtools index $bam_file
done

echo "All conversions completed!"
```

#### 2.1.3 优缺点
**优点：**
- 无需修改程序代码
- 实施简单快速
- 稳定可靠

**缺点：**
- 需要额外的磁盘空间（BAM文件比CRAM文件大）
- 需要转换时间
- 需要维护两套数据

---

### 方案2：修改程序使用HTSlib库（长期方案）

HTSlib是现代的、功能强大的序列数据处理库，同时支持BAM、CRAM和SAM格式。

#### 2.2.1 为什么选择HTSlib
- 原生支持BAM、CRAM、SAM格式
- 支持CRAM 3.0及更高版本
- 维护活跃，是samtools的底层库
- 性能优异

#### 2.2.2 需要的修改步骤

**步骤1：安装HTSlib**
```bash
# 下载HTSlib
wget https://github.com/samtools/htslib/releases/download/1.18/htslib-1.18.tar.bz2
tar -xjf htslib-1.18.tar.bz2
cd htslib-1.18

# 编译安装
./configure --prefix=/path/to/install
make
make install
```

**步骤2：修改代码**
将BamTools API替换为HTSlib API。主要修改点：

```cpp
// 原代码使用BamTools
#include "api/BamReader.h"
using namespace BamTools;
BamReader my_bam_reader;
my_bam_reader.Open(filename);

// 改为使用HTSlib
#include <htslib/sam.h>
#include <htslib/hts.h>

samFile *fp = sam_open(filename, "r");  // 自动识别BAM/CRAM/SAM
bam_hdr_t *header = sam_hdr_read(fp);
hts_idx_t *idx = sam_index_load(fp, filename);
bam1_t *aln = bam_init1();
```

**步骤3：修改Makefile**
```makefile
# 原makefile
all:
	g++ -o3 -I./bamtools-master/include/ -L./bamtools-master/lib/ \
	    GetBaseCountsMultiSample.cpp -lbamtools -lz -o GetBaseCountsMultiSample -fopenmp

# 改为使用HTSlib
all:
	g++ -o3 -I/path/to/htslib/include -L/path/to/htslib/lib \
	    GetBaseCountsMultiSample.cpp -lhts -lz -lpthread -lcurl -llzma -lbz2 \
	    -o GetBaseCountsMultiSample -fopenmp
```

#### 2.2.3 优缺点
**优点：**
- 一次修改，永久支持多种格式
- 可以直接使用CRAM文件，节省磁盘空间
- 更现代化的API，功能更强大
- 长期维护更好

**缺点：**
- 需要大量代码修改（估计需要修改几百行）
- 需要测试确保功能一致性
- 开发周期较长
- 需要重新编译和测试

---

### 方案3：使用管道/FIFO实时转换（中间方案）

创建一个包装脚本，通过命名管道实时转换CRAM到BAM。

```bash
#!/bin/bash
# run_with_cram.sh

SAMPLE_NAME=$1
CRAM_FILE=$2
REF_GENOME=$3

# 创建临时FIFO
FIFO="/tmp/${SAMPLE_NAME}_$$.fifo"
mkfifo $FIFO

# 后台运行转换进程
samtools view -@ 4 -b -T $REF_GENOME $CRAM_FILE > $FIFO &

# 运行GetBaseCountsMultiSample，使用FIFO作为输入
# 注意：这种方法不适用于需要随机访问的情况

# 清理
rm $FIFO
```

**注意：** 由于GetBaseCountsMultiSample使用索引进行随机访问，此方案实际上不可行。

---

## 三、推荐方案

根据实际情况选择：

### 短期/临时使用 → **方案1（转换为BAM）**
如果您：
- 只是临时需要处理几个CRAM文件
- 有足够的磁盘空间
- 需要快速得到结果

**操作步骤：**
1. 使用samtools将CRAM转换为BAM
2. 创建BAM索引
3. 使用现有的GetBaseCountsMultiSample程序

### 长期/生产环境 → **方案2（迁移到HTSlib）**
如果您：
- 经常需要处理CRAM文件
- 磁盘空间有限
- 愿意投入开发时间

**需要考虑：**
- 代码修改工作量较大（可能需要数天到数周）
- 需要全面测试保证结果一致性
- 需要C++编程和HTSlib API的知识

---

## 四、参考资源

### 相关文档
- HTSlib官方文档: https://github.com/samtools/htslib
- Samtools手册: http://www.htslib.org/doc/samtools.html
- CRAM格式规范: https://samtools.github.io/hts-specs/CRAMv3.pdf

### 类似项目参考
- bam-readcount已经支持CRAM格式，可以参考其实现
- GATK等工具也已经从BamTools迁移到HTSlib

---

## 五、快速开始指南

如果您现在就需要处理CRAM文件，请按以下步骤操作：

```bash
# 1. 确保安装了samtools（1.10或更高版本）
samtools --version

# 2. 准备参考基因组（CRAM文件通常需要）
REF="/path/to/reference.fasta"

# 3. 转换CRAM为BAM
samtools view -@ 8 -b -T $REF -o sample.bam sample.cram

# 4. 创建索引
samtools index sample.bam

# 5. 使用GetBaseCountsMultiSample
./GetBaseCountsMultiSample \
    --fasta $REF \
    --bam sample_name:sample.bam \
    --vcf variants.vcf \
    --output output.txt \
    --thread 8
```

---

## 六、问题排查

### Q1: CRAM转换时报错 "Failed to open reference"
**解决：** 确保提供了正确的参考基因组文件（-T参数），并且该参考基因组与CRAM文件创建时使用的一致。

### Q2: 转换后的BAM文件很大
**解决：** BAM文件确实比CRAM大。可以考虑：
- 只转换需要分析的区域（使用samtools view -L）
- 分析完成后删除BAM文件
- 考虑方案2，迁移到HTSlib

### Q3: 如何判断CRAM文件需要哪个参考基因组
```bash
# 查看CRAM文件头信息
samtools view -H sample.cram | grep "@SQ"
```

---

**报告生成时间：** 2025-11-05
**分析工具：** Claude Sonnet 4.5

