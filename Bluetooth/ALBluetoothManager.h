//
//  ALBluetoothManager.h
//  Bluetooth
//
//  Created by wzkj on 2018/3/19.
//  Copyright © 2018年 Cloudwave. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ALBluetoothManager : NSObject

@property (nonatomic, strong, readonly) NSArray * _Nonnull scanedDatas;

+ (nonnull instancetype)manager;

-(void)startScan;

/**
 开始扫描

 @param serviceUUIDs 服务id列表
 @param options 筛选选项
 */
-(void)startScan:(nullable NSArray<NSString *> *)serviceUUIDs filterOption:(nullable NSDictionary<NSString *, id> *)options;


/**
 停止扫描
 */
-(void)stopScan;

-(void)connectPeripheralWithName:(nonnull NSString *)name;

/**
 * services 为空则会发现连接的perpheral的所有服务，否则为services中指定的服务
 */
// 连接蓝牙
-(void)connectPeripheralWithName:(nonnull NSString *)name withServices:(nullable NSArray<NSString *>*)services andCharacteristics:(nullable NSArray<NSString *> *)characteristicUUIDs;

-(void)disConnectPeripheral;
@end
