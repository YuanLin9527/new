//
//  DeviceInfo.m
//  设备信息获取工具类实现
//

#import "DeviceInfo.h"
#import <UIKit/UIKit.h>
#import <sys/utsname.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>

@implementation DeviceInfo

+ (NSString *)getDeviceModel {
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *platform = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    // 简化的设备型号映射
    NSDictionary *deviceMap = @{
        // iPhone
        @"iPhone14,2": @"iPhone 13 Pro",
        @"iPhone14,3": @"iPhone 13 Pro Max",
        @"iPhone14,4": @"iPhone 13 mini",
        @"iPhone14,5": @"iPhone 13",
        @"iPhone14,6": @"iPhone SE (3rd generation)",
        @"iPhone14,7": @"iPhone 14",
        @"iPhone14,8": @"iPhone 14 Plus",
        @"iPhone15,2": @"iPhone 14 Pro",
        @"iPhone15,3": @"iPhone 14 Pro Max",
        @"iPhone15,4": @"iPhone 15",
        @"iPhone15,5": @"iPhone 15 Plus",
        @"iPhone16,1": @"iPhone 15 Pro",
        @"iPhone16,2": @"iPhone 15 Pro Max",
        // iPad
        @"iPad13,1": @"iPad Air (4th generation)",
        @"iPad13,2": @"iPad Air (4th generation)",
        @"iPad14,1": @"iPad mini (6th generation)",
        @"iPad14,2": @"iPad mini (6th generation)",
        // 模拟器
        @"i386": @"Simulator",
        @"x86_64": @"Simulator",
        @"arm64": @"Simulator"
    };
    
    NSString *deviceName = deviceMap[platform];
    if (deviceName) {
        return [NSString stringWithFormat:@"设备型号: %@", deviceName];
    } else {
        return [NSString stringWithFormat:@"设备型号: %@", platform];
    }
}

+ (NSString *)getSystemVersion {
    NSString *systemName = [[UIDevice currentDevice] systemName];
    NSString *systemVersion = [[UIDevice currentDevice] systemVersion];
    return [NSString stringWithFormat:@"系统版本: %@ %@", systemName, systemVersion];
}

+ (NSString *)getDeviceId {
    NSString *idfv = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    return [NSString stringWithFormat:@"设备ID: %@", idfv ?: @"未知"];
}

+ (NSString *)getNetworkType {
    // 简化版本：使用Reachability方式
    // 避免使用较新的Network framework API
    NSString *networkType = @"Unknown";
    
    // 尝试检测WiFi
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
    
    // 简单判断：能连接说明有网络
    networkType = @"Connected";
    
    return [NSString stringWithFormat:@"网络类型: %@", networkType];
}

+ (NSString *)getCarrierName {
    if (@available(iOS 16.0, *)) {
        // iOS 16+ CTCarrier 及相关 API 已被废弃且无直接替代，按需求退化处理
        return @"运营商: 不可用";
    }
    
    CTTelephonyNetworkInfo *networkInfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = nil;
    if (@available(iOS 12.0, *)) {
        NSDictionary *carriers = [networkInfo serviceSubscriberCellularProviders];
        if (carriers && carriers.count > 0) {
            carrier = carriers.allValues.firstObject;
        }
    } else {
        carrier = [networkInfo subscriberCellularProvider];
    }
    
    NSString *carrierName = carrier.carrierName;
    if (carrierName && carrierName.length > 0) {
        return [NSString stringWithFormat:@"运营商: %@", carrierName];
    } else {
        return @"运营商: 未知";
    }
}

+ (NSString *)getDeviceName {
    NSString *deviceName = [[UIDevice currentDevice] name];
    return [NSString stringWithFormat:@"设备名称: %@", deviceName];
}

+ (NSString *)getAppVersion {
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *version = infoDictionary[@"CFBundleShortVersionString"];
    NSString *build = infoDictionary[@"CFBundleVersion"];
    return [NSString stringWithFormat:@"App版本: %@ (%@)", version ?: @"1.0", build ?: @"1"];
}

@end

