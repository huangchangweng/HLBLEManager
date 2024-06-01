//
//  HLBLEUtils.h
//  HLBLEManager
//
//  Created by 黄常翁 on 2024/6/1.
//

#import <Foundation/Foundation.h>

@interface HLBLEUtils : NSObject

/// 普通字符串转换为十六进制
+ (NSString *)hexStringFromString:(NSString *)string;

/// 十六进制转换为普通字符串
+ (NSString *)stringFromHexString:(NSString *)hexString;

/// 十六进制转NSData
+ (NSData *)convertHexStrToData:(NSString *)str;

/// NSData转十六进制
+ (NSString *)convertDataToHexStr:(NSData *)data;

/// 补0
+ (NSString *)characterStringMainStr:(NSString*)mainStr
                            addDigit:(NSInteger)addDigit
                              addStr:(NSString*)addStr;

@end
