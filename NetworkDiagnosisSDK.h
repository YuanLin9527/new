//
//  NetworkDiagnosisSDK.h
//  网络诊断SDK - iOS版本
//
//  提供 Ping、Traceroute、Telnet 网络诊断功能
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// 诊断结果回调
typedef void(^NetworkDiagnosisCallback)(NSString *result);
typedef void(^NetworkDiagnosisProgressCallback)(NSString *progress);

/**
 * 网络诊断SDK主类
 * 提供Ping、Traceroute、Telnet三种网络诊断功能
 */
@interface NetworkDiagnosisSDK : NSObject

/**
 * 获取SDK单例
 */
+ (instancetype)sharedInstance;

/**
 * Ping检测 - 连续Ping 5次
 * @param host IP地址或域名
 * @param callback 结果回调，包含所有Ping结果的汇总信息
 */
- (void)pingHost:(NSString *)host 
        callback:(NetworkDiagnosisCallback)callback;

/**
 * Ping检测 - 自定义次数
 * @param host IP地址或域名
 * @param count Ping次数
 * @param callback 结果回调
 */
- (void)pingHost:(NSString *)host 
           count:(NSInteger)count 
        callback:(NetworkDiagnosisCallback)callback;

/**
 * Traceroute路由跟踪
 * @param host IP地址或域名
 * @param progressCallback 进度回调，每一跳的结果
 * @param completionCallback 完成回调
 */
- (void)tracerouteHost:(NSString *)host 
          progressCallback:(NetworkDiagnosisProgressCallback)progressCallback
        completionCallback:(NetworkDiagnosisCallback)completionCallback;

/**
 * Telnet端口检测
 * @param host IP地址或域名
 * @param port 端口号
 * @param callback 结果回调
 */
- (void)telnetHost:(NSString *)host 
              port:(NSInteger)port 
          callback:(NetworkDiagnosisCallback)callback;

/**
 * 执行完整诊断（Ping + Traceroute + Telnet）
 * @param host IP地址或域名
 * @param port 端口号（用于Telnet检测）
 * @param progressCallback 进度回调
 * @param completionCallback 完成回调
 */
- (void)fullDiagnosisHost:(NSString *)host 
                     port:(NSInteger)port 
         progressCallback:(NetworkDiagnosisProgressCallback)progressCallback
       completionCallback:(NetworkDiagnosisCallback)completionCallback;

/**
 * 取消当前正在执行的诊断任务
 */
- (void)cancelCurrentTask;

/**
 * 获取SDK版本号
 */
+ (NSString *)sdkVersion;

@end

NS_ASSUME_NONNULL_END

