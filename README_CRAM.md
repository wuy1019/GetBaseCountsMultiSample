# GetBaseCountsCram - 支持CRAM格式的基因变异计数工具

## 概述

GetBaseCountsCram 是 GetBaseCountsMultiSample 的重构版本，使用 htslib 替代 bamtools，支持同时处理 BAM 和 CRAM 格式的文件。

## 主要改进

1. **CRAM支持**: 完全支持CRAM格式输入文件
2. **静态编译**: 使用静态链接，无需在目标系统安装依赖库
3. **向后兼容**: 完全兼容原 BAM 格式，结果与原版本一致

## 依赖

- htslib (>=1.9)
- gcc/g++ 支持 C++11
- OpenMP 支持

## 编译

### 1. 安装 htslib 静态库

```bash
# 下载并编译 htslib
wget https://github.com/samtools/htslib/releases/download/1.17/htslib-1.17.tar.bz2
tar -xjf htslib-1.17.tar.bz2
cd htslib-1.17
./configure --disable-libcurl --disable-s3 --disable-gcs
make
sudo make install
```

### 2. 编译 GetBaseCountsCram

```bash
cd /dssg/home/wuy/Projects/GetBaseCountsMultiSample
make clean
make
```

编译完成后会生成静态链接的 `GetBaseCountsCram` 可执行文件。

## 使用方法

### BAM 文件输入 (与原版本相同)

```bash
./GetBaseCountsCram \
  --fasta reference.fa \
  --bam sample1:sample1.bam \
  --vcf variants.vcf \
  --output output.vcf \
  --thread 8
```

### CRAM 文件输入 (新功能)

```bash
./GetBaseCountsCram \
  --fasta reference.fa \
  --bam sample1:sample1.cram \
  --vcf variants.vcf \
  --output output.vcf \
  --thread 8
```

### 混合输入 (BAM + CRAM)

```bash
./GetBaseCountsCram \
  --fasta reference.fa \
  --bam sample1:sample1.bam \
  --bam sample2:sample2.cram \
  --vcf variants.vcf \
  --output output.vcf \
  --thread 8
```

## 参数说明

所有参数与原 GetBaseCountsMultiSample 完全相同：

- `--fasta`: 参考基因组序列文件（必需）
- `--bam`: 输入文件，格式为 SAMPLE_NAME:FILE_PATH（必需，可多次指定）
- `--bam_fof`: 包含样本名和文件路径的列表文件
- `--maf`: MAF格式变异文件（与--vcf互斥）
- `--vcf`: VCF格式变异文件（与--maf互斥）
- `--output`: 输出文件（必需）
- `--thread`: 线程数（默认1）
- `--maq`: 最小mapping quality（默认20）
- `--baq`: 最小base quality（默认0）
- 其他过滤和输出选项请运行 `./GetBaseCountsCram --help` 查看

## CRAM 文件要求

1. CRAM 文件必须有对应的索引文件 (.crai)
2. 参考基因组文件路径必须正确（CRAM依赖参考基因组）
3. 建议使用与生成CRAM相同的参考基因组

## 验证结果

使用 demo 数据验证结果一致性：

```bash
cd demo
../GetBaseCountsCram \
  --fasta hs37d5.fa \
  --bam BC250P0506-Q1APP92KXF1-L000KBP1:BC250P0506-Q1APP92KXF1-L000KBP1.final.bam \
  --vcf tmpin.vcf \
  --output tmpout_new.vcf \
  --thread 8

# 比较结果
diff tmpout.vcf tmpout_new.vcf
```

## 技术细节

### 代码重构说明

1. **htslib集成**: 使用 htslib 的 sam.h, hts.h 和 faidx.h 接口
2. **兼容层**: 实现了 BamAlignment 和 BamReader 类，API与 bamtools 兼容
3. **CIGAR处理**: 使用 htslib 的 CIGAR 解析函数
4. **质量分数**: 自动转换 htslib 的 Phred 质量分数

### 性能优化

- 保持原有的多线程并行处理
- 使用区域索引快速定位
- 静态编译减少运行时开销

## 故障排除

### 编译错误

1. **找不到 htslib 头文件**: 确保 htslib 已正确安装
2. **链接错误**: 检查是否安装了静态库 libhts.a
3. **OpenMP错误**: 确保编译器支持 OpenMP

### 运行错误

1. **无法打开CRAM文件**: 检查文件路径和索引文件
2. **参考基因组错误**: 确保 --fasta 参数指定的文件正确
3. **内存不足**: 减少 --thread 参数或 --max_block_size

## 版本历史

- v1.3.0 (2025-11-11): 重构支持 CRAM 格式，使用 htslib
- v1.2.5: 原 bamtools 版本

## 许可证

继承原 GetBaseCountsMultiSample 的许可证。

