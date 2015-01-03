//
//  ViewController.m
//  CBExperimentsPer
//
//  Created by alex on 12/11/14.
//  Copyright (c) 2014 SDWR. All rights reserved.
//
@import CoreBluetooth;
#import "ViewController.h"

@interface ViewController () < CBPeripheralManagerDelegate>

@property (strong) CBPeripheralManager *manager;
@property (strong, nonatomic) CBMutableCharacteristic *transferCharacteristic;
@property (strong, nonatomic) CBMutableCharacteristic *receiveCharacteristic;
@property BOOL hasSubscribedCentrals;
@property NSTimer *heartBeatTimer;
@property (strong, nonatomic) IBOutlet UILabel *receivedLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.manager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - CBPeripheralManagerDelegate

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {

    if (peripheral.state == CBPeripheralManagerStatePoweredOn) {

        self.transferCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:@"7e55"]
                                                                         properties:CBCharacteristicPropertyNotify
                                                                              value:nil
                                                                        permissions:CBAttributePermissionsReadable];

        self.receiveCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:@"7e54"]
                                                                         properties:CBCharacteristicPropertyWrite
                                                                              value:nil
                                                                        permissions:CBAttributePermissionsWriteable];



        CBMutableService *transferService = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:@"7e57"]
                                                                           primary:YES];

        transferService.characteristics = @[self.transferCharacteristic,self.receiveCharacteristic];

        [self.manager addService:transferService];

    }


}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error {

    if (!error) {

        if (!self.manager.isAdvertising) {
            [self.manager startAdvertising:@{ CBAdvertisementDataServiceUUIDsKey : @[[CBUUID UUIDWithString:@"7e57"]] }];

        }
    }
}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error {

    [self sendValue:@"test"];
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic {

    self.hasSubscribedCentrals = NO;
    [self.heartBeatTimer invalidate];
    self.heartBeatTimer = nil;
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests {

    for (CBATTRequest *req in requests) {

        NSLog(@"req = %@",req);
        NSString *printable = [[NSString alloc] initWithData:req.value encoding:NSUTF8StringEncoding];
        NSLog(@"CBCharacteristic value - %@", printable);

        [self.manager respondToRequest:req withResult:CBATTErrorSuccess];

        if (req.characteristic.UUID == self.receiveCharacteristic.UUID) {

            self.receiveCharacteristic.value = req.value;
            self.receivedLabel.text = [[NSString alloc] initWithData:self.receiveCharacteristic.value encoding:NSUTF8StringEncoding];
            
        }
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic {

    self.hasSubscribedCentrals = YES;

    NSLog(@"didSubscribeToCharacteristic");


}

- (IBAction)launchApp1:(id)sender {

    [self sendValue:@"b1"];
}
- (IBAction)launchApp2:(id)sender {

    [self sendValue:@"b2"];
}
- (IBAction)launchApp3:(id)sender {

    [self sendValue:@"b3"];
}


- (void)sendValue:(NSString *)value {


   // NSString *deviceName = [[UIDevice currentDevice] name];

  //  NSString *fullString = [NSString stringWithFormat:@"%@ says %@",deviceName,value];
    NSData* data = [ value dataUsingEncoding:NSUTF8StringEncoding];
    [self.manager updateValue:data forCharacteristic:self.transferCharacteristic onSubscribedCentrals:nil];
}

@end
