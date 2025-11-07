# iOS网络诊断SDK集成教程

## 📦 第一步：获取SDK文件

从GitHub Actions下载编译好的SDK：

```
https://github.com/YuanLin9527/new/actions
```

解压后得到：
- `libNetworkDiagnosisSDK.a` - 静态库
- `NetworkDiagnosisSDK.h`
- `InAppFloatingView.h`
- `DiagnosisViewController.h`
- `DeviceInfo.h`

---

## 📁 第二步：添加文件到Xcode项目

### 1. 创建SDK文件夹

在你的Xcode项目中：
1. 右键项目根目录
2. 选择 **New Group**
3. 命名为 `NetworkDiagnosisSDK`

### 2. 拖入文件

将以下文件拖入 `NetworkDiagnosisSDK` 文件夹：
- `libNetworkDiagnosisSDK.a`
- 所有 `.h` 头文件

选择：
- ✅ **Copy items if needed**
- ✅ **Add to targets: 你的游戏Target**

---

## ⚙️ 第三步：配置项目设置

### 1. 添加系统框架

在Xcode中：
1. 选择项目 Target
2. **General** → **Frameworks, Libraries, and Embedded Content**
3. 点击 **+** 添加：
   - `Foundation.framework`
   - `UIKit.framework`
   - `CoreTelephony.framework`
   - `SystemConfiguration.framework`

### 2. 配置Header Search Paths（可选）

如果编译报错找不到头文件：
1. **Build Settings** → 搜索 **Header Search Paths**
2. 添加：`$(PROJECT_DIR)/NetworkDiagnosisSDK`

---

## 🚀 第四步：在代码中使用

### 方式1：显示悬浮窗（推荐，跟你图二的代码类似）

```objective-c
#import "InAppFloatingView.h"

- (void)showDiagnosisFloatingButton {
    // 准备游戏数据（可选）
    NSString *jsonData = @"{\"device_id\":\"12345\",\"user\":\"test_user\",\"level\":\"10\"}";
    
    // 默认诊断URL（可选）
    NSString *defaultUrl = @"www.baidu.com";
    
    // 显示悬浮按钮
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    [InAppFloatingView showInWindow:window 
                           jsonData:jsonData 
                         defaultUrl:defaultUrl];
}

// 隐藏悬浮窗
- (void)hideDiagnosisButton {
    [InAppFloatingView hide];
}
```

### 方式2：直接调用诊断API

```objective-c
#import "NetworkDiagnosisSDK.h"

- (void)startNetworkDiagnosis {
    NetworkDiagnosisSDK *sdk = [NetworkDiagnosisSDK sharedInstance];
    
    // 执行完整诊断
    [sdk fullDiagnosisHost:@"www.baidu.com"
                      port:80
          progressCallback:^(NSString *progress) {
        // 实时输出诊断进度
        NSLog(@"诊断进度: %@", progress);
    }
        completionCallback:^(NSString *result) {
        // 诊断完成
        NSLog(@"诊断完成: %@", result);
    }];
}
```

### 方式3：单独调用各功能

```objective-c
#import "NetworkDiagnosisSDK.h"

NetworkDiagnosisSDK *sdk = [NetworkDiagnosisSDK sharedInstance];

// 只Ping
[sdk pingHost:@"8.8.8.8" callback:^(NSString *result) {
    NSLog(@"Ping结果: %@", result);
}];

// 只Telnet
[sdk telnetHost:@"www.baidu.com" port:80 callback:^(NSString *result) {
    NSLog(@"Telnet结果: %@", result);
}];

// 只Traceroute
[sdk tracerouteHost:@"www.baidu.com"
    progressCallback:^(NSString *progress) {
        NSLog(@"路由: %@", progress);
    }
    completionCallback:^(NSString *result) {
        NSLog(@"完成: %@", result);
    }];
```

---

## 💡 完整示例代码

### 在ViewController中集成

```objective-c
// ViewController.h
#import <UIKit/UIKit.h>

@interface ViewController : UIViewController
@end

// ViewController.m
#import "ViewController.h"
#import "InAppFloatingView.h"

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 显示你的游戏界面
    self.view.backgroundColor = [UIColor blackColor];
    
    // 延迟0.5秒显示诊断悬浮按钮
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self showDiagnosisButton];
    });
}

- (void)showDiagnosisButton {
    // 准备游戏数据
    NSDictionary *gameData = @{
        @"device_id": @"12345",
        @"user": @"test_user",
        @"level": @"10"
    };
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:gameData options:0 error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    // 显示悬浮窗
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    [InAppFloatingView showInWindow:window 
                           jsonData:jsonString 
                         defaultUrl:@"www.baidu.com"];
}

- (void)dealloc {
    // 页面销毁时隐藏悬浮窗
    [InAppFloatingView hide];
}

@end
```

---

## 🎮 在AppDelegate中全局使用

```objective-c
// AppDelegate.m
#import "AppDelegate.h"
#import "InAppFloatingView.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // 游戏初始化...
    
    // 延迟显示诊断按钮（可选，用于测试/调试版本）
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self showGlobalDiagnosisButton];
    });
    
    return YES;
}

- (void)showGlobalDiagnosisButton {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    
    NSString *jsonData = @"{\"device_id\":\"12345\"}";
    [InAppFloatingView showInWindow:window 
                           jsonData:jsonData 
                         defaultUrl:@"www.baidu.com"];
}

@end
```

---

## ⚠️ 常见问题

### 1. 编译错误：Undefined symbols

**解决方法：**
- 确保 `libNetworkDiagnosisSDK.a` 已添加到项目
- 检查 **Build Phases** → **Link Binary With Libraries** 中是否包含该库

### 2. 运行时闪退：Unrecognized selector

**解决方法：**
- **Build Settings** → **Other Linker Flags**
- 添加：`-ObjC`

### 3. 找不到头文件

**解决方法：**
- 确保头文件已正确添加到项目
- 检查 **Header Search Paths** 设置

### 4. 悬浮窗不显示

**解决方法：**
```objective-c
// 确保在主线程调用
dispatch_async(dispatch_get_main_queue(), ^{
    [InAppFloatingView showInWindow:window 
                           jsonData:jsonData 
                         defaultUrl:defaultUrl];
});
```

---

## 📝 API说明

### InAppFloatingView

| 方法 | 说明 |
|------|------|
| `+ showInWindow:jsonData:defaultUrl:` | 显示悬浮按钮 |
| `+ hide` | 隐藏悬浮按钮 |
| `+ restore` | 恢复悬浮按钮 |
| `+ isShowing` | 是否正在显示 |

### NetworkDiagnosisSDK

| 方法 | 说明 |
|------|------|
| `+ sharedInstance` | 获取单例 |
| `- pingHost:callback:` | Ping检测 |
| `- tracerouteHost:progressCallback:completionCallback:` | 路由跟踪 |
| `- telnetHost:port:callback:` | Telnet检测 |
| `- fullDiagnosisHost:port:progressCallback:completionCallback:` | 完整诊断 |

---

## 🎯 使用建议

### 开发/测试版本

```objective-c
#ifdef DEBUG
    // 显示诊断按钮
    [InAppFloatingView showInWindow:window jsonData:data defaultUrl:url];
#endif
```

### 正式版本

```objective-c
// 正式版可以关闭，或者通过服务器配置开关
if ([self shouldShowDiagnosisButton]) {
    [InAppFloatingView showInWindow:window jsonData:data defaultUrl:url];
}
```

---

## ✅ 完成！

集成完成后，运行游戏：
1. 会看到紫色的"诊断"悬浮按钮
2. 可以拖动到任意位置
3. 点击后弹出输入框
4. 输入IP和端口，开始诊断
5. 查看Ping、Traceroute、Telnet结果

**完全对标Android版本功能！** 🎉

