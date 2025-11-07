//
//  DeviceInfo.h
//  设备信息获取工具类
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DeviceInfo : NSObject

/**
 * 获取设备型号（如：iPhone 14 Pro）
 */
+ (NSString *)getDeviceModel;

/**
 * 获取系统版本（如：iOS 16.0）
 */
+ (NSString *)getSystemVersion;

/**
 * 获取设备唯一标识符（IDFV）
 */
+ (NSString *)getDeviceId;

/**
 * 获取网络类型（WiFi/Cellular/Unknown）
 */
+ (NSString *)getNetworkType;

/**
 * 获取运营商名称
 */
+ (NSString *)getCarrierName;

/**
 * 获取设备名称（如：用户的iPhone）
 */
+ (NSString *)getDeviceName;

/**
 * 获取App版本号
 */
+ (NSString *)getAppVersion;

@end

NS_ASSUME_NONNULL_END

