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
#import <Network/Network.h>

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
    NSString *networkType = @"Unknown";
    
    // 检测网络连接状态
    nw_path_monitor_t monitor = nw_path_monitor_create();
    nw_path_t path = nw_path_monitor_copy_current_path(monitor);
    
    if (path) {
        nw_path_status_t status = nw_path_get_status(path);
        if (status == nw_path_status_satisfied) {
            if (nw_path_uses_interface_type(path, nw_interface_type_wifi)) {
                networkType = @"WiFi";
            } else if (nw_path_uses_interface_type(path, nw_interface_type_cellular)) {
                networkType = @"Cellular";
            } else if (nw_path_uses_interface_type(path, nw_interface_type_wired)) {
                networkType = @"Wired";
            } else {
                networkType = @"Other";
            }
        } else {
            networkType = @"No Connection";
        }
    }
    
    return [NSString stringWithFormat:@"网络类型: %@", networkType];
}

+ (NSString *)getCarrierName {
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
    
    NSString *carrierName = [carrier carrierName];
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

