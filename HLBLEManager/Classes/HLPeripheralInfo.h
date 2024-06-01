//
//  HLPeripheralInfo.h
//  HLBLEManager
//
//  Created by 黄常翁 on 2024/6/1.
//

#import <Foundation/Foundation.h>
#import <BabyBluetooth/BabyBluetooth.h>

@interface HLPeripheralInfo : NSObject
@property (nonatomic, strong) NSNumber     *RSSI;
@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, strong) NSDictionary *advertisementData;
@end
