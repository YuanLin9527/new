//
//  DiagnosisViewController.m
//  网络诊断结果页面实现
//

#import "DiagnosisViewController.h"
#import "NetworkDiagnosisSDK.h"
#import "DeviceInfo.h"
#import "InAppFloatingView.h"

@interface DiagnosisViewController ()
@property (nonatomic, strong) UITextView *logTextView;
@property (nonatomic, strong) UIButton *startButton;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UIButton *logCopyButton;  // 重命名避免 copy 前缀
@property (nonatomic, assign) BOOL isDiagnosing;
@end

@implementation DiagnosisViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    [self setupUI];
    
    // 如果有URL，自动开始诊断
    if (self.diagnosisUrl && self.diagnosisUrl.length > 0) {
        [self performSelector:@selector(startDiagnosis) withObject:nil afterDelay:0.5];
    }
}

- (void)setupUI {
    // 标题
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 40, self.view.bounds.size.width, 44)];
    titleLabel.text = @"🔧 网络诊断调试面板";
    titleLabel.font = [UIFont boldSystemFontOfSize:18];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:titleLabel];
    
    // 日志显示区域
    CGFloat logTop = 90;
    CGFloat logBottom = self.view.bounds.size.height - 80;
    self.logTextView = [[UITextView alloc] initWithFrame:CGRectMake(16, logTop, 
                                                                     self.view.bounds.size.width - 32, 
                                                                     logBottom - logTop)];
    self.logTextView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
    self.logTextView.font = [UIFont fontWithName:@"Courier" size:12];
    self.logTextView.textColor = [UIColor blackColor];
    self.logTextView.editable = NO;
    self.logTextView.layer.cornerRadius = 8;
    self.logTextView.layer.borderWidth = 1;
    self.logTextView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.logTextView.text = @"等待诊断启动...";
    [self.view addSubview:self.logTextView];
    
    // 按钮区域
    CGFloat buttonTop = self.view.bounds.size.height - 70;
    CGFloat buttonWidth = (self.view.bounds.size.width - 64) / 3;
    
    // 开始诊断按钮
    self.startButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.startButton.frame = CGRectMake(16, buttonTop, buttonWidth, 44);
    [self.startButton setTitle:@"开始诊断" forState:UIControlStateNormal];
    self.startButton.backgroundColor = [UIColor systemBlueColor];
    [self.startButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.startButton.layer.cornerRadius = 8;
    [self.startButton addTarget:self action:@selector(startDiagnosis) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.startButton];
    
    // 关闭按钮
    self.closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.closeButton.frame = CGRectMake(32 + buttonWidth, buttonTop, buttonWidth, 44);
    [self.closeButton setTitle:@"关闭" forState:UIControlStateNormal];
    self.closeButton.backgroundColor = [UIColor systemGrayColor];
    [self.closeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.closeButton.layer.cornerRadius = 8;
    [self.closeButton addTarget:self action:@selector(closeDiagnosis) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.closeButton];
    
    // 复制日志按钮（重命名为 logCopyButton）
    self.logCopyButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.logCopyButton.frame = CGRectMake(48 + buttonWidth * 2, buttonTop, buttonWidth, 44);
    [self.logCopyButton setTitle:@"复制日志" forState:UIControlStateNormal];
    self.logCopyButton.backgroundColor = [UIColor colorWithRed:0.1 green:0.46 blue:0.82 alpha:1];
    [self.logCopyButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.logCopyButton.layer.cornerRadius = 8;
    [self.logCopyButton addTarget:self action:@selector(copyLog) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.logCopyButton];
}

- (void)startDiagnosis {
    if (self.isDiagnosing) return;
    
    self.isDiagnosing = YES;
    self.logTextView.text = @"";
    self.startButton.enabled = NO;
    
    // 显示设备信息
    [self log:@"开始查询设备信息..."];
    [self log:[DeviceInfo getDeviceModel]];
    [self log:[DeviceInfo getSystemVersion]];
    [self log:[DeviceInfo getDeviceId]];
    [self log:[DeviceInfo getNetworkType]];
    [self log:[DeviceInfo getCarrierName]];
    [self log:@""];
    
    [self log:@"开始网络诊断..."];
    [self log:@"=============================="];
    
    if (self.jsonData && self.jsonData.length > 0) {
        [self log:[NSString stringWithFormat:@"收到游戏数据: %@", self.jsonData]];
    }
    
    NSString *url = self.diagnosisUrl ?: @"http://list-new.dhsf.xqhuyu.com/modlist/modlist_143319_ios.txt";
    [self log:[NSString stringWithFormat:@"诊断目标: %@\n", url]];
    
    // 提取主机名
    NSString *host = [self extractHost:url];
    NSInteger port = 80; // 默认端口
    
    if ([url containsString:@"https"]) {
        port = 443;
    }
    
    // 执行完整诊断
    NetworkDiagnosisSDK *sdk = [NetworkDiagnosisSDK sharedInstance];
    
    [sdk fullDiagnosisHost:host
                      port:port
          progressCallback:^(NSString *progress) {
        [self log:progress];
    }
        completionCallback:^(NSString *result) {
        [self log:@"\n✅ 诊断完成！"];
        self.isDiagnosing = NO;
        self.startButton.enabled = YES;
    }];
}

- (void)closeDiagnosis {
    [[NetworkDiagnosisSDK sharedInstance] cancelCurrentTask];
    [self dismissViewControllerAnimated:YES completion:^{
        // 恢复悬浮窗
        [InAppFloatingView restore];
    }];
}

- (void)copyLog {
    NSString *logText = self.logTextView.text;
    if (logText.length == 0) {
        [self showAlert:@"提示" message:@"日志为空，无法复制"];
        return;
    }
    
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = logText;
    
    [self showAlert:@"成功" message:@"日志已复制到粘贴板"];
}

- (void)log:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.logTextView.text = [self.logTextView.text stringByAppendingFormat:@"%@\n", message];
        
        // 自动滚动到底部
        NSRange bottom = NSMakeRange(self.logTextView.text.length - 1, 1);
        [self.logTextView scrollRangeToVisible:bottom];
    });
}

- (NSString *)extractHost:(NSString *)urlString {
    if (!urlString || urlString.length == 0) return nil;
    
    // 移除协议
    NSString *host = urlString;
    if ([host hasPrefix:@"http://"]) {
        host = [host substringFromIndex:7];
    } else if ([host hasPrefix:@"https://"]) {
        host = [host substringFromIndex:8];
    }
    
    // 移除路径
    NSRange slashRange = [host rangeOfString:@"/"];
    if (slashRange.location != NSNotFound) {
        host = [host substringToIndex:slashRange.location];
    }
    
    // 移除端口
    NSRange colonRange = [host rangeOfString:@":"];
    if (colonRange.location != NSNotFound) {
        host = [host substringToIndex:colonRange.location];
    }
    
    return host;
}

- (void)showAlert:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end

