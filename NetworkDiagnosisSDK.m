//
//  NetworkDiagnosisSDK.m
//  网络诊断SDK - iOS版本
//

#import "NetworkDiagnosisSDK.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <netdb.h>
#import <unistd.h>
#include <sys/time.h>
#include <netinet/ip_icmp.h>

#define SDK_VERSION @"1.0.0"
#define MAX_HOPS 30
#define TIMEOUT_SECONDS 5

@interface NetworkDiagnosisSDK ()
@property (nonatomic, strong) dispatch_queue_t diagnosisQueue;
@property (nonatomic, assign) BOOL shouldCancel;
@end

@implementation NetworkDiagnosisSDK

#pragma mark - Singleton

+ (instancetype)sharedInstance {
    static NetworkDiagnosisSDK *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[NetworkDiagnosisSDK alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // 创建并发队列，而不是串行队列
        dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(
            DISPATCH_QUEUE_CONCURRENT,
            QOS_CLASS_USER_INITIATED,
            0
        );
        _diagnosisQueue = dispatch_queue_create("com.networkdiagnosis.queue", attr);
        
        NSLog(@"[SDK] init - 创建队列成功: %p, label: %s", _diagnosisQueue, dispatch_queue_get_label(_diagnosisQueue));
        
        _shouldCancel = NO;
    }
    return self;
}

#pragma mark - Public Methods

+ (NSString *)sdkVersion {
    return SDK_VERSION;
}

- (void)cancelCurrentTask {
    self.shouldCancel = YES;
}

#pragma mark - Ping

- (void)pingHost:(NSString *)host callback:(NetworkDiagnosisCallback)callback {
    [self pingHost:host count:5 callback:callback];
}

- (void)pingHost:(NSString *)host count:(NSInteger)count callback:(NetworkDiagnosisCallback)callback {
    NSLog(@"[SDK] ========== pingHost 开始 ==========");
    NSLog(@"[SDK] host=%@, count=%ld", host, (long)count);
    NSLog(@"[SDK] 当前线程:%@", [NSThread currentThread]);
    NSLog(@"[SDK] 是否主线程:%@", [NSThread isMainThread] ? @"YES" : @"NO");
    NSLog(@"[SDK] callback=%p", callback);
    NSLog(@"[SDK] diagnosisQueue=%p", self.diagnosisQueue);
    NSLog(@"[SDK] self=%p", self);
    
    if (!host || host.length == 0) {
        NSLog(@"[SDK] pingHost 错误：主机地址为空");
        if (callback) {
            dispatch_async(dispatch_get_main_queue(), ^{
                callback(@"错误: 主机地址不能为空");
            });
        }
        return;
    }
    
    self.shouldCancel = NO;
    
    // 强引用self，避免被释放
    __weak typeof(self) weakSelf = self;
    
    NSLog(@"[SDK] ========== 准备执行 dispatch_async ==========");
    NSLog(@"[SDK] 目标队列: %p", self.diagnosisQueue);
    
    // 尝试使用dispatch_get_global_queue作为备选
    dispatch_queue_t queue = self.diagnosisQueue;
    if (!queue) {
        NSLog(@"[SDK] ⚠️ diagnosisQueue为空！使用全局队列");
        queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    }
    
    NSLog(@"[SDK] 即将调用 dispatch_async...");
    NSLog(@"[SDK] 队列地址: %p, 队列label: %s", queue, dispatch_queue_get_label(queue));
    
    // 测试：先用全局队列试试
    dispatch_queue_t testQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    NSLog(@"[SDK] 测试全局队列地址: %p, label: %s", testQueue, dispatch_queue_get_label(testQueue));
    
    // 尝试1：使用全局队列而不是自定义队列
    dispatch_async(testQueue, ^{
        NSLog(@"[SDK] ========== ✅✅✅ 成功进入全局队列的 dispatch_async 块！ ==========");
        NSLog(@"[SDK] 执行线程:%@", [NSThread currentThread]);
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            NSLog(@"[SDK] ❌ self已被释放！");
            return;
        }
        
        NSLog(@"[SDK] strongSelf=%p", strongSelf);
        
        NSMutableString *result = [NSMutableString string];
        [result appendFormat:@"===== Ping %@ =====\n", host];
        
        NSLog(@"[SDK] 开始DNS解析：%@", host);
        
        // 解析主机地址
        NSString *ipAddress = [strongSelf resolveHost:host];
        if (!ipAddress) {
            NSLog(@"[SDK] DNS解析失败：%@", host);
            [result appendFormat:@"DNS解析失败: %@\n", host];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (callback) callback(result);
            });
            return;
        }
        
        NSLog(@"[SDK] DNS解析成功：%@ -> %@", host, ipAddress);
        [result appendFormat:@"目标IP: %@\n\n", ipAddress];
        
        NSInteger successCount = 0;
        NSInteger failCount = 0;
        double totalTime = 0;
        double minTime = DBL_MAX;
        double maxTime = 0;
        
        for (NSInteger i = 0; i < count; i++) {
            if (strongSelf.shouldCancel) {
                [result appendString:@"\n任务已取消\n"];
                break;
            }
            
            NSLog(@"[SDK] 执行第%ld次ping...", (long)(i + 1));
            double pingTime = [strongSelf executePing:ipAddress];
            NSLog(@"[SDK] 第%ld次ping结果: %.2f", (long)(i + 1), pingTime);
            
            if (pingTime >= 0) {
                [result appendFormat:@"第%ld次: %@, time=%.2f ms\n", 
                    (long)(i + 1), ipAddress, pingTime];
                successCount++;
                totalTime += pingTime;
                if (pingTime < minTime) minTime = pingTime;
                if (pingTime > maxTime) maxTime = pingTime;
            } else if (pingTime == -1) {
                [result appendFormat:@"第%ld次: 请求超时\n", (long)(i + 1)];
                failCount++;
            } else {
                [result appendFormat:@"第%ld次: 连接失败\n", (long)(i + 1)];
                failCount++;
            }
            
            if (i < count - 1) {
                [NSThread sleepForTimeInterval:1.0];
            }
        }
        
        NSLog(@"[SDK] Ping完成，成功:%ld 失败:%ld", (long)successCount, (long)failCount);
        
        [result appendString:@"\n----- 统计信息 -----\n"];
        [result appendFormat:@"发送: %ld, 成功: %ld, 失败: %ld\n", 
            (long)count, (long)successCount, (long)failCount];
        
        if (successCount > 0) {
            double avgTime = totalTime / successCount;
            [result appendFormat:@"最小: %.2f ms, 最大: %.2f ms, 平均: %.2f ms\n", 
                minTime, maxTime, avgTime];
        }
        
        [result appendFormat:@"丢包率: %.1f%%\n", (failCount * 100.0 / count)];
        
        NSLog(@"[SDK] 准备回调Ping结果，长度:%lu", (unsigned long)result.length);
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"[SDK] 执行Ping回调");
            if (callback) {
                callback(result);
                NSLog(@"[SDK] Ping回调完成");
            }
        });
    });
}

- (double)executePing:(NSString *)ipAddress {
    int sock = socket(AF_INET, SOCK_DGRAM, IPPROTO_ICMP);
    if (sock < 0) {
        return -2;
    }
    
    // 设置超时
    struct timeval timeout;
    timeout.tv_sec = TIMEOUT_SECONDS;
    timeout.tv_usec = 0;
    setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, &timeout, sizeof(timeout));
    
    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = inet_addr([ipAddress UTF8String]);
    
    // 构造ICMP包（简化版本，使用UDP socket模拟）
    // 注意：iOS应用在非越狱设备上可能没有权限发送ICMP包
    // 这里使用connect测试来模拟ping
    
    struct timeval start, end;
    gettimeofday(&start, NULL);
    
    // 尝试连接（用于模拟ping）
    int result = connect(sock, (struct sockaddr *)&addr, sizeof(addr));
    
    gettimeofday(&end, NULL);
    close(sock);
    
    if (result == 0 || errno == ECONNREFUSED || errno == ENETUNREACH) {
        // 计算时间差（毫秒）
        double elapsed = (end.tv_sec - start.tv_sec) * 1000.0 + 
                        (end.tv_usec - start.tv_usec) / 1000.0;
        return elapsed;
    }
    
    if (errno == ETIMEDOUT) {
        return -1; // 超时
    }
    
    return -2; // 其他错误
}

#pragma mark - Traceroute

- (void)tracerouteHost:(NSString *)host 
      progressCallback:(NetworkDiagnosisProgressCallback)progressCallback
    completionCallback:(NetworkDiagnosisCallback)completionCallback {
    
    if (!host || host.length == 0) {
        if (completionCallback) {
            completionCallback(@"错误: 主机地址不能为空");
        }
        return;
    }
    
    self.shouldCancel = NO;
    
    dispatch_async(self.diagnosisQueue, ^{
        NSMutableString *result = [NSMutableString string];
        [result appendFormat:@"===== Traceroute %@ =====\n", host];
        
        if (progressCallback) {
            dispatch_async(dispatch_get_main_queue(), ^{
                progressCallback([result copy]);
            });
        }
        
        // 解析主机地址
        NSString *targetIP = [self resolveHost:host];
        if (!targetIP) {
            NSString *error = @"DNS解析失败\n";
            dispatch_async(dispatch_get_main_queue(), ^{
                if (progressCallback) progressCallback(error);
                if (completionCallback) completionCallback(error);
            });
            return;
        }
        
            [result appendFormat:@"目标IP: %@\n", targetIP];
        [result appendString:@"跳数\t\tIP地址\t\t\t延迟\n"];
        [result appendString:@"--------------------------------------------\n"];
        
        BOOL reached = NO;
        
        for (int ttl = 1; ttl <= MAX_HOPS && !reached && !self.shouldCancel; ttl++) {
            NSString *hopResult = [self traceHop:targetIP ttl:ttl reached:&reached];
            [result appendString:hopResult];
            
            if (progressCallback) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    progressCallback(hopResult);
                });
            }
            
            [NSThread sleepForTimeInterval:0.5];
        }
        
        if (self.shouldCancel) {
            [result appendString:@"\n任务已取消\n"];
        } else if (reached) {
            [result appendString:@"\n路由跟踪完成\n"];
        } else {
            [result appendString:@"\n已达到最大跳数限制\n"];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completionCallback) completionCallback(result);
        });
    });
}

- (NSString *)traceHop:(NSString *)targetIP ttl:(int)ttl reached:(BOOL *)reached {
    int sock = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if (sock < 0) {
        return [NSString stringWithFormat:@"%d\t\t错误: 无法创建socket\n", ttl];
    }
    
    // 设置TTL
    setsockopt(sock, IPPROTO_IP, IP_TTL, &ttl, sizeof(ttl));
    
    // 设置超时
    struct timeval timeout;
    timeout.tv_sec = TIMEOUT_SECONDS;
    timeout.tv_usec = 0;
    setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, &timeout, sizeof(timeout));
    
    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons(33434 + ttl); // traceroute常用端口
    addr.sin_addr.s_addr = inet_addr([targetIP UTF8String]);
    
    struct timeval start, end;
    gettimeofday(&start, NULL);
    
    // 发送UDP包
    char buffer[64] = {0};
    sendto(sock, buffer, sizeof(buffer), 0, (struct sockaddr *)&addr, sizeof(addr));
    
    // 尝试接收响应
    struct sockaddr_in from;
    socklen_t fromlen = sizeof(from);
    ssize_t n = recvfrom(sock, buffer, sizeof(buffer), 0, (struct sockaddr *)&from, &fromlen);
    
    gettimeofday(&end, NULL);
    close(sock);
    
    double elapsed = (end.tv_sec - start.tv_sec) * 1000.0 + 
                    (end.tv_usec - start.tv_usec) / 1000.0;
    
    if (n > 0 || errno == ECONNREFUSED) {
        char ipStr[INET_ADDRSTRLEN];
        inet_ntop(AF_INET, &(from.sin_addr), ipStr, INET_ADDRSTRLEN);
        NSString *hopIP = [NSString stringWithUTF8String:ipStr];
        
        // 检查是否到达目标
        if ([hopIP isEqualToString:targetIP] || errno == ECONNREFUSED) {
            *reached = YES;
        }
        
        return [NSString stringWithFormat:@"%d\t\t%@\t\t%.2f ms\n", ttl, hopIP, elapsed];
    } else if (errno == ETIMEDOUT || errno == EAGAIN) {
        return [NSString stringWithFormat:@"%d\t\t* * *\t\t\t超时\n", ttl];
    } else {
        return [NSString stringWithFormat:@"%d\t\t* * *\t\t\t不可达\n", ttl];
    }
}

#pragma mark - Telnet

- (void)telnetHost:(NSString *)host port:(NSInteger)port callback:(NetworkDiagnosisCallback)callback {
    if (!host || host.length == 0) {
        if (callback) {
            callback(@"错误: 主机地址不能为空");
        }
        return;
    }
    
    if (port <= 0 || port > 65535) {
        if (callback) {
            callback(@"错误: 端口号无效（范围: 1-65535）");
        }
        return;
    }
    
    self.shouldCancel = NO;
    
    dispatch_async(self.diagnosisQueue, ^{
        NSMutableString *result = [NSMutableString string];
        [result appendFormat:@"===== Telnet %@:%ld =====\n", host, (long)port];
        
        // 解析主机地址
        NSString *ipAddress = [self resolveHost:host];
        if (!ipAddress) {
            [result appendString:@"DNS解析失败\n"];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (callback) callback(result);
            });
            return;
        }
        
        [result appendFormat:@"目标IP: %@\n", ipAddress];
        [result appendFormat:@"端口: %ld\n\n", (long)port];
        
        // 执行TCP连接测试
        int sock = socket(AF_INET, SOCK_STREAM, 0);
        if (sock < 0) {
            [result appendString:@"错误: 无法创建socket\n"];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (callback) callback(result);
            });
            return;
        }
        
        // 设置超时
        struct timeval timeout;
        timeout.tv_sec = TIMEOUT_SECONDS;
        timeout.tv_usec = 0;
        setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, &timeout, sizeof(timeout));
        setsockopt(sock, SOL_SOCKET, SO_SNDTIMEO, &timeout, sizeof(timeout));
        
        struct sockaddr_in addr;
        memset(&addr, 0, sizeof(addr));
        addr.sin_family = AF_INET;
        addr.sin_port = htons((uint16_t)port);
        addr.sin_addr.s_addr = inet_addr([ipAddress UTF8String]);
        
        [result appendString:@"正在连接...\n"];
        
        struct timeval start, end;
        gettimeofday(&start, NULL);
        
        int connectResult = connect(sock, (struct sockaddr *)&addr, sizeof(addr));
        
        gettimeofday(&end, NULL);
        
        double elapsed = (end.tv_sec - start.tv_sec) * 1000.0 + 
                        (end.tv_usec - start.tv_usec) / 1000.0;
        
        if (connectResult == 0) {
            [result appendFormat:@"✅ 连接成功！\n"];
            [result appendFormat:@"连接耗时: %.2f ms\n", elapsed];
            [result appendString:@"端口状态: OPEN\n"];
        } else {
            if (errno == ETIMEDOUT) {
                [result appendString:@"❌ 连接超时\n"];
                [result appendString:@"端口状态: FILTERED/TIMEOUT\n"];
            } else if (errno == ECONNREFUSED) {
                [result appendString:@"❌ 连接被拒绝\n"];
                [result appendString:@"端口状态: CLOSED\n"];
            } else if (errno == ENETUNREACH) {
                [result appendString:@"❌ 网络不可达\n"];
                [result appendString:@"端口状态: UNREACHABLE\n"];
            } else {
                [result appendFormat:@"❌ 连接失败 (错误码: %d)\n", errno];
                [result appendString:@"端口状态: ERROR\n"];
            }
        }
        
        close(sock);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (callback) callback(result);
        });
    });
}

#pragma mark - Full Diagnosis

- (void)fullDiagnosisHost:(NSString *)host 
                     port:(NSInteger)port 
         progressCallback:(NetworkDiagnosisProgressCallback)progressCallback
       completionCallback:(NetworkDiagnosisCallback)completionCallback {
    
    self.shouldCancel = NO;
    NSMutableString *fullResult = [NSMutableString string];
    
    dispatch_async(self.diagnosisQueue, ^{
        [fullResult appendFormat:@"========== 完整网络诊断 ==========\n"];
        [fullResult appendFormat:@"目标主机: %@\n", host];
        [fullResult appendFormat:@"目标端口: %ld\n", (long)port];
        [fullResult appendFormat:@"开始时间: %@\n\n", [self currentTimeString]];
        
        if (progressCallback) {
            dispatch_async(dispatch_get_main_queue(), ^{
                progressCallback([fullResult copy]);
            });
        }
        
        // 步骤1: Ping测试
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        __block NSString *pingResult = nil;
        
        [self pingHost:host callback:^(NSString *result) {
            pingResult = result;
            dispatch_semaphore_signal(semaphore);
        }];
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        
        if (!self.shouldCancel) {
            [fullResult appendString:pingResult];
            [fullResult appendString:@"\n\n"];
            
            if (progressCallback) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    progressCallback(pingResult);
                });
            }
        }
        
        // 步骤2: Traceroute测试
        if (!self.shouldCancel) {
            __block NSString *traceResult = nil;
            
            [self tracerouteHost:host 
                progressCallback:^(NSString *progress) {
                    if (progressCallback) {
                        progressCallback(progress);
                    }
                }
                completionCallback:^(NSString *result) {
                    traceResult = result;
                    dispatch_semaphore_signal(semaphore);
                }];
            
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            
            if (!self.shouldCancel) {
                [fullResult appendString:traceResult];
                [fullResult appendString:@"\n\n"];
            }
        }
        
        // 步骤3: Telnet测试
        if (!self.shouldCancel) {
            __block NSString *telnetResult = nil;
            
            [self telnetHost:host port:port callback:^(NSString *result) {
                telnetResult = result;
                dispatch_semaphore_signal(semaphore);
            }];
            
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            
            if (!self.shouldCancel) {
                [fullResult appendString:telnetResult];
                [fullResult appendString:@"\n\n"];
                
                if (progressCallback) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        progressCallback(telnetResult);
                    });
                }
            }
        }
        
        // 完成
        [fullResult appendFormat:@"========== 诊断完成 ==========\n"];
        [fullResult appendFormat:@"完成时间: %@\n", [self currentTimeString]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completionCallback) {
                completionCallback(fullResult);
            }
        });
    });
}

#pragma mark - Helper Methods

- (NSString *)resolveHost:(NSString *)host {
    // 先检查是否已经是IP地址
    struct in_addr addr;
    if (inet_pton(AF_INET, [host UTF8String], &addr) == 1) {
        return host;
    }
    
    // 进行DNS解析
    struct hostent *remoteHostEnt = gethostbyname([host UTF8String]);
    if (remoteHostEnt == NULL) {
        return nil;
    }
    
    struct in_addr *remoteInAddr = (struct in_addr *)remoteHostEnt->h_addr_list[0];
    char *ip = inet_ntoa(*remoteInAddr);
    
    return [NSString stringWithUTF8String:ip];
}

- (NSString *)currentTimeString {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    return [formatter stringFromDate:[NSDate date]];
}

@end

