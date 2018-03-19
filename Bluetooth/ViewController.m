//
//  ViewController.m
//  Bluetooth
//
//  Created by wzkj on 2018/3/19.
//  Copyright © 2018年 Cloudwave. All rights reserved.
//

#import "ViewController.h"
#import "ALBluetoothManager.h"

@interface ViewController ()
@property (nonatomic, strong) NSArray *datas;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[ALBluetoothManager manager] startScan];
    __block typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        weakSelf.datas = [[ALBluetoothManager manager] scanedDatas];
        [[ALBluetoothManager manager] stopScan];
        [weakSelf.tableView reloadData];
    });

}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (!_datas) {
        return 0;
    }
    return _datas.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"bluetoothIdentifier"];
    if (_datas) {
        NSDictionary *dic = [_datas objectAtIndex:indexPath.row];
        UILabel *title = [cell viewWithTag:200];
        title.text = dic[@"name"];
        UILabel *rssi = [cell viewWithTag:201];
        rssi.text = [NSString stringWithFormat:@"%@",dic[@"rssi"]];
        UILabel *identifier = [cell viewWithTag:202];
        identifier.text = dic[@"identifier"];
    }

    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_datas) {
        NSDictionary *dic = [_datas objectAtIndex:indexPath.row];
        NSString *name = dic[@"name"];
        if (name && name.length > 0) {
            [[ALBluetoothManager manager] connectPeripheralWithName:name];
        }
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
