#!/bin/bash
# 简化编译脚本 - 只生成真机静态库
# 适用于只需要真机版本的场景

set -e

echo "======================================"
echo "网络诊断SDK简化编译（仅真机版本）"
echo "======================================"

PROJECT_NAME="NetworkDiagnosisSDK"
OUTPUT_DIR="./output"
LIBRARY_NAME="lib${PROJECT_NAME}.a"

# 清理
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# 编译真机版本（arm64）
echo "📱 编译真机版本..."
xcrun -sdk iphoneos clang -arch arm64 \
    -fembed-bitcode \
    -c NetworkDiagnosisSDK.m \
    -o "$OUTPUT_DIR/NetworkDiagnosisSDK.o" \
    -fobjc-arc \
    -fmodules \
    -Os

# 生成静态库
ar rcs "$OUTPUT_DIR/$LIBRARY_NAME" "$OUTPUT_DIR/NetworkDiagnosisSDK.o"

# 复制头文件
cp NetworkDiagnosisSDK.h "$OUTPUT_DIR/"

# 删除中间文件
rm "$OUTPUT_DIR/NetworkDiagnosisSDK.o"

echo ""
echo "✅ 编译完成！"
echo ""
echo "📦 输出文件："
echo "  - $OUTPUT_DIR/$LIBRARY_NAME"
echo "  - $OUTPUT_DIR/NetworkDiagnosisSDK.h"
echo ""
ls -lh "$OUTPUT_DIR"
echo ""

