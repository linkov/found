//
//  ViewController.m
//  CBExperiments
//
//  Created by alex on 12/10/14.
//  Copyright (c) 2014 SDWR. All rights reserved.
//
#import "ViewController.h"

#include <stdlib.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/sysctl.h>

typedef enum {
    CBRangeUnknown = 0,
    CBRangeFar,
    CBRangeNear,
    CBRangeImmediate,
} CBRange;

@import CoreBluetooth;
//@import CoreLocation;



@interface ViewController () <CBCentralManagerDelegate, CBPeripheralDelegate>

@property(nonatomic, strong) CBCentralManager *manager;
@property (strong) CBPeripheral *btDevice;
@property (strong) CBCharacteristic *btWatchedCr;
@property (strong) CBCharacteristic *btWriteCr;
@property (strong) IBOutlet NSTextField *mainLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.manager = [[CBCentralManager alloc] initWithDelegate:self
                                                        queue:nil];


}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

NSString *runCommand(NSString *commandToRun) {
    NSTask *task;
    task = [[NSTask alloc] init];
    [task setLaunchPath: @"/bin/sh"];

    NSURL* url = [[NSBundle mainBundle] URLForResource:@"awkward" withExtension:nil];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *filePath = [documentsPath stringByAppendingPathComponent:@"awkward"];
    BOOL fileExists = [fileManager fileExistsAtPath:filePath];

    if (fileExists) {
        NSLog(@"found");
    } else {
        NSLog(@"no file");
    }

    NSString *fString = [url.absoluteString stringByReplacingOccurrencesOfString:@"file:///" withString:@""];

    NSArray *arguments = [NSArray arrayWithObjects:
                          @"-c" ,
                          [NSString stringWithFormat:@"%@ |awk -f /%@", commandToRun,fString],
                          nil];
    NSLog(@"run command: %@",commandToRun);
    [task setArguments: arguments];

    NSPipe *pipe;
    pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];

    NSFileHandle *file;
    file = [pipe fileHandleForReading];

    [task launch];

    NSData *data;
    data = [file readDataToEndOfFile];

    NSString *output;
    output = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    return output;
}

- (NSString *)machineModel {

    size_t len = 0;
    sysctlbyname("hw.model", NULL, &len, NULL, 0);

    if (len)
    {
        char *model = malloc(len*sizeof(char));
        sysctlbyname("hw.model", model, &len, NULL, 0);
        NSString *model_ns = [NSString stringWithUTF8String:model];
        free(model);
        return model_ns;
    }

    return @"Just an Apple Computer"; //incase model name can't be read
}


#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {

    switch (central.state) {
        case CBCentralManagerStatePoweredOn:
            [self.manager scanForPeripheralsWithServices:nil options: @{ CBCentralManagerScanOptionAllowDuplicatesKey : @NO}];
            break;
        default:
            break;
    }


}

- (void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary *)dict {

}

- (void)centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals {

    for (CBPeripheral *per in peripherals) {

        NSLog(@"ID - %@",[per.identifier UUIDString]);
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {


//    NSLog(@"did discover peripheral: %@, data: %@, %1.2f", [peripheral.identifier UUIDString], advertisementData, [RSSI floatValue]);
//    CBUUID *uuid = [advertisementData[CBAdvertisementDataServiceUUIDsKey] firstObject];
//    NSLog(@"service uuid: %@", [uuid UUIDString]);

  //  CBRange range =  [self rangeFromRSSI:[RSSI integerValue]];

 //   if (range == CBRangeNear && !self.btDevice) {
        self.btDevice = peripheral;
        [self.manager connectPeripheral:self.btDevice options:nil];
       // [self.manager stopScan];
 //   }
//
//    if (range == CBRangeFar && self.btDevice) {
//
//        self.btDevice = nil;
//    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {

   // self.btDevice = peripheral;
    self.btDevice.delegate = self;
    [self.btDevice discoverServices:@[[CBUUID UUIDWithString:@"7e57"]]];
    [self.manager stopScan];


}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {

}


#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {

    for (CBService *service in peripheral.services) {

        NSLog(@"Service UUID - %@",service.UUID);

        [self.btDevice discoverCharacteristics:@[[CBUUID UUIDWithString:@"7e55"],[CBUUID UUIDWithString:@"7e54"]] forService:service];


    }
    
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverIncludedServicesForService:(CBService *)service error:(NSError *)error {

}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {

   // self.btWatchedCr = service.characteristics.firstObject;
   // [self.btDevice readValueForCharacteristic:self.btWatchedCr];
//
//    [self.btDevice setNotifyValue:YES
//                                  forCharacteristic:self.btWatchedCr];

    for (CBCharacteristic *cr in service.characteristics) {

        NSLog(@"CBCharacteristic UUID - %@",cr.UUID);
        NSString *printable = [[NSString alloc] initWithData:cr.value encoding:NSUTF8StringEncoding];
        NSLog(@"CBCharacteristic value - %@", printable);

        if (cr.properties & CBCharacteristicPropertyNotify) {

            
            [self.btDevice setNotifyValue:YES
                                   forCharacteristic:cr];

            self.btWatchedCr = cr;
        }

        if (cr.properties & CBCharacteristicPropertyWrite) {

            self.btWriteCr = cr;
            [self.btDevice writeValue:[ [self machineModel] dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.btWriteCr type:CBCharacteristicWriteWithResponse];

            NSString *comm = runCommand(@"ps -arcwwwxo 'command %cpu %mem' | grep -v grep | head -13");

            NSMutableArray *arr = [NSMutableArray array];

            for (NSString *jsonString in [comm componentsSeparatedByString:@"\n"]) {


                NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
                id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];

                if (json) {

                    [arr addObject:json];
                }
            }

            //pgrep VLC to get PID
            // kill -9 PID
         //   NSLog(@"%@",comm);
        }


    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {

    if (error) {


    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {


    //[peripheral readRSSI];
    NSString *printable = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    NSLog(@"CBCharacteristic value - %@", printable);
    self.mainLabel.stringValue = printable;

    [self performActionForButton:printable];
}

//- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error {
//
//     NSLog(@"RSSI - %@",peripheral.RSSI);
//}

/* You should check if the characteristic notification has stopped. If it has, you should disconnect from it */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {

    if (characteristic.isNotifying) {
        NSLog(@"Notification began on %@", characteristic);
    } else {
        // Notification has stopped
          [self.manager cancelPeripheralConnection:peripheral];
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {

    NSLog(@"didDisconnectPeripheral");
    self.mainLabel.stringValue = @"";
    self.btDevice = nil;
    [self.manager scanForPeripheralsWithServices:nil options: @{ CBCentralManagerScanOptionAllowDuplicatesKey : @NO}];
}


- (IBAction)readCR:(id)sender {

//    [self.btDevice writeValue:[ @"wrote value" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.btWriteCr type:CBCharacteristicWriteWithResponse];
}

#pragma mark - Utils 

- (void)performActionForButton:(NSString *)buttonString {

    if ([buttonString isEqualToString:@"b1"]) {


    } else if ([buttonString isEqualToString:@"b2"]) {


    } else {

    }
}

- (CBRange)rangeFromRSSI:(NSInteger)rssi {

    if (rssi < -70)
        return CBRangeFar;
    if (rssi < -55)
        return CBRangeNear;
    if (rssi < 0)
        return CBRangeImmediate;

    return CBRangeUnknown;
}



@end
