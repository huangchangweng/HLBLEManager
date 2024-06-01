//
//  HLViewController.m
//  HLBLEManager
//
//  Created by huangchangweng on 06/01/2024.
//  Copyright (c) 2024 huangchangweng. All rights reserved.
//

#import "HLViewController.h"
#import <HLBLEManager/HLBLEManager.h>

@interface HLViewController ()<HLBLEManagerDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray *dataArray;
@end

@implementation HLViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    [[HLBLEManager sharedManager] addDelegate:self queue:nil];
    // 写入UUID值【替换成自己的蓝牙设备UUID值】
    [HLBLEManager sharedManager].serverUUIDString = @"1815";
    [HLBLEManager sharedManager].writeUUIDString = @"2A56";
    [HLBLEManager sharedManager].readUUIDString = @"2A5A";
    [HLBLEManager sharedManager].isAutoConnect = YES;
}

- (void)dealloc {
    [[HLBLEManager sharedManager] removeDelegate:self];
}

#pragma mark - HLBLEManagerDelegate

/**
 * 蓝牙状态改变
 * @param state 状态
 */
- (void)BLEManager:(HLBLEManager *)manager
    didUpdateState:(CBManagerState)state
{
    if (state == CBManagerStatePoweredOn) {
        // 开始扫描设备
        [[HLBLEManager sharedManager] startScanPeripheral];
    } else if (state == CBManagerStatePoweredOff) {
        NSLog(@"提醒用户打开蓝牙");
    }
}

/**
 * 查找设备的过滤器
 * @param peripheralName 设备名称
 */
- (BOOL)BLEManager:(HLBLEManager *)manager
  filterOnDiscover:(NSString *)peripheralName
 advertisementData:(NSDictionary *)advertisementData
              RSSI:(NSNumber *)RSSI
{
    // 这里可以根据自己的业务来判断
    
    if (peripheralName.length > 0) {
        return YES;
    }
    return NO;
}

/**
 * 扫描到的设备回调
 * @param peripheralInfos 扫描到的所有蓝牙设备数组
 */
- (void)BLEManager:(HLBLEManager *)manager
scanResultPeripherals:(NSArray<HLPeripheralInfo *> *)peripheralInfos
{
    self.dataArray = peripheralInfos;
    [self.tableView reloadData];
}

/**
 * 连接成功
 * @param peripheral 连接的外设
 */
- (void)BLEManager:(HLBLEManager *)manager
connectedPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"连接成功");
}

/**
 * 连接失败
 */
- (void)BLEManagerConnectFailed:(HLBLEManager *)manager
{
    NSLog(@"连接失败");
}

/**
 * 当前断开的设备
 * @param peripheral 断开的peripheral信息
 */
- (void)BLEManager:(HLBLEManager *)manager
disconnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"设备断开连接");
}

/**
 * 发现读、写特征
 */
- (void)BLEManagerDiscoverCharacteristics:(HLBLEManager *)manager
{
    NSLog(@"发现读、写特征");
}

/**
 * 读取蓝牙数据
 * @param valueData 蓝牙设备发送过来的data数据
 */
- (void)BLEManager:(HLBLEManager *)manager
          readData:(NSData *)valueData
{
    NSLog(@"读取蓝牙数据：%@", [HLBLEUtils convertDataToHexStr:valueData]);
}

#pragma mark -

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellId"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cellId"];
    }
    
    HLPeripheralInfo *info = self.dataArray[indexPath.row];
    cell.textLabel.text = info.peripheral.name;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    HLPeripheralInfo *info = self.dataArray[indexPath.row];
    
    // 去连接当前选择的Peripheral
    [[HLBLEManager sharedManager] connectPeripheral:info.peripheral];
}

@end
