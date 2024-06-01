//
//  HLBLEManager.m
//  HLBLEManager
//
//  Created by 黄常翁 on 2024/6/1.
//

#import "HLBLEManager.h"
#import <GCDMulticastDelegate/GCDMulticastDelegate.h>

static NSObject *g_lock = nil;
#define channelOnPeropheralView @"peripheralView"
#define kConnectedPeripheraId   @"kConnectedPeripheraId"

@interface HLBLEManager()
/// 所有代理对象
@property (nonatomic, strong) GCDMulticastDelegate<HLBLEManagerDelegate> *delegates;
/// babyBluetooth
@property (nonatomic, strong) BabyBluetooth    *babyBluetooth;
/// 扫描到的外设设备数组
@property (nonatomic, strong) NSMutableArray   *peripheralArray;
/// 写数据特征值
@property (nonatomic, strong) CBCharacteristic *writeCharacteristic;
/// 读数据特征值
@property (nonatomic, strong) CBCharacteristic *readCharacteristic;
@end

@implementation HLBLEManager

#pragma mark - Lifecycle

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initBabyBluetooth];
        
        _delegates = (GCDMulticastDelegate<HLBLEManagerDelegate> *)[[GCDMulticastDelegate alloc] init];
        g_lock = [[NSObject alloc] init];
    }
    return self;
}

#pragma mark - Private Method

- (void)initBabyBluetooth {
    self.babyBluetooth = [BabyBluetooth shareBabyBluetooth];
    [self babyBluetoothDelegate];
}

- (void)babyBluetoothDelegate {
    __weak typeof(self) weakSelf = self;
    
    // 1-系统蓝牙状态
    [self.babyBluetooth setBlockOnCentralManagerDidUpdateState:^(CBCentralManager *central) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.delegates BLEManager:weakSelf didUpdateState:central.state];
        });
    }];
    
    // 2-设置查找设备的过滤器
    [self.babyBluetooth setFilterOnDiscoverPeripherals:^BOOL(NSString *peripheralName, NSDictionary *advertisementData, NSNumber *RSSI) {
        return [weakSelf.delegates BLEManager:weakSelf 
                             filterOnDiscover:peripheralName
                            advertisementData:advertisementData
                                         RSSI:RSSI];
    }];
    
    // 查找的规则
    [self.babyBluetooth setFilterOnDiscoverPeripheralsAtChannel:channelOnPeropheralView
                                                         filter:^BOOL(NSString *peripheralName, NSDictionary *advertisementData, NSNumber *RSSI) {
        return [weakSelf.delegates BLEManager:weakSelf 
                             filterOnDiscover:peripheralName
                            advertisementData:advertisementData
                                         RSSI:RSSI];
    }];
    
    // 3-设置扫描到设备的委托
    [self.babyBluetooth setBlockOnDiscoverToPeripherals:^(CBCentralManager *central, CBPeripheral *peripheral, NSDictionary *advertisementData, NSNumber *RSSI) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (weakSelf.isAutoConnect) {
                NSString *pID = [[NSUserDefaults standardUserDefaults] valueForKey:kConnectedPeripheraId];
                if ([pID isEqualToString:peripheral.identifier.UUIDString]) {
                    [weakSelf connectPeripheral:peripheral];
                }
            }
            [weakSelf scanResultPeripheral:peripheral
                         advertisementData:advertisementData
                                      RSSI:RSSI];
        });
    }];
    
    BabyRhythm *rhythm = [[BabyRhythm alloc] init];
    
    // 4-设置设备连接成功的委托,同一个baby对象，使用不同的channel切换委托回调
    [self.babyBluetooth setBlockOnConnectedAtChannel:channelOnPeropheralView
                                               block:^(CBCentralManager *central, CBPeripheral *peripheral) {
        NSLog(@"【HLBLEManager】->连接成功");
        dispatch_async(dispatch_get_main_queue(), ^{
            if (weakSelf.isAutoConnect) {
                [[NSUserDefaults standardUserDefaults] setValue:peripheral.identifier.UUIDString forKey:kConnectedPeripheraId];
            }
            [weakSelf.delegates BLEManager:weakSelf
                       connectedPeripheral:peripheral];
        });
    }];
    
    // 5-设置设备连接失败的委托
    [self.babyBluetooth setBlockOnFailToConnectAtChannel:channelOnPeropheralView
                                                   block:^(CBCentralManager *central, CBPeripheral *peripheral, NSError *error) {
        NSLog(@"【HLBLEManager】->连接失败");
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.delegates BLEManagerConnectFailed:weakSelf];
        });
    }];
    
    // 6-设置设备断开连接的委托
    [self.babyBluetooth setBlockOnDisconnectAtChannel:channelOnPeropheralView
                                                block:^(CBCentralManager *central, CBPeripheral *peripheral, NSError *error) {
        NSLog(@"【HLBLEManager】->设备：%@断开连接",peripheral.name);
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.delegates BLEManager:weakSelf 
                      disconnectPeripheral:peripheral];
        });
    }];
    
    // 7-设置发现设备的Services的委托
    [self.babyBluetooth setBlockOnDiscoverServicesAtChannel:channelOnPeropheralView
                                                      block:^(CBPeripheral *peripheral, NSError *error) {
        [rhythm beats];
    }];
    
    // 8-设置发现设service的Characteristics的委托
    [self.babyBluetooth setBlockOnDiscoverCharacteristicsAtChannel:channelOnPeropheralView
                                                             block:^(CBPeripheral *peripheral, CBService *service, NSError *error) {
        NSString *serviceUUID = [NSString stringWithFormat:@"%@",service.UUID];
        if ([serviceUUID isEqualToString:weakSelf.serverUUIDString]) {
            for (CBCharacteristic *ch in service.characteristics) {
                // 写数据的特征值
                NSString *chUUID = [NSString stringWithFormat:@"%@",ch.UUID];
                if ([chUUID isEqualToString:weakSelf.writeUUIDString]) {
                    weakSelf.writeCharacteristic = ch;
                }
                // 读数据的特征值
                if ([chUUID isEqualToString:weakSelf.readUUIDString]) {
                    weakSelf.readCharacteristic = ch;
                    [weakSelf.currentPeripheral setNotifyValue:YES
                                             forCharacteristic:weakSelf.readCharacteristic];
                }
            }
        }
        [weakSelf.delegates BLEManagerDiscoverCharacteristics:weakSelf];
    }];
    
    // 9-设置读取characteristics的委托
    [self.babyBluetooth setBlockOnReadValueForCharacteristicAtChannel:channelOnPeropheralView
                                                                block:^(CBPeripheral *peripheral, CBCharacteristic *characteristics, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.delegates BLEManager:weakSelf readData:characteristics.value];
        });
    }];
    
    // 设置发现characteristics的descriptors的委托
    [self.babyBluetooth setBlockOnDiscoverDescriptorsForCharacteristicAtChannel:channelOnPeropheralView
                                                                          block:^(CBPeripheral *peripheral, CBCharacteristic *characteristic, NSError *error) { }];
    
    // 设置读取Descriptor的委托
    [self.babyBluetooth setBlockOnReadValueForDescriptorsAtChannel:channelOnPeropheralView
                                                             block:^(CBPeripheral *peripheral, CBDescriptor *descriptor, NSError *error) { }];
    
    // 读取rssi的委托
    [self.babyBluetooth setBlockOnDidReadRSSI:^(NSNumber *RSSI, NSError *error) { }];
    
    // 设置beats break委托
    [rhythm setBlockOnBeatsBreak:^(BabyRhythm *bry) { }];
    
    // 设置beats over委托
    [rhythm setBlockOnBeatsOver:^(BabyRhythm *bry) { }];
    
    // 扫描选项->CBCentralManagerScanOptionAllowDuplicatesKey:忽略同一个Peripheral端的多个发现事件被聚合成一个发现事件
    NSDictionary *scanForPeripheralsWithOptions = @{CBCentralManagerScanOptionAllowDuplicatesKey:@YES};
    /*连接选项->
     CBConnectPeripheralOptionNotifyOnConnectionKey :当应用挂起时，如果有一个连接成功时，如果我们想要系统为指定的peripheral显示一个提示时，就使用这个key值。
     CBConnectPeripheralOptionNotifyOnDisconnectionKey :当应用挂起时，如果连接断开时，如果我们想要系统为指定的peripheral显示一个断开连接的提示时，就使用这个key值。
     CBConnectPeripheralOptionNotifyOnNotificationKey:
     当应用挂起时，使用该key值表示只要接收到给定peripheral端的通知就显示一个提
     */
    NSDictionary *connectOptions = @{CBConnectPeripheralOptionNotifyOnConnectionKey:@YES,
                                     CBConnectPeripheralOptionNotifyOnDisconnectionKey:@YES,
                                     CBConnectPeripheralOptionNotifyOnNotificationKey:@YES};
    
    [self.babyBluetooth setBabyOptionsAtChannel:channelOnPeropheralView
                  scanForPeripheralsWithOptions:scanForPeripheralsWithOptions
                   connectPeripheralWithOptions:connectOptions
                 scanForPeripheralsWithServices:nil
                           discoverWithServices:nil
                    discoverWithCharacteristics:nil];
    
    // 连接设备
    [self.babyBluetooth setBabyOptionsWithScanForPeripheralsWithOptions:scanForPeripheralsWithOptions
                                           connectPeripheralWithOptions:nil
                                         scanForPeripheralsWithServices:nil
                                                   discoverWithServices:nil
                                            discoverWithCharacteristics:nil];
}

/// 扫描到的设备[由block回主线程]
- (void)scanResultPeripheral:(CBPeripheral *)peripheral 
           advertisementData:(NSDictionary *)advertisementData
                        RSSI:(NSNumber *)RSSI {
    for (HLPeripheralInfo *peripheralInfo in self.peripheralArray) {
        if ([peripheralInfo.peripheral.identifier isEqual:peripheral.identifier]) {
            return;
        }
    }
    
    HLPeripheralInfo *peripheralInfo = [[HLPeripheralInfo alloc] init];
    peripheralInfo.peripheral = peripheral;
    peripheralInfo.advertisementData = advertisementData;
    peripheralInfo.RSSI = RSSI;
    [self.peripheralArray addObject:peripheralInfo];
    
    [self.delegates BLEManager:self scanResultPeripherals:self.peripheralArray];
}

#pragma mark - Public Method

+ (HLBLEManager *)sharedManager {
    static HLBLEManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HLBLEManager alloc] init];
    });
    return instance;
}

/**
 * 添加代理
 * @param queue 默认为dispatch_get_main_queue()
 */
- (void)addDelegate:(id<HLBLEManagerDelegate>)delegate
              queue:(dispatch_queue_t)queue
{
    @synchronized(g_lock) {
        if (!queue) {
            queue = dispatch_get_main_queue();
        }
        [_delegates addDelegate:delegate delegateQueue:queue];
    }
}

/**
 * 删除代理
 */
- (void)removeDelegate:(id<HLBLEManagerDelegate>)delegate
{
    if (!delegate) {
        return;
    }
    @synchronized(g_lock) {
        [_delegates removeDelegate:delegate];
    }
}

/**
 * 开始扫描
 */
- (void)startScanPeripheral {
    self.babyBluetooth.scanForPeripherals().begin();
}

/**
 * 停止扫描
 */
- (void)stopScanPeripheral {
    [self.peripheralArray removeAllObjects];
    [self.babyBluetooth cancelScan];
}

/**
 * 连接设备
 */
-(void)connectPeripheral:(CBPeripheral *)peripheral {
    // 断开之前的所有连接
    [self.babyBluetooth cancelAllPeripheralsConnection];
    self.currentPeripheral = peripheral;
    self.babyBluetooth.having(peripheral).and.channel(channelOnPeropheralView).
    then.connectToPeripherals().discoverServices().
    discoverCharacteristics().readValueForCharacteristic().
    discoverDescriptorsForCharacteristic().
    readValueForDescriptors().begin();
}

/**
 * 获取当前连接所有设备
 */
- (NSArray *)getCurrentPeripherals {
    return [self.babyBluetooth findConnectedPeripherals];
}

/**
 * 获取设备的服务跟特征值[当已连接成功时]
 */
- (void)searchServerAndCharacteristicUUID {
    self.babyBluetooth.having(self.currentPeripheral).and.channel(channelOnPeropheralView).
    then.connectToPeripherals().discoverServices().discoverCharacteristics()
    .readValueForCharacteristic().discoverDescriptorsForCharacteristic().
    readValueForDescriptors().begin();
}

/**
 * 断开所有连接
 */
- (void)disconnectAllPeripherals {
    [self.babyBluetooth cancelAllPeripheralsConnection];
}

/**
 * 断开当前连接
 */
- (void)disconnectLastPeripheral:(CBPeripheral *)peripheral {
    [self.babyBluetooth cancelPeripheralConnection:peripheral];
}

/**
 * 发送数据
 */
- (void)write:(NSData *)msgData {
    if (self.writeCharacteristic == nil) {
        NSLog(@"【HLBLEManager】->数据发送失败");
        return;
    }
    
    //若最后一个参数是CBCharacteristicWriteWithResponse
    //则会进入setBlockOnDidWriteValueForCharacteristic委托
    [self.currentPeripheral writeValue:msgData
                     forCharacteristic:self.writeCharacteristic
                                  type:CBCharacteristicWriteWithResponse];
}

#pragma mark - Getter

- (NSMutableArray *)peripheralArray {
    if (!_peripheralArray) {
        _peripheralArray = [NSMutableArray new];
    }
    return _peripheralArray;
}

@end
