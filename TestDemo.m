//
//  TestDemo.m
//  网络诊断SDK测试示例
//
//  演示如何使用SDK的各项功能
//

#import <Foundation/Foundation.h>
#import "NetworkDiagnosisSDK.h"

// 测试主函数
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSLog(@"========== 网络诊断SDK测试 ==========\n");
        NSLog(@"SDK版本: %@\n", [NetworkDiagnosisSDK sdkVersion]);
        
        NetworkDiagnosisSDK *sdk = [NetworkDiagnosisSDK sharedInstance];
        
        // 设置信号量等待异步任务完成
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        
        // 测试用的IP和端口
        NSString *testHost = @"8.8.8.8";  // Google DNS
        NSInteger testPort = 53;          // DNS端口
        
        // ====================================
        // 测试1: Ping测试（连续5次）
        // ====================================
        NSLog(@"\n【测试1】执行Ping测试...\n");
        
        [sdk pingHost:testHost callback:^(NSString *result) {
            NSLog(@"%@", result);
            NSLog(@"\n");
            
            // 发送信号，继续下一个测试
            dispatch_semaphore_signal(semaphore);
        }];
        
        // 等待Ping完成
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        
        // 等待2秒再执行下一个测试
        [NSThread sleepForTimeInterval:2.0];
        
        // ====================================
        // 测试2: Traceroute测试
        // ====================================
        NSLog(@"\n【测试2】执行Traceroute测试...\n");
        
        [sdk tracerouteHost:testHost 
            progressCallback:^(NSString *progress) {
                NSLog(@"%@", progress);
            }
            completionCallback:^(NSString *result) {
                NSLog(@"\n路由跟踪完成\n");
                
                // 发送信号，继续下一个测试
                dispatch_semaphore_signal(semaphore);
            }];
        
        // 等待Traceroute完成
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        
        // 等待2秒再执行下一个测试
        [NSThread sleepForTimeInterval:2.0];
        
        // ====================================
        // 测试3: Telnet端口检测
        // ====================================
        NSLog(@"\n【测试3】执行Telnet端口检测...\n");
        
        [sdk telnetHost:testHost port:testPort callback:^(NSString *result) {
            NSLog(@"%@", result);
            NSLog(@"\n");
            
            // 发送信号，继续下一个测试
            dispatch_semaphore_signal(semaphore);
        }];
        
        // 等待Telnet完成
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        
        // 等待2秒再执行下一个测试
        [NSThread sleepForTimeInterval:2.0];
        
        // ====================================
        // 测试4: 完整诊断（Ping + Traceroute + Telnet）
        // ====================================
        NSLog(@"\n【测试4】执行完整诊断...\n");
        
        [sdk fullDiagnosisHost:testHost 
                          port:testPort
              progressCallback:^(NSString *progress) {
                  // 实时输出进度
                  // NSLog(@"%@", progress);
              }
            completionCallback:^(NSString *result) {
                NSLog(@"%@", result);
                
                // 发送信号，测试完成
                dispatch_semaphore_signal(semaphore);
            }];
        
        // 等待完整诊断完成
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        
        NSLog(@"\n========== 所有测试完成 ==========\n");
        
        // 保持程序运行一小段时间，确保所有日志输出
        [NSThread sleepForTimeInterval:1.0];
    }
    return 0;
}

/*
 ====================================
 使用示例说明
 ====================================
 
 在实际iOS应用中使用时：
 
 // 1. 导入头文件
 #import "NetworkDiagnosisSDK.h"
 
 // 2. 获取SDK实例
 NetworkDiagnosisSDK *sdk = [NetworkDiagnosisSDK sharedInstance];
 
 // 3. 调用诊断功能
 
 // 方式1: 单独调用Ping
 [sdk pingHost:@"www.baidu.com" callback:^(NSString *result) {
     NSLog(@"Ping结果: %@", result);
     // 更新UI显示结果
 }];
 
 // 方式2: 单独调用Traceroute
 [sdk tracerouteHost:@"www.baidu.com"
     progressCallback:^(NSString *progress) {
         // 实时更新每一跳的结果
         NSLog(@"路由: %@", progress);
     }
     completionCallback:^(NSString *result) {
         // 显示完整结果
         NSLog(@"完成: %@", result);
     }];
 
 // 方式3: 单独调用Telnet
 [sdk telnetHost:@"www.baidu.com" port:80 callback:^(NSString *result) {
     NSLog(@"Telnet结果: %@", result);
 }];
 
 // 方式4: 执行完整诊断
 [sdk fullDiagnosisHost:@"www.baidu.com"
                   port:80
       progressCallback:^(NSString *progress) {
           // 实时显示诊断进度
       }
     completionCallback:^(NSString *result) {
         // 显示完整诊断报告
         NSLog(@"诊断报告: %@", result);
     }];
 
 // 5. 如需取消正在执行的任务
 [sdk cancelCurrentTask];
 
 ====================================
 */

