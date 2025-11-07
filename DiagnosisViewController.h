//
//  DiagnosisViewController.h
//  网络诊断结果页面
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DiagnosisViewController : UIViewController

@property (nonatomic, strong) NSString *diagnosisUrl;
@property (nonatomic, strong) NSString *jsonData;

@end

NS_ASSUME_NONNULL_END

