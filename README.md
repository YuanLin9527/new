# iOS网络诊断SDK

## 简介

这是一个**完全对标Android版本**的iOS网络诊断SDK，提供游戏内悬浮窗、Ping、Traceroute和Telnet等完整诊断功能。编译后生成.a静态库，可直接集成到iOS游戏应用中。

## 🎯 主要功能

### UI功能（跟Android版本一致）
✅ **游戏内悬浮窗** - 紫色诊断按钮，可拖动，不需要系统权限  
✅ **输入对话框** - 可自定义诊断URL  
✅ **诊断结果页面** - 实时显示日志，支持复制  
✅ **设备信息收集** - 自动显示设备型号、系统版本、网络类型等  

### 诊断功能
✅ **Ping检测** - 连续Ping 5次，输出延迟和丢包率  
✅ **Traceroute路由跟踪** - 跟踪数据包到达目标主机的路径  
✅ **Telnet端口检测** - 检测指定IP和端口是否可连接  
✅ **完整诊断** - 一键执行所有诊断功能

## 快速开始

### 编译SDK

在Mac电脑上执行：

```bash
cd iOS_NetworkDiagnosisSDK
chmod +x build.sh
./build.sh
```

编译完成后，在 `build/` 目录下会生成：
- `libNetworkDiagnosisSDK.a` - 静态库
- `NetworkDiagnosisSDK.xcframework` - 通用框架
- `NetworkDiagnosisSDK.h` - 头文件

### 使用示例（跟Android版本一样）

```objective-c
#import "InAppFloatingView.h"

@implementation GameViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 准备数据
    NSString *jsonData = @"{\"device_id\":\"12345\",\"user\":\"test\"}";
    NSString *defaultUrl = @"http://your-server.com";
    
    // 显示悬浮诊断按钮（跟Android的 InAppFloatingView.show() 一样）
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    [InAppFloatingView showInWindow:window 
                           jsonData:jsonData 
                         defaultUrl:defaultUrl];
}

- (void)dealloc {
    // 隐藏悬浮窗
    [InAppFloatingView hide];
}

@end
```

**就这么简单！用户点击悬浮按钮后会自动弹出输入框，确认后执行诊断。**

### 高级用法（直接调用API）

```objective-c
#import "NetworkDiagnosisSDK.h"

NetworkDiagnosisSDK *sdk = [NetworkDiagnosisSDK sharedInstance];

// 执行Ping检测
[sdk pingHost:@"8.8.8.8" callback:^(NSString *result) {
    NSLog(@"%@", result);
}];

// 执行完整诊断
[sdk fullDiagnosisHost:@"www.baidu.com"
                  port:80
      progressCallback:^(NSString *progress) {
          NSLog(@"进度: %@", progress);
      }
    completionCallback:^(NSString *result) {
        NSLog(@"完成: %@", result);
    }];
```

## 文件说明

| 文件 | 说明 |
|------|------|
| `InAppFloatingView.h/m` | **游戏内悬浮窗（主要使用）** |
| `DiagnosisViewController.h/m` | 诊断结果显示页面 |
| `DeviceInfo.h/m` | 设备信息获取工具 |
| `NetworkDiagnosisSDK.h/m` | 底层诊断API |
| `build.sh` | 完整编译脚本（生成真机+模拟器+XCFramework） |
| `使用示例.m` | **完整UI使用示例（推荐查看）** |
| `TestDemo.m` | 底层API测试示例 |
| `集成说明.md` | 详细的集成和使用文档 |

## 文档

详细的集成说明和API文档请查看：[集成说明.md](./集成说明.md)

## 系统要求

- **编译环境：** macOS + Xcode命令行工具
- **运行环境：** iOS 9.0+
- **开发语言：** Objective-C
- **编译产物：** .a静态库 / XCFramework

## 技术特点

- 🎯 100%对标Android版本功能
- 🎨 完整的UI组件（悬浮窗、输入框、结果页面）
- 📦 编译为静态库，体积小巧
- 🚫 无需系统权限（游戏内悬浮窗）
- 🔒 线程安全，回调在主线程
- ⚡ 异步执行，不阻塞UI
- 🛠️ 支持取消正在执行的任务
- 📱 支持真机和模拟器
- 🎮 适用于Unity、Cocos2d等游戏引擎

## 🔄 与Android版本对比

| 功能 | Android | iOS | 状态 |
|------|---------|-----|------|
| 游戏内悬浮窗 | ✅ | ✅ | 100%对应 |
| 输入对话框 | ✅ | ✅ | 100%对应 |
| Ping检测 | ✅ | ✅ | 100%对应 |
| Traceroute | ✅ | ✅ | 100%对应 |
| Telnet检测 | ✅ | ✅ | 100%对应 |
| 设备信息 | ✅ | ✅ | 100%对应 |
| 日志复制 | ✅ | ✅ | 100%对应 |
| 调用方式 | `show(activity, ...)` | `showInWindow:...` | API对应 |

## 版本历史

- **v1.0.0** (2025-11-07)
  - 初始版本发布
  - ✅ 完整对标Android版本功能
  - ✅ 游戏内悬浮窗UI
  - ✅ 诊断结果页面
  - ✅ 设备信息收集
  - ✅ 支持Ping、Traceroute、Telnet
  - ✅ 生成XCFramework通用库

## 许可证

本SDK供学习和集成使用。

---

**更新时间：** 2025-11-07

