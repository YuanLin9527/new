//
//  InAppFloatingView.h
//  游戏内悬浮窗 - 不需要系统权限
//
//  用于在游戏界面显示诊断按钮
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 游戏内悬浮视图管理类
 * 功能：在游戏界面显示可拖动的诊断按钮
 * 优点：不需要系统悬浮窗权限
 * 缺点：仅在游戏应用内可见
 */
@interface InAppFloatingView : NSObject

/**
 * 在指定窗口显示悬浮按钮
 * @param window 游戏的UIWindow（通常传入 [UIApplication sharedApplication].keyWindow）
 * @param jsonData 游戏数据（JSON字符串，可选）
 * @param defaultUrl 默认诊断URL
 */
+ (void)showInWindow:(UIWindow *)window 
            jsonData:(NSString * _Nullable)jsonData 
          defaultUrl:(NSString * _Nullable)defaultUrl;

/**
 * 隐藏悬浮按钮
 */
+ (void)hide;

/**
 * 恢复显示悬浮按钮（诊断页面关闭后调用）
 */
+ (void)restore;

/**
 * 判断是否正在显示
 */
+ (BOOL)isShowing;

@end

NS_ASSUME_NONNULL_END

