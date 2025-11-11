# GetBaseCountsCram 编译指南 (htslib 1.22.1)

## 版本信息
- **GetBaseCountsCram**: 1.3.0
- **htslib**: 1.22.1
- **编译器要求**: gcc 4.8+ (支持 C++11)

## 快速编译

```bash
cd /dssg/home/wuy/Projects/GetBaseCountsMultiSample

# 方法1: 使用自动化脚本（推荐）
./rebuild_clean.sh

# 方法2: 手动步骤
./fix_htslib.sh    # 修复 htslib 1.22.1 的编译问题
./build.sh         # 编译
```

## 修复说明

### htslib 1.22.1 的已知问题及修复

#### 问题 1: simd.c 编译错误
**错误信息**:
```
simd.c:138:30: error: incompatible types when initializing type '__m128i' using type 'int'
```

**原因**: 缺少 SSSE3 头文件 `<tmmintrin.h>`

**修复**: `fix_htslib.sh` 自动添加必要的头文件

#### 问题 2: htslib.pc.in 缺失
**错误信息**:
```
config.status: error: cannot find input file: 'htslib.pc.in'
```

**原因**: 某些 htslib 版本的源码包中缺少此文件

**修复**: `fix_htslib.sh` 自动创建模板文件

## 代码更新 (vs 原 bamtools 版本)

### API 变更

| 原 bamtools API | 新 htslib 1.22.1 API | 说明 |
|-----------------|---------------------|------|
| `BamReader` | `samFile*` + `sam_hdr_t*` | 文件和头信息 |
| `BamAlignment` | `bam1_t*` | 比对记录 |
| `bam_hdr_t` | `sam_hdr_t` | 头结构（1.15+ 更新）|
| `bam_name2id()` | `sam_hdr_name2tid()` | 染色体名到ID |

### 兼容层实现

重构保留了所有 bamtools API，业务逻辑无需修改：
- `BamAlignment` 类：封装 htslib 的 `bam1_t`
- `BamReader` 类：封装 htslib 的文件操作
- `CigarOp` 结构：封装 CIGAR 操作

## 编译选项

### 最小依赖编译（当前使用）
```bash
./configure --disable-libcurl --disable-s3 --disable-gcs --disable-bz2 --disable-lzma
make lib-static
```

只依赖：
- zlib (必需)
- pthread
- math library

### 完整功能编译
```bash
./configure
make
```

依赖：
- zlib, bzip2, xz (压缩)
- libcurl (网络访问)
- openssl (HTTPS)

## 编译输出

成功编译后应该看到：
```
✓ htslib build complete: 2.1M
✓ GetBaseCountsCram build complete
Executable: ./GetBaseCountsCram
```

## 测试验证

```bash
# 运行测试脚本
./test_demo.sh

# 手动测试
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

## 故障排除

### 问题: 仍然有 simd.c 错误

**解决**:
```bash
cd htslib
# 备份原文件
cp simd.c simd.c.backup
# 在 #include <emmintrin.h> 后添加
# #include <tmmintrin.h>
cd ..
./build.sh
```

### 问题: 找不到 -lz

**解决**:
```bash
# CentOS/RHEL
sudo yum install zlib-devel

# Ubuntu/Debian
sudo apt-get install zlib1g-dev
```

### 问题: sam_hdr_name2tid 未定义

**原因**: htslib版本太旧（<1.15）

**解决**: 
1. 确认 htslib 版本 >= 1.15
2. 或在代码中使用 `bam_name2id()` （旧版兼容）

## 文件清单

### 核心文件
- `GetBaseCountsMultiSample.cpp` - 主程序源码（重构后）
- `Makefile` - 编译配置

### 辅助脚本
- `fix_htslib.sh` - 修复 htslib 1.22.1 编译问题
- `build.sh` - 自动化编译脚本
- `rebuild_clean.sh` - 清理并重新编译
- `test_demo.sh` - 自动化测试脚本

### 文档
- `README_CRAM.md` - CRAM 支持完整文档
- `REFACTORING_SUMMARY.md` - 重构技术总结
- `COMPILE_GUIDE.md` - 本文件
- `QUICK_START.md` - 快速开始指南

## 性能建议

### 编译优化
```bash
# 在 Makefile 中使用
CXXFLAGS = -O3 -march=native -std=c++11 -fopenmp
```

### 运行优化
- 使用多线程: `--thread 8`
- CRAM 需要参考基因组在本地
- 建议 SSD 存储以提高 I/O 性能

## 支持的格式

| 格式 | 扩展名 | 索引 | 说明 |
|------|--------|------|------|
| BAM | .bam | .bai | 原支持格式 |
| CRAM | .cram | .crai | 新增支持 |
| SAM | .sam | - | htslib 支持但未优化 |

## 后续开发

如需添加新功能：
1. 修改 `GetBaseCountsMultiSample.cpp`
2. 保持兼容层不变
3. 使用 htslib 原生 API 添加新功能
4. 运行测试确保兼容性

## 参考资源

- htslib 官方文档: http://www.htslib.org/
- htslib GitHub: https://github.com/samtools/htslib
- CRAM 格式规范: https://samtools.github.io/hts-specs/CRAMv3.pdf

