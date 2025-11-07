//
//  InAppFloatingView.m
//  游戏内悬浮窗实现
//

#import "InAppFloatingView.h"
#import "DiagnosisViewController.h"

@interface FloatingButton : UIView
@property (nonatomic, strong) UILabel *diagnosisLabel;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, copy) void(^onDiagnosisClick)(void);
@property (nonatomic, copy) void(^onCloseClick)(void);
@end

@implementation FloatingButton {
    CGPoint _initialCenter;
    CGPoint _initialTouchPoint;
    BOOL _isDragging;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    // 主诊断按钮
    self.diagnosisLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 90, 45)];
    self.diagnosisLabel.text = @"诊断";
    self.diagnosisLabel.textColor = [UIColor whiteColor];
    self.diagnosisLabel.font = [UIFont boldSystemFontOfSize:18];
    self.diagnosisLabel.textAlignment = NSTextAlignmentCenter;
    self.diagnosisLabel.backgroundColor = [UIColor colorWithRed:0.5 green:0.2 blue:0.8 alpha:0.9]; // 紫色
    self.diagnosisLabel.layer.cornerRadius = 8;
    self.diagnosisLabel.layer.masksToBounds = YES;
    self.diagnosisLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    self.diagnosisLabel.layer.shadowOffset = CGSizeMake(0, 2);
    self.diagnosisLabel.layer.shadowOpacity = 0.3;
    self.diagnosisLabel.layer.shadowRadius = 4;
    self.diagnosisLabel.userInteractionEnabled = YES;
    [self addSubview:self.diagnosisLabel];
    
    // 关闭按钮（右上角X，增大到40x40，最大化触摸区域）
    self.closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.closeButton.frame = CGRectMake(68, -16, 40, 40);  // 更大的按钮
    [self.closeButton setTitle:@"×" forState:UIControlStateNormal];
    [self.closeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.closeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];  // 高亮时也是白色
    self.closeButton.titleLabel.font = [UIFont boldSystemFontOfSize:24];
    self.closeButton.backgroundColor = [UIColor redColor];
    self.closeButton.layer.cornerRadius = 20;
    self.closeButton.layer.masksToBounds = NO;  // 改为NO，让触摸区域不受裁剪限制
    self.closeButton.clipsToBounds = NO;
    
    // 设置高亮时的背景色（深红色）
    [self.closeButton setBackgroundImage:[self imageWithColor:[UIColor colorWithRed:0.8 green:0 blue:0 alpha:1]] 
                                forState:UIControlStateHighlighted];
    
    // 扩大触摸区域（让点击更容易触发）
    self.closeButton.contentEdgeInsets = UIEdgeInsetsMake(-15, -15, -15, -15);
    
    // 确保按钮在最上层
    self.closeButton.layer.zPosition = 1000;
    
    [self.closeButton addTarget:self action:@selector(closeButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.closeButton];
    
    // 禁用clipsToBounds以允许按钮超出边界
    self.clipsToBounds = NO;
    
    // 添加拖动手势
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [self addGestureRecognizer:pan];
    
    // 添加点击手势
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self.diagnosisLabel addGestureRecognizer:tap];
    
    // 确保悬浮窗初始位置不在屏幕边缘
    [self adjustPositionToSafeArea];
}

// 调整位置到安全区域
- (void)adjustPositionToSafeArea {
    UIView *superview = self.superview;
    if (!superview) return;
    
    // 获取安全区域边距
    UIEdgeInsets safeInsets = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) {
        safeInsets = superview.safeAreaInsets;
    }
    
    CGFloat safeMargin = 10;
    CGFloat minY = MAX(self.bounds.size.height / 2 + 44, self.bounds.size.height / 2 + safeInsets.top + safeMargin);
    CGFloat bottomSafeArea = MAX(80, safeInsets.bottom + 50);
    CGFloat maxY = superview.bounds.size.height - self.bounds.size.height / 2 - bottomSafeArea;
    
    // 如果当前位置在不安全区域，调整到安全区域
    CGPoint currentCenter = self.center;
    if (currentCenter.y < minY) {
        currentCenter.y = minY + 20;  // 再往下一点
        self.center = currentCenter;
    } else if (currentCenter.y > maxY) {
        currentCenter.y = maxY - 20;  // 往上移一点
        self.center = currentCenter;
    }
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    UIView *superview = self.superview;
    if (!superview) return;
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
        _initialCenter = self.center;
        _isDragging = NO;
    }
    else if (gesture.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [gesture translationInView:superview];
        
        // 如果移动距离超过阈值，标记为拖动
        if (fabs(translation.x) > 10 || fabs(translation.y) > 10) {
            _isDragging = YES;
        }
        
        CGPoint newCenter = CGPointMake(_initialCenter.x + translation.x,
                                       _initialCenter.y + translation.y);
        
        // 获取安全区域边距（支持刘海屏和Home Indicator）
        UIEdgeInsets safeInsets = UIEdgeInsetsZero;
        if (@available(iOS 11.0, *)) {
            safeInsets = superview.safeAreaInsets;
        }
        
        // 限制在父视图范围内，留出更大的安全边距
        CGFloat safeMargin = 10;  // 额外安全边距
        CGFloat minX = self.bounds.size.width / 2 + safeMargin;
        CGFloat maxX = superview.bounds.size.width - self.bounds.size.width / 2 - safeMargin;
        
        // 顶部：避开状态栏和刘海（44pt起始）
        CGFloat minY = MAX(self.bounds.size.height / 2 + 44, self.bounds.size.height / 2 + safeInsets.top + safeMargin);
        
        // 底部：避开Home Indicator（至少留出80pt，足够覆盖34pt的Home Indicator区域）
        CGFloat bottomSafeArea = MAX(80, safeInsets.bottom + 50);
        CGFloat maxY = superview.bounds.size.height - self.bounds.size.height / 2 - bottomSafeArea;
        
        newCenter.x = MAX(minX, MIN(newCenter.x, maxX));
        newCenter.y = MAX(minY, MIN(newCenter.y, maxY));
        
        self.center = newCenter;
    }
    else if (gesture.state == UIGestureRecognizerStateEnded || 
             gesture.state == UIGestureRecognizerStateCancelled) {
        // 手势结束时重置拖动标记
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self->_isDragging = NO;
        });
    }
}

- (void)handleTap:(UITapGestureRecognizer *)gesture {
    if (!_isDragging && self.onDiagnosisClick) {
        self.onDiagnosisClick();
    }
    _isDragging = NO;
}

- (void)closeButtonTapped {
    // 移除高亮效果
    self.closeButton.highlighted = NO;
    
    if (self.onCloseClick) {
        self.onCloseClick();
    }
}

// 辅助方法：创建纯色图片（用于按钮背景）
- (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end

// ========================================

@implementation InAppFloatingView

static FloatingButton *_floatingButton = nil;
static UIWindow *_currentWindow = nil;
static NSString *_savedJsonData = nil;
static NSString *_savedDefaultUrl = nil;

+ (void)showInWindow:(UIWindow *)window 
            jsonData:(NSString *)jsonData 
          defaultUrl:(NSString *)defaultUrl {
    
    if (_floatingButton) {
        [self hide];
    }
    
    _currentWindow = window;
    _savedJsonData = jsonData;
    _savedDefaultUrl = defaultUrl;
    
    // 获取安全区域边距（支持刘海屏和Home Indicator）
    UIEdgeInsets safeInsets = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) {
        safeInsets = window.safeAreaInsets;
    }
    
    // 计算安全的初始位置
    // 初始Y：屏幕高度的30%位置（更靠上，避开底部Home Indicator）
    CGFloat initialY = window.bounds.size.height * 0.3;
    // 确保不在底部危险区域（至少距离底部100pt）
    CGFloat minSafeY = 60;  // 距离顶部最小距离
    CGFloat maxSafeY = window.bounds.size.height - 120;  // 距离底部至少120pt
    initialY = MAX(minSafeY, MIN(initialY, maxSafeY));
    
    // 创建悬浮按钮（右侧，安全位置）
    _floatingButton = [[FloatingButton alloc] initWithFrame:CGRectMake(window.bounds.size.width - 110, initialY, 90, 45)];
    
    // 点击诊断按钮
    __weak typeof(self) weakSelf = self;
    _floatingButton.onDiagnosisClick = ^{
        [weakSelf showDiagnosisDialog];
    };
    
    // 点击关闭按钮
    _floatingButton.onCloseClick = ^{
        [weakSelf hide];
    };
    
    [window addSubview:_floatingButton];
}

+ (void)hide {
    if (_floatingButton) {
        [_floatingButton removeFromSuperview];
        _floatingButton = nil;
    }
}

+ (void)restore {
    if (_currentWindow && _savedJsonData && _savedDefaultUrl) {
        [self showInWindow:_currentWindow jsonData:_savedJsonData defaultUrl:_savedDefaultUrl];
    }
}

+ (BOOL)isShowing {
    return _floatingButton != nil;
}

// 显示输入对话框（改为IP+端口两个输入框）
+ (void)showDiagnosisDialog {
    [self hide]; // 先隐藏悬浮窗
    
    UIViewController *rootVC = [self topViewController];
    if (!rootVC) return;
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"网络诊断"
                                                                   message:@"请输入IP地址和端口号:"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    // 第一个输入框：IP地址
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"IP地址或域名";
        textField.text = _savedDefaultUrl ?: @"www.baidu.com";
        textField.keyboardType = UIKeyboardTypeURL;
        textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        textField.autocorrectionType = UITextAutocorrectionTypeNo;
    }];
    
    // 第二个输入框：端口号
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"端口号 (默认80)";
        textField.text = @"80";
        textField.keyboardType = UIKeyboardTypeNumberPad;
    }];
    
    // 开始诊断
    UIAlertAction *startAction = [UIAlertAction actionWithTitle:@"开始诊断"
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction *action) {
        UITextField *ipField = alert.textFields[0];
        UITextField *portField = alert.textFields[1];
        
        NSString *host = [ipField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSString *portStr = [portField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        if (host.length == 0) {
            [self showAlert:@"提示" message:@"请输入有效的IP地址或域名"];
            [self restore];
            return;
        }
        
        // 端口号默认80
        NSInteger port = 80;
        if (portStr.length > 0) {
            port = [portStr integerValue];
            if (port <= 0 || port > 65535) {
                [self showAlert:@"提示" message:@"端口号范围: 1-65535"];
                [self restore];
                return;
            }
        }
        
        // 打开诊断页面
        DiagnosisViewController *diagnosisVC = [[DiagnosisViewController alloc] init];
        diagnosisVC.diagnosisUrl = [NSString stringWithFormat:@"%@:%ld", host, (long)port];
        diagnosisVC.jsonData = _savedJsonData;
        diagnosisVC.modalPresentationStyle = UIModalPresentationFullScreen;
        
        [rootVC presentViewController:diagnosisVC animated:YES completion:nil];
    }];
    
    // 取消
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction *action) {
        [self restore]; // 恢复悬浮窗
    }];
    
    [alert addAction:startAction];
    [alert addAction:cancelAction];
    
    // 显示对话框
    [rootVC presentViewController:alert animated:YES completion:^{
        // 调整对话框高度，确保两个输入框都能完整显示
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (alert.view.constraints.count > 0) {
                for (NSLayoutConstraint *constraint in alert.view.constraints) {
                    if (constraint.firstAttribute == NSLayoutAttributeHeight) {
                        constraint.constant = MAX(constraint.constant, 180);  // 最小高度180
                    }
                }
            }
        });
    }];
}

// 获取最顶层的ViewController
+ (UIViewController *)topViewController {
    UIWindow *window = _currentWindow;
    if (!window) {
        if (@available(iOS 13.0, *)) {
            for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:[UIWindowScene class]]) {
                    UIWindowScene *ws = (UIWindowScene *)scene;
                    window = ws.windows.firstObject;
                    if (window) break;
                }
            }
        } else {
            window = [UIApplication sharedApplication].keyWindow;
        }
    }
    UIViewController *rootVC = window.rootViewController;
    
    while (rootVC.presentedViewController) {
        rootVC = rootVC.presentedViewController;
    }
    
    if ([rootVC isKindOfClass:[UINavigationController class]]) {
        return [(UINavigationController *)rootVC visibleViewController];
    }
    if ([rootVC isKindOfClass:[UITabBarController class]]) {
        return [(UITabBarController *)rootVC selectedViewController];
    }
    
    return rootVC;
}

// 显示简单提示
+ (void)showAlert:(NSString *)title message:(NSString *)message {
    UIViewController *topVC = [self topViewController];
    if (!topVC) return;
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [topVC presentViewController:alert animated:YES completion:nil];
}

@end

