//
//  HLBLEManager.h
//  HLBLEManager
//
//  Created by 黄常翁 on 2024/6/1.
//

#import <Foundation/Foundation.h>
#import <BabyBluetooth/BabyBluetooth.h>
#import "HLPeripheralInfo.h"
#import "HLBLEUtils.h"

@class HLBLEManager;
@protocol HLBLEManagerDelegate <NSObject>
@optional

/**
 * 蓝牙状态改变
 * @param state 状态
 */
- (void)BLEManager:(HLBLEManager *)manager
    didUpdateState:(CBManagerState)state;

/**
 * 查找设备的过滤器
 * @param peripheralName 设备名称
 */
- (BOOL)BLEManager:(HLBLEManager *)manager
  filterOnDiscover:(NSString *)peripheralName
 advertisementData:(NSDictionary *)advertisementData
              RSSI:(NSNumber *)RSSI;

/**
 * 扫描到的设备回调
 * @param peripheralInfos 扫描到的所有蓝牙设备数组
 */
- (void)BLEManager:(HLBLEManager *)manager 
scanResultPeripherals:(NSArray<HLPeripheralInfo *> *)peripheralInfos;

/**
 * 连接成功
 * @param peripheral 连接的外设
 */
- (void)BLEManager:(HLBLEManager *)manager
connectedPeripheral:(CBPeripheral *)peripheral;

/**
 * 连接失败
 */
- (void)BLEManagerConnectFailed:(HLBLEManager *)manager;

/**
 * 当前断开的设备
 * @param peripheral 断开的peripheral信息
 */
- (void)BLEManager:(HLBLEManager *)manager
disconnectPeripheral:(CBPeripheral *)peripheral;

/**
 * 发现读、写特征
 */
- (void)BLEManagerDiscoverCharacteristics:(HLBLEManager *)manager;

/**
 * 读取蓝牙数据
 * @param valueData 蓝牙设备发送过来的data数据
 */
- (void)BLEManager:(HLBLEManager *)manager
          readData:(NSData *)valueData;

@end

@interface HLBLEManager : NSObject
/// 外设的服务UUID值
@property (nonatomic, copy) NSString *serverUUIDString;
/// 外设的写入UUID值
@property (nonatomic, copy) NSString *writeUUIDString;
/// 外设的读取UUID值
@property (nonatomic, copy) NSString *readUUIDString;
/// 当前连接的外设设备
@property (nonatomic, strong) CBPeripheral *currentPeripheral;
/// 是否自动连接，默认为NO（以前连接过的设备会记录id，然后在“startScanPeripheral”扫描后如果发现以前连接过的设备会自动连接）
/// 连接成功会回调“BLEManager:connectedPeripheral:”方法，self.currentPeripheral也有值
@property (nonatomic, assign) BOOL isAutoConnect;

/**
 * 单例
 */
+ (HLBLEManager *)sharedManager;

/**
 * 添加代理
 * @param queue 默认为dispatch_get_main_queue()
 */
- (void)addDelegate:(id<HLBLEManagerDelegate>)delegate 
              queue:(dispatch_queue_t)queue;

/**
 * 删除代理
 */
- (void)removeDelegate:(id<HLBLEManagerDelegate>)delegate;

/**
 * 开始扫描周边蓝牙设备
 */
- (void)startScanPeripheral;

/**
 * 停止扫描
 */
- (void)stopScanPeripheral;

/**
 * 连接所选取的蓝牙外设
 * @param peripheral 所选择蓝牙外设的perioheral
 */
-(void)connectPeripheral:(CBPeripheral *)peripheral;

/**
 * 获取当前连接成功的所有蓝牙设备数组
 * @return 返回当前所连接成功蓝牙设备数组
 */
- (NSArray *)getCurrentPeripherals;

/**
 * 获取设备的服务跟特征值[当已连接成功时调用有效]
 */
- (void)searchServerAndCharacteristicUUID;

/**
 * 断开当前连接的所有蓝牙设备
 */
- (void)disconnectAllPeripherals;

/**
 * 断开所选择的蓝牙设备
 * @param peripheral 所选择蓝牙外设的perioheral
 */
- (void)disconnectLastPeripheral:(CBPeripheral *)peripheral;

/**
 * 向蓝牙设备发送数据
 * @param msgData 数据data值
 */
- (void)write:(NSData *)msgData;

@end
