#!/bin/bash
# 网络诊断SDK编译脚本
# 用于编译生成 .a 静态库

set -e

echo "======================================"
echo "网络诊断SDK编译脚本"
echo "======================================"
echo ""

# 配置变量
PROJECT_NAME="NetworkDiagnosisSDK"
OUTPUT_DIR="./build"
LIBRARY_NAME="lib${PROJECT_NAME}.a"

# SDK版本
SDK_DEVICE="iphoneos"
SDK_SIMULATOR="iphonesimulator"

# 架构配置
ARCHS_DEVICE="arm64"  # 真机架构
ARCHS_SIMULATOR="x86_64 arm64"  # 模拟器架构（Intel和Apple Silicon）

# 清理之前的构建
echo "🧹 清理之前的构建文件..."
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/device"
mkdir -p "$OUTPUT_DIR/simulator"
mkdir -p "$OUTPUT_DIR/universal"

# 编译真机版本
echo ""
echo "📱 编译真机版本（arm64）..."

# 编译所有.m文件
xcrun -sdk $SDK_DEVICE clang -arch arm64 \
    -fembed-bitcode \
    -c NetworkDiagnosisSDK.m InAppFloatingView.m DiagnosisViewController.m DeviceInfo.m \
    -fobjc-arc \
    -fmodules \
    -Os

# 移动到device目录
mv NetworkDiagnosisSDK.o "$OUTPUT_DIR/device/"
mv InAppFloatingView.o "$OUTPUT_DIR/device/"
mv DiagnosisViewController.o "$OUTPUT_DIR/device/"
mv DeviceInfo.o "$OUTPUT_DIR/device/"

# 生成真机静态库
ar rcs "$OUTPUT_DIR/device/$LIBRARY_NAME" \
    "$OUTPUT_DIR/device/NetworkDiagnosisSDK.o" \
    "$OUTPUT_DIR/device/InAppFloatingView.o" \
    "$OUTPUT_DIR/device/DiagnosisViewController.o" \
    "$OUTPUT_DIR/device/DeviceInfo.o"

echo "✅ 真机版本编译完成: $OUTPUT_DIR/device/$LIBRARY_NAME"

# 编译模拟器版本
echo ""
echo "🖥️  编译模拟器版本（x86_64 + arm64）..."

# x86_64 (Intel Mac 模拟器)
xcrun -sdk $SDK_SIMULATOR clang -arch x86_64 \
    -c NetworkDiagnosisSDK.m InAppFloatingView.m DiagnosisViewController.m DeviceInfo.m \
    -fobjc-arc \
    -fmodules \
    -Os

# 移动x86_64文件
mv NetworkDiagnosisSDK.o "$OUTPUT_DIR/simulator/NetworkDiagnosisSDK_x86_64.o"
mv InAppFloatingView.o "$OUTPUT_DIR/simulator/InAppFloatingView_x86_64.o"
mv DiagnosisViewController.o "$OUTPUT_DIR/simulator/DiagnosisViewController_x86_64.o"
mv DeviceInfo.o "$OUTPUT_DIR/simulator/DeviceInfo_x86_64.o"

# arm64 (Apple Silicon Mac 模拟器)
xcrun -sdk $SDK_SIMULATOR clang -arch arm64 \
    -c NetworkDiagnosisSDK.m InAppFloatingView.m DiagnosisViewController.m DeviceInfo.m \
    -fobjc-arc \
    -fmodules \
    -Os

# 移动arm64文件
mv NetworkDiagnosisSDK.o "$OUTPUT_DIR/simulator/NetworkDiagnosisSDK_arm64.o"
mv InAppFloatingView.o "$OUTPUT_DIR/simulator/InAppFloatingView_arm64.o"
mv DiagnosisViewController.o "$OUTPUT_DIR/simulator/DiagnosisViewController_arm64.o"
mv DeviceInfo.o "$OUTPUT_DIR/simulator/DeviceInfo_arm64.o"

# 合并模拟器架构
lipo -create \
    "$OUTPUT_DIR/simulator/NetworkDiagnosisSDK_x86_64.o" \
    "$OUTPUT_DIR/simulator/NetworkDiagnosisSDK_arm64.o" \
    -output "$OUTPUT_DIR/simulator/NetworkDiagnosisSDK.o"

lipo -create \
    "$OUTPUT_DIR/simulator/InAppFloatingView_x86_64.o" \
    "$OUTPUT_DIR/simulator/InAppFloatingView_arm64.o" \
    -output "$OUTPUT_DIR/simulator/InAppFloatingView.o"

lipo -create \
    "$OUTPUT_DIR/simulator/DiagnosisViewController_x86_64.o" \
    "$OUTPUT_DIR/simulator/DiagnosisViewController_arm64.o" \
    -output "$OUTPUT_DIR/simulator/DiagnosisViewController.o"

lipo -create \
    "$OUTPUT_DIR/simulator/DeviceInfo_x86_64.o" \
    "$OUTPUT_DIR/simulator/DeviceInfo_arm64.o" \
    -output "$OUTPUT_DIR/simulator/DeviceInfo.o"

# 生成模拟器静态库
ar rcs "$OUTPUT_DIR/simulator/$LIBRARY_NAME" \
    "$OUTPUT_DIR/simulator/NetworkDiagnosisSDK.o" \
    "$OUTPUT_DIR/simulator/InAppFloatingView.o" \
    "$OUTPUT_DIR/simulator/DiagnosisViewController.o" \
    "$OUTPUT_DIR/simulator/DeviceInfo.o"

echo "✅ 模拟器版本编译完成: $OUTPUT_DIR/simulator/$LIBRARY_NAME"

# 创建通用库（XCFramework）
echo ""
echo "📦 创建XCFramework通用库..."
xcodebuild -create-xcframework \
    -library "$OUTPUT_DIR/device/$LIBRARY_NAME" \
    -headers . \
    -library "$OUTPUT_DIR/simulator/$LIBRARY_NAME" \
    -headers . \
    -output "$OUTPUT_DIR/${PROJECT_NAME}.xcframework"

echo "✅ XCFramework创建完成: $OUTPUT_DIR/${PROJECT_NAME}.xcframework"

# 复制头文件
echo ""
echo "📄 复制头文件..."
cp NetworkDiagnosisSDK.h "$OUTPUT_DIR/"
cp InAppFloatingView.h "$OUTPUT_DIR/"
cp DiagnosisViewController.h "$OUTPUT_DIR/"
cp DeviceInfo.h "$OUTPUT_DIR/"
echo "✅ 头文件已复制"

# 显示文件信息
echo ""
echo "======================================"
echo "📊 编译结果"
echo "======================================"
echo ""
echo "📁 输出目录: $OUTPUT_DIR"
echo ""
echo "真机静态库:"
ls -lh "$OUTPUT_DIR/device/$LIBRARY_NAME"
lipo -info "$OUTPUT_DIR/device/$LIBRARY_NAME"
echo ""
echo "模拟器静态库:"
ls -lh "$OUTPUT_DIR/simulator/$LIBRARY_NAME"
lipo -info "$OUTPUT_DIR/simulator/$LIBRARY_NAME"
echo ""
echo "XCFramework:"
ls -lh "$OUTPUT_DIR/${PROJECT_NAME}.xcframework"
echo ""
echo "======================================"
echo "✅ 编译完成！"
echo "======================================"
echo ""
echo "📦 产物清单："
echo "  1. $OUTPUT_DIR/device/$LIBRARY_NAME - 真机版本"
echo "  2. $OUTPUT_DIR/simulator/$LIBRARY_NAME - 模拟器版本"
echo "  3. $OUTPUT_DIR/${PROJECT_NAME}.xcframework - 通用库（推荐使用）"
echo "  4. $OUTPUT_DIR/*.h - 所有头文件"
echo ""
echo "📝 使用方法请查看 集成说明.md"
echo ""
echo "✨ 包含完整的游戏内悬浮窗UI功能！"
echo ""

