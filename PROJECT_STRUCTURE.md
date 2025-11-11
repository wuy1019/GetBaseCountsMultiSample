# GetBaseCountsCram 项目结构

## 目录树

```
GetBaseCountsMultiSample/
├── GetBaseCountsCram              # 可执行文件（支持 BAM + CRAM）
├── GetBaseCountsMultiSample.cpp   # 主程序源代码
├── Makefile                       # 编译配置
├── build.sh                       # 自动化编译脚本
├── fix_htslib.sh                  # htslib 1.22.1 修复脚本
├── test_demo.sh                   # 测试脚本
├── cleanup.sh                     # 清理脚本（已执行）
│
├── README.md                      # 原始项目 README
├── README_CRAM.md                 # CRAM 支持详细文档
├── COMPILE_GUIDE.md               # 编译指南
│
├── docs/                          # 历史文档
│   └── CRAM_support_analysis.md   # 原始需求分析
│
├── htslib/                        # htslib 1.22.1 源码和库
│   └── libhts.a                   # 静态库
│
├── demo/                          # 测试数据
│   ├── cmd.sh
│   ├── hs37d5.fa
│   ├── hs37d5.fa.fai
│   ├── BC250P0506-Q1APP92KXF1-L000KBP1.final.bam
│   ├── BC250P0506-Q1APP92KXF1-L000KBP1.final.bam.bai
│   └── tmpin.vcf
│
└── bamtools-master/               # 旧的 bamtools（保留作参考）
```

## 核心文件说明

### 可执行文件
- **GetBaseCountsCram** (4.1M)
  - 编译好的可执行程序
  - 支持 BAM 和 CRAM 格式
  - 静态链接 htslib

### 源代码
- **GetBaseCountsMultiSample.cpp** (2384行)
  - 主程序源码
  - 使用 htslib 1.22.1 API
  - 兼容层保持原业务逻辑不变

### 编译相关
- **Makefile**
  - 使用本地 `./htslib` 目录
  - 支持动态链接（默认）
  - OpenMP 并行支持

- **build.sh**
  - 自动应用 htslib 修复
  - 检查依赖
  - 编译 htslib 和主程序
  - 显示详细状态

- **fix_htslib.sh**
  - 修复 htslib 1.22.1 的 SIMD 编译问题
  - 创建缺失的 htslib.pc.in
  - 添加必要的头文件

### 测试
- **test_demo.sh**
  - 使用 demo 数据运行测试
  - 与原版本结果比对
  - 自动生成测试报告

### 文档
- **README.md** - 原始项目说明
- **README_CRAM.md** - CRAM 支持完整文档（使用方法、参数等）
- **COMPILE_GUIDE.md** - 编译指南（依赖、故障排除等）
- **docs/CRAM_support_analysis.md** - 历史需求分析文档

## 使用流程

### 1. 编译
```bash
./build.sh
```

### 2. 测试
```bash
./test_demo.sh
```

### 3. 使用
```bash
# BAM 文件
./GetBaseCountsCram --fasta ref.fa --bam sample:sample.bam --vcf in.vcf --output out.vcf

# CRAM 文件
./GetBaseCountsCram --fasta ref.fa --bam sample:sample.cram --vcf in.vcf --output out.vcf

# 混合使用
./GetBaseCountsCram --fasta ref.fa \
  --bam sample1:s1.bam \
  --bam sample2:s2.cram \
  --vcf in.vcf --output out.vcf
```

## 版本信息

- **GetBaseCountsCram**: 1.3.0
- **htslib**: 1.22.1
- **原 GetBaseCountsMultiSample**: 1.2.5 (bamtools)

## 依赖

### 编译时
- gcc/g++ (C++11)
- make
- zlib-devel
- OpenMP

### 运行时
- 无（静态链接）

## 重要改进

1. ✅ 支持 CRAM 格式
2. ✅ 使用现代 htslib 替代 bamtools
3. ✅ 向后兼容（API 层）
4. ✅ 业务逻辑零修改
5. ✅ 静态编译选项
6. ✅ 完整的测试和文档

## 维护说明

### 如需重新编译
```bash
make -f Makefile clean
./build.sh
```

### 如需更新 htslib
1. 替换 `htslib/` 目录
2. 运行 `./fix_htslib.sh`
3. 运行 `./build.sh`

### 如需修改代码
1. 编辑 `GetBaseCountsMultiSample.cpp`
2. 保持兼容层不变（BamAlignment, BamReader 类）
3. 运行 `make -f Makefile` 重新编译
4. 运行 `./test_demo.sh` 验证

## 技术债务清理

已删除的中间文件：
- ❌ rebuild_clean.sh (功能整合到 build.sh)
- ❌ QUICK_START.md (整合到 COMPILE_GUIDE.md)
- ❌ REFACTORING_SUMMARY.md (整合到 COMPILE_GUIDE.md)
- ❌ makefile (旧的 bamtools 配置)
- ❌ *.o 目标文件

## 参考

- htslib 官网: http://www.htslib.org/
- CRAM 规范: https://samtools.github.io/hts-specs/CRAMv3.pdf

