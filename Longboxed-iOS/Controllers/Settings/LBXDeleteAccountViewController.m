//
//  LBXDeleteAccountViewController.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 12/10/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXDeleteAccountViewController.h"
#import "LBXControllerServices.h"
#import "LBXLogging.h"
#import "LBXDatabaseManager.h"
#import "LBXClient.h"

#import "UIFont+LBXCustomFonts.h"  

#import <UICKeyChainStore.h>
#import <SVProgressHUD.h>
#import <AYVibrantButton.h>
#import "SIAlertView.h"

@interface LBXDeleteAccountViewController ()

@property (nonatomic, strong) IBOutlet UIButton *deleteAccountButton;
@property (nonatomic, strong) IBOutlet UITextField *passwordField;
@property (nonatomic) LBXClient *client;

@end

@implementation LBXDeleteAccountViewController

UICKeyChainStore *store;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    store = [UICKeyChainStore keyChainStore];
    _client = [[LBXClient alloc] init];
    
    [_deleteAccountButton setTitle:@"                                                                           " forState:UIControlStateNormal];
    
    // Add the ability to dismiss the keyboard
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [LBXControllerServices setViewWillAppearWhiteNavigationController:self];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    [[UITextField appearanceWhenContainedIn:[self class], nil] setFont:[UIFont settingsTableViewFont]];
    [[UITextField appearance] setTintColor:[UIColor blackColor]];
}

- (void)viewDidLayoutSubviews
{
    AYVibrantButton *invertButton = [[AYVibrantButton alloc] initWithFrame:_deleteAccountButton.frame style:AYVibrantButtonStyleInvert];
    invertButton.vibrancyEffect = nil;
    invertButton.backgroundColor = [UIColor blackColor];
    invertButton.text = @"DELETE ACCOUNT AND ALL DATA";
    invertButton.font = _deleteAccountButton.titleLabel.font;
    [invertButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    invertButton.tag = 0;
    
    // Only add the button once (this method gets called multiple times)
    BOOL needsAdded = YES;
    for (UIView *view in self.view.subviews) {
        if ([view isKindOfClass:[AYVibrantButton class]]) needsAdded = NO;
    }
    if (needsAdded) [self.view addSubview:invertButton];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [_passwordField becomeFirstResponder];
    self.navigationController.navigationBar.topItem.title = @"Delete Account";
}

- (void)dismissKeyboard {
    [_passwordField resignFirstResponder];
}

- (IBAction)buttonPressed:(id)sender
{
    UIButton *button = (UIButton *)sender;
    switch ([button tag])
    {
        case 0:
            [self deleteAccount];
            break;
    }
}

# pragma mark Private Methods

- (void)deleteAccount
{
    if (![_passwordField.text length]) {
        [LBXControllerServices showAlertWithTitle:@"Password Required" andMessage:@"Enter your password to confirm and delete your account."];
        return;
    }
    
    if (![_passwordField.text isEqualToString:[store stringForKey:@"password"]]) {
        [LBXControllerServices showAlertWithTitle:@"Wrong Password" andMessage:@"Sorry, that's the wrong password."];
        _passwordField.text = @"";
        return;
    }
    
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeBlack];
    [self.client deleteAccountWithCompletion:^(NSDictionary *responseDict, AFHTTPRequestOperation *response, NSError *error) {
        if (!error) {
            [SVProgressHUD showSuccessWithStatus:@"Account Deleted"];
            [LBXControllerServices removeCredentials];
            [LBXDatabaseManager flushBundlesAndPullList];
            [self.navigationController popViewControllerAnimated:YES];
            
        }
        else {
            [LBXLogging logMessage:[NSString stringWithFormat:@"Error deleting account for %@", [store stringForKey:@"id"]]];
            
            NSString *errorMessage = [NSString new];
            for (NSString *errorKey in responseDict.allKeys) {
                if (((NSArray *)responseDict[errorKey]).count) errorMessage = responseDict[errorKey][0];
            }
            
            [LBXControllerServices showAlertWithTitle:@"Error Deleting Account" andMessage:[NSString stringWithFormat:@"%@", errorMessage]];
            
            dispatch_async(dispatch_get_main_queue(),^{
                _passwordField.text = @"";
                [_passwordField becomeFirstResponder];
            });
        }
    }];
}

@end
