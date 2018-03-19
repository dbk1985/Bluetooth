//
//  ALBluetoothManager.m
//  Bluetooth
//
//  Created by wzkj on 2018/3/19.
//  Copyright © 2018年 Cloudwave. All rights reserved.
//

#import "ALBluetoothManager.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>  // iOS被遗忘的近距离通讯利器-MultipeerConnectivity https://www.jianshu.com/p/662dd49d82b6  https://www.jianshu.com/p/d1401793eeea

@interface ALPeripheralInfo : NSObject
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, strong) NSDictionary *advertisementData;
@property (nonatomic, strong) NSNumber *rssi;

@end

@implementation ALPeripheralInfo
@end


@interface ALBluetoothManager ()<CBCentralManagerDelegate,CBPeripheralDelegate>
{
    NSArray *serviceUUIDs;
    NSArray *characteristicUUIDs;
}
@property (nonatomic, strong) CBCentralManager *cbManager;
/** 设备标识为键的设备信息 */
@property (nonatomic, strong) NSMutableDictionary *scanedPeripherals;
/* 连接到的外设 */
@property (nonatomic, strong) CBPeripheral *connectedPeripheral;

@end

@implementation ALBluetoothManager
+ (instancetype)manager
{
    static ALBluetoothManager *g_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_instance = [[ALBluetoothManager alloc] init];

    });
    return g_instance;
}

-(instancetype)init
{
    self = [super init];
    if (self) {
        self.scanedPeripherals = [NSMutableDictionary dictionary];
        self.cbManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:nil];
    }
    return self;
}

#pragma mark --------------------------- 扫描蓝牙
-(void)startScan
{
    [self startScan:nil filterOption:nil];
}

-(void)startScan:(nullable NSArray<NSString *> *)serviceUUIDs filterOption:(nullable NSDictionary<NSString *, id> *)options
{
    if (self.cbManager.isScanning) return;
    if (self.cbManager.state == 5) {
        __block NSMutableArray <CBUUID *> *servicesIds;
        if (serviceUUIDs && serviceUUIDs.count > 0) {
            [serviceUUIDs enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (!servicesIds) {
                    servicesIds = [NSMutableArray array];
                }
                [servicesIds addObject:[CBUUID UUIDWithString:obj]];
            }];
        }
        [self.cbManager scanForPeripheralsWithServices:servicesIds // 通过某些服务筛选外设
                                               options:options]; // dict,条件
    }
}

-(void)stopScan
{
    [self.cbManager stopScan];
}

-(void)connectPeripheralWithName:(nonnull NSString *)name
{
    [self connectPeripheralWithName:name withServices:nil andCharacteristics:nil];
}

/**
 * services 为空则会发现连接的perpheral的所有服务，否则为services中指定的服务
 */
// 连接蓝牙
-(void)connectPeripheralWithName:(nonnull NSString *)name withServices:(nullable NSArray<NSString *>*)services andCharacteristics:(nullable NSArray<NSString *> *)characteristicUUIDs
{
    // 取消之前的连接
    if (self.connectedPeripheral) {
        [self.cbManager cancelPeripheralConnection:self.connectedPeripheral];
    }
    // 根据名称建立新的连接
    __block typeof(self) weakSelf = self;
    [[self.scanedPeripherals allValues] enumerateObjectsUsingBlock:^(ALPeripheralInfo *peripheralInfo, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([peripheralInfo.peripheral.name /*hasPrefix*/isEqualToString:name]) {
            serviceUUIDs = services;
            // 标记我们的外设,让他的生命周期 = vc
            weakSelf.connectedPeripheral = peripheralInfo.peripheral;
            //  设置外设的代理
            weakSelf.connectedPeripheral.delegate = weakSelf;
            // 发现完之后就是进行连接
            [weakSelf.cbManager connectPeripheral:peripheralInfo.peripheral options:nil];
            *stop = YES;
        }
    }];
}

-(void)disConnectPeripheral
{
    if (self.connectedPeripheral) {
        [self.cbManager cancelPeripheralConnection:self.connectedPeripheral];
    }
}

-(NSArray *)scanedDatas
{
    NSMutableArray *datas = [NSMutableArray array];
    [self.scanedPeripherals.allValues enumerateObjectsUsingBlock:^(ALPeripheralInfo *peripheralInfo, NSUInteger idx, BOOL * _Nonnull stop) {
        NSDictionary *dic = @{@"name":[peripheralInfo name] == nil ? @"" : [peripheralInfo name],@"identifier":[[[peripheralInfo peripheral] identifier] UUIDString],@"rssi":peripheralInfo.rssi};
        [datas addObject:dic];
    }];
    return datas;
}

#pragma mark --------------------------- CBCentralManager scan delegate
//只要中心管理者初始化 就会触发此代理方法 判断手机蓝牙状态
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch (central.state) {
        case 0:
            NSLog(@"未知 ");
            break;
        case 1:
            NSLog(@"CBCentralManagerStateResetting");
            break;
        case 2:
            NSLog(@"设备不支持蓝牙");
            break;
        case 3:
            NSLog(@"蓝牙未授权");
            break;
        case 4:
            NSLog(@"蓝牙未开启");
            break;
        case 5:{
            NSLog(@"蓝牙已开启");
            // 在中心管理者成功开启后再搜索外设
            [self startScan];
            break;
        }
        default:
            break;
    }
}

//- (void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary<NSString *, id> *)dict
//{
//
//}

// 搜索成功之后,会调用我们找到外设的代理方法
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{ //找到外设
    NSLog(@"%s, line = %d, cetral = %@,peripheral = %@, advertisementData = %@, RSSI = %@", __FUNCTION__, __LINE__, central, peripheral, advertisementData, RSSI);
    /*
     peripheral = ,
     advertisementData = {
         kCBAdvDataChannel = 38;
         kCBAdvDataIsConnectable = 1;
         kCBAdvDataLocalName = OBand;       //设备名称
         kCBAdvDataManufacturerData = <4c69616e 0e060678 a5043853 75>;
         kCBAdvDataServiceUUIDs =     (
            FEE7
         );
         kCBAdvDataTxPowerLevel = 0;
     },
     RSSI = -55  // 信号强度
     根据打印结果,我们可以得到运动手环它的名字叫 OBand-75
     */
    // 在此处对 advertisementData(外设携带的广播数据) 进行一些处理,通常通过过滤,得到一些外设,然后将外设储存到我们的可变数组中,
    // 这里由于附近只有1个运动手环, 所以我们先按1个外设进行处理

    ALPeripheralInfo *peripheralInfo = [[ALPeripheralInfo alloc] init];
    peripheralInfo.name = [peripheral name];
    peripheralInfo.peripheral = peripheral;
    peripheralInfo.advertisementData = advertisementData;
    peripheralInfo.rssi = RSSI;

    [self.scanedPeripherals setObject:peripheralInfo forKey:[peripheral identifier]];
}

#pragma mark --------------------------- CBCentralManager connecte delegate
// 中心管理者连接外设成功
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral // 外设
{
    NSLog(@"%s, line = %d, %@=连接成功", __FUNCTION__, __LINE__, peripheral.name);
    __block NSMutableArray <CBUUID *> *services;
    if (serviceUUIDs) {
        [serviceUUIDs enumerateObjectsUsingBlock:^(NSString * _Nonnull serviceUUIDString, NSUInteger idx, BOOL * _Nonnull stop) {
            if (!services) {
                services = [NSMutableArray array];
            }
            CBUUID *cbuuid = [CBUUID UUIDWithString:serviceUUIDString];
            [services addObject:cbuuid];
        }];
    }
    // 连接成功之后,可以进行服务和特征的发现
    // 外设发现服务,传nil代表不过滤
    // 这里会触发外设的代理方法 - (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
    [self.connectedPeripheral discoverServices:services];
}
// 外设连接失败
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"%s, line = %d, %@=连接失败", __FUNCTION__, __LINE__, peripheral.name);
    self.connectedPeripheral = nil;
}

// 丢失连接
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"%s, line = %d, %@=断开连接", __FUNCTION__, __LINE__, peripheral.name);
    self.connectedPeripheral = nil;
}


#pragma mark --------------------------- CBPeripheral receive data delegate
// 发现服务
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error
{
    if (error) {
        NSLog(@"发现服务失败：%@",error);
        return;
    }

    __block NSMutableArray *characteristics;
    if (characteristicUUIDs) {
        [characteristicUUIDs enumerateObjectsUsingBlock:^(NSString *  _Nonnull characteristicUUIDString, NSUInteger idx, BOOL * _Nonnull stop) {
            if (!characteristics) {
                characteristics = [NSMutableArray array];
            }
            CBUUID *cbuuid = [CBUUID UUIDWithString:characteristicUUIDString];
            [characteristics addObject:cbuuid];
        }];
    }
    [peripheral.services enumerateObjectsUsingBlock:^(CBService * _Nonnull service, NSUInteger idx, BOOL * _Nonnull stop) {
        // 根据UUID寻找服务中的特征
        [peripheral discoverCharacteristics:characteristics forService:service];
    }];
}

/** 发现特征回调 发现外设服务里的特征的时候调用的代理方法(这个是比较重要的方法，在这里可以通过事先知道UUID找到你需要的特征，订阅特征，或者这里写入数据给特征也可以) */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {

    // 遍历出所需要的特征
    for (CBCharacteristic *characteristic in service.characteristics) {
        NSLog(@"所有特征：%@", characteristic);
        // 从外设开发人员那里拿到不同特征的UUID，不同特征做不同事情，比如有读取数据的特征，也有写入数据的特征
    }

    CBCharacteristic *characteristic = service.characteristics.lastObject;

    // 直接读取这个特征数据，会调用didUpdateValueForCharacteristic
    [peripheral readValueForCharacteristic:characteristic];         // 回调代理方法 - (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error

    // 订阅通知
    [peripheral setNotifyValue:YES forCharacteristic:characteristic];   //回调代理方法 -(void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
}

// 更新特征的value的时候会调用 （凡是从蓝牙传过来的数据都要经过这个回调，简单的说这个方法就是你拿数据的唯一方法） 你可以判断是否
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"%s, line = %d", __FUNCTION__, __LINE__);
//    if (characteristic == @"你要的特征的UUID或者是你已经找到的特征") {
//        //characteristic.value就是你要的数据
//    }
}

/** 订阅状态的改变 */
-(void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        NSLog(@"订阅失败");
        NSLog(@"%@",error);
    }
    if (characteristic.isNotifying) {
        NSLog(@"订阅成功");
    } else {
        NSLog(@"取消订阅");
    }
}



@end
