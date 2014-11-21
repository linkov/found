//
//  AppDelegate.m
//  Found
//
//  Created by alex on 11/21/14.
//  Copyright (c) 2014 SDWR. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    return YES;
}

-(void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    UIAlertView * av = [[UIAlertView alloc] initWithTitle:@"Proximity alert"
                                                  message:notification.alertBody
                                                 delegate:NULL
                                        cancelButtonTitle:@"OK"
                                        otherButtonTitles:nil, nil];
    [av show];
}

@end
