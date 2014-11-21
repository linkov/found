//
//  ViewController.m
//  Found
//
//  Created by alex on 11/21/14.
//  Copyright (c) 2014 SDWR. All rights reserved.
//

#import "ViewController.h"

NSString * const SDWUUIDKey  =  @"com.swdr.found.uuid";
static NSString *beaconId = @"com.sdwr.found.beaconid";

@interface ViewController () <CBPeripheralManagerDelegate, CLLocationManagerDelegate>
@property (strong, nonatomic) IBOutlet UILabel *statusLabel;

@property CLBeaconRegion *beaconRegion;
@property CBPeripheralManager *peripheralManager;
@property NSMutableDictionary *peripheralData;
@property CLLocationManager *locationManager;
@property CLProximity previousProximity;
@property (strong) NSUUID *uid;

@property (strong, nonatomic) IBOutlet UIButton *generateIDButton;
@property (strong, nonatomic) IBOutlet UILabel *generatedIDLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {

	if ([[NSUserDefaults standardUserDefaults] valueForKey:SDWUUIDKey]) {
		self.uid = [[NSUUID alloc]initWithUUIDString:[[NSUserDefaults standardUserDefaults] valueForKey:SDWUUIDKey]];
		self.generatedIDLabel.text = [self.uid UUIDString];
		[self setupBeacon];
	}
}

#pragma mark - Beacon setup
- (void)setupBeacon {

	self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:self.uid identifier:beaconId];

	[self.beaconRegion setNotifyEntryStateOnDisplay:YES];
	[self.beaconRegion setNotifyOnEntry:YES];
	[self.beaconRegion setNotifyOnExit:YES];

	[self configureAsTransmitter];
	[self configureAsReceiver];
}

- (void)configureAsTransmitter {

	NSNumber *power = [NSNumber numberWithInt:-63];
	self.peripheralData = [self.beaconRegion peripheralDataWithMeasuredPower:power];

	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:queue];
}

- (void)configureAsReceiver {

	self.locationManager = [[CLLocationManager alloc] init];
	self.locationManager.delegate = self;
	[self.locationManager requestAlwaysAuthorization];
	[self.locationManager startMonitoringForRegion:self.beaconRegion];
	[self.locationManager startRangingBeaconsInRegion:self.beaconRegion];
}


#pragma mark - CBPeripheralManagerDelegate
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {

	if (peripheral.state == CBPeripheralManagerStatePoweredOn) {
		[self.peripheralManager startAdvertising:self.peripheralData];
	} else if (peripheral.state == CBPeripheralManagerStatePoweredOff) {
		[self.peripheralManager stopAdvertising];
	}
}

#pragma mark - CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {

	if ([region.identifier isEqualToString:beaconId]) {
		UILocalNotification *notification = [[UILocalNotification alloc] init];
		notification.alertBody = @"Parter nearby.";
		[[UIApplication sharedApplication] presentLocalNotificationNow:notification];
	}
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {

	if ([region.identifier isEqualToString:beaconId]) {
		UILocalNotification *notification = [[UILocalNotification alloc] init];
		notification.alertBody = @"Parter goes away.";
		[[UIApplication sharedApplication] presentLocalNotificationNow:notification];
	}
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region {
	if ([beacons count] == 0)
		return;

	NSString *message;
	UIColor *bgColor;

	CLBeacon *beacon = [beacons firstObject];
	switch (beacon.proximity) {
		case CLProximityUnknown:
			message = @"Unknown proximity";
			bgColor = [UIColor whiteColor];
			break;

		case CLProximityFar:
			message = @"CLProximityFar";
			bgColor = [UIColor greenColor];
			break;

		case CLProximityNear:
			message = @"CLProximityNear";
			bgColor = [UIColor orangeColor];
			break;

		case CLProximityImmediate:
		default:
			message = @"CLProximityImmediate";
			bgColor = [UIColor redColor];
			break;
	}

	if (beacon.proximity != self.previousProximity) {
		[self.statusLabel setText:message];
		[self.view setBackgroundColor:bgColor];
		self.previousProximity = beacon.proximity;
	}
}

#pragma mark - Actions
- (IBAction)generateIDAction:(id)sender {

	NSUUID *uid = [NSUUID UUID];
	[[NSUserDefaults standardUserDefaults] setValue:[uid UUIDString] forKey:SDWUUIDKey];
	[[NSUserDefaults standardUserDefaults] synchronize];

	self.generatedIDLabel.hidden = NO;
	self.generatedIDLabel.text = [uid UUIDString];
	self.uid = uid;
	[self setupBeacon];

	UIPasteboard *pb = [UIPasteboard generalPasteboard];
	[pb setString:self.generatedIDLabel.text];
}

@end
