//
//  ModalViewController.m
//  Found
//
//  Created by alex on 11/21/14.
//  Copyright (c) 2014 SDWR. All rights reserved.
//
#import "ViewController.h"
#import "ModalViewController.h"

@interface ModalViewController ()
@property (strong, nonatomic) IBOutlet UITextView *uuidTextField;

@end

@implementation ModalViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	self.uuidTextField.text = [[NSUserDefaults standardUserDefaults] valueForKey:SDWUUIDKey];
}

- (IBAction)finishEnteringUUID:(id)sender {

	[[NSUserDefaults standardUserDefaults] setValue:self.uuidTextField.text forKey:SDWUUIDKey];
	[[NSUserDefaults standardUserDefaults] synchronize];

	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
