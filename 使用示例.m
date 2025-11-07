//
//  使用示例.m
//  演示如何在游戏中集成网络诊断SDK
//
//  这个示例展示了跟Android版本完全一样的使用方式
//

#import <UIKit/UIKit.h>
#import "InAppFloatingView.h"
#import "NetworkDiagnosisSDK.h"

/*
 ====================================
 集成步骤说明
 ====================================
 
 1. 导入SDK
 将编译后的.a文件和头文件添加到项目中
 
 2. 在AppDelegate中初始化（可选）
 可以在应用启动时进行一些初始化配置
 
 3. 在游戏主界面显示悬浮窗
 调用 [InAppFloatingView showInWindow:...] 显示诊断按钮
 
 4. 在游戏退出时隐藏
 调用 [InAppFloatingView hide]
 */

// ====================================
// 示例1：在ViewController中使用
// ====================================

@interface GameViewController : UIViewController
@end

@implementation GameViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    // 显示游戏内容
    UILabel *label = [[UILabel alloc] initWithFrame:self.view.bounds];
    label.text = @"这是你的游戏界面";
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont systemFontOfSize:24];
    [self.view addSubview:label];
    
    // ✅ 关键代码：显示诊断悬浮按钮
    [self showDiagnosisFloatingButton];
}

- (void)showDiagnosisFloatingButton {
    // 准备游戏数据（可选）
    NSString *jsonData = @"{\"device_id\":\"12345\",\"user\":\"test_user\",\"level\":\"10\"}";
    
    // 默认诊断URL（可选）
    NSString *defaultUrl = @"http://your-game-server.com/api";
    
    // 显示悬浮按钮
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    [InAppFloatingView showInWindow:window 
                           jsonData:jsonData 
                         defaultUrl:defaultUrl];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // 当页面退出时，隐藏悬浮按钮
    [InAppFloatingView hide];
}

- (void)dealloc {
    // 确保清理
    [InAppFloatingView hide];
}

@end

// ====================================
// 示例2：在AppDelegate中全局使用
// ====================================

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // 创建窗口
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor whiteColor];
    
    // 设置根视图控制器
    GameViewController *gameVC = [[GameViewController alloc] init];
    self.window.rootViewController = gameVC;
    [self.window makeKeyAndVisible];
    
    // ✅ 在应用启动后显示诊断按钮
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self showGlobalDiagnosisButton];
    });
    
    return YES;
}

- (void)showGlobalDiagnosisButton {
    // 游戏数据（JSON格式）
    NSDictionary *gameData = @{
        @"player_id": @"123456",
        @"server_id": @"server_01",
        @"game_version": @"1.0.0",
        @"platform": @"iOS"
    };
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:gameData options:0 error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    // 显示悬浮按钮
    [InAppFloatingView showInWindow:self.window 
                           jsonData:jsonString 
                         defaultUrl:@"http://your-game-server.com"];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // 应用退出时清理
    [InAppFloatingView hide];
}

@end

// ====================================
// 示例3：手动调用诊断功能（不使用悬浮窗）
// ====================================

@interface ManualDiagnosisViewController : UIViewController
@end

@implementation ManualDiagnosisViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 添加一个按钮来触发诊断
    UIButton *diagnosisButton = [UIButton buttonWithType:UIButtonTypeSystem];
    diagnosisButton.frame = CGRectMake(100, 200, 200, 50);
    [diagnosisButton setTitle:@"开始网络诊断" forState:UIControlStateNormal];
    [diagnosisButton addTarget:self action:@selector(startManualDiagnosis) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:diagnosisButton];
}

- (void)startManualDiagnosis {
    NetworkDiagnosisSDK *sdk = [NetworkDiagnosisSDK sharedInstance];
    
    // 方式1：只执行Ping
    [sdk pingHost:@"8.8.8.8" callback:^(NSString *result) {
        NSLog(@"Ping结果:\n%@", result);
    }];
    
    // 方式2：只执行Telnet
    [sdk telnetHost:@"www.baidu.com" port:80 callback:^(NSString *result) {
        NSLog(@"Telnet结果:\n%@", result);
    }];
    
    // 方式3：执行完整诊断
    [sdk fullDiagnosisHost:@"www.google.com"
                      port:80
          progressCallback:^(NSString *progress) {
        NSLog(@"诊断进度: %@", progress);
    }
        completionCallback:^(NSString *result) {
        NSLog(@"诊断完成:\n%@", result);
    }];
}

@end

// ====================================
// 示例4：在Unity游戏中使用（桥接代码）
// ====================================

/*
 如果你的游戏使用Unity开发，需要创建一个桥接文件：
 
 // UnityNetworkDiagnosisBridge.h
 #import <Foundation/Foundation.h>
 
 extern "C" {
     void ShowDiagnosisButton(const char* jsonData, const char* defaultUrl);
     void HideDiagnosisButton();
 }
 
 // UnityNetworkDiagnosisBridge.m
 #import "UnityNetworkDiagnosisBridge.h"
 #import "InAppFloatingView.h"
 #import <UIKit/UIKit.h>
 
 void ShowDiagnosisButton(const char* jsonData, const char* defaultUrl) {
     NSString *json = jsonData ? [NSString stringWithUTF8String:jsonData] : nil;
     NSString *url = defaultUrl ? [NSString stringWithUTF8String:defaultUrl] : nil;
     
     dispatch_async(dispatch_get_main_queue(), ^{
         UIWindow *window = [UIApplication sharedApplication].keyWindow;
         [InAppFloatingView showInWindow:window jsonData:json defaultUrl:url];
     });
 }
 
 void HideDiagnosisButton() {
     dispatch_async(dispatch_get_main_queue(), ^{
         [InAppFloatingView hide];
     });
 }
 
 然后在Unity C#中调用：
 
 using System.Runtime.InteropServices;
 
 public class NetworkDiagnosis {
     [DllImport("__Internal")]
     private static extern void ShowDiagnosisButton(string jsonData, string defaultUrl);
     
     [DllImport("__Internal")]
     private static extern void HideDiagnosisButton();
     
     public static void Show(string jsonData, string url) {
         #if UNITY_IOS && !UNITY_EDITOR
         ShowDiagnosisButton(jsonData, url);
         #endif
     }
     
     public static void Hide() {
         #if UNITY_IOS && !UNITY_EDITOR
         HideDiagnosisButton();
         #endif
     }
 }
 
 // 在Unity中使用
 void Start() {
     string gameData = "{\"player_id\":\"123\",\"level\":\"5\"}";
     NetworkDiagnosis.Show(gameData, "http://your-server.com");
 }
 
 void OnDestroy() {
     NetworkDiagnosis.Hide();
 }
 */

// ====================================
// 核心功能说明
// ====================================

/*
 ✅ 游戏内悬浮窗功能：
 - 紫色"诊断"按钮，可拖动
 - 右上角有关闭按钮（小X）
 - 点击"诊断"按钮弹出输入框
 - 可输入或修改诊断URL
 - 自动执行网络诊断
 
 ✅ 诊断功能包括：
 1. Ping检测 - 连续5次
 2. Traceroute路由跟踪 - 最多30跳
 3. Telnet端口检测 - 检测端口连通性
 
 ✅ 诊断结果页面：
 - 显示设备信息
 - 实时显示诊断日志
 - 支持复制日志到剪贴板
 - 可以重新开始诊断
 - 关闭后自动恢复悬浮窗
 
 ⚠️ 注意事项：
 - 悬浮窗只在游戏应用内可见（不是系统级悬浮窗）
 - 不需要任何系统权限
 - 切换应用后悬浮窗会消失
 - 建议在开发/测试版本中使用，正式版可关闭
 */

