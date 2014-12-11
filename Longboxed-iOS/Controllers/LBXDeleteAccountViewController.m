//
//  LBXDeleteAccountViewController.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 12/10/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXDeleteAccountViewController.h"
#import "LBXControllerServices.h"
#import "LBXMessageBar.h"
#import "LBXLogging.h"
#import "LBXDatabaseManager.h"
#import "LBXClient.h"

#import "UIFont+customFonts.h"  

#import <UICKeyChainStore.h>

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
    
    [_deleteAccountButton setTitle:@"     DELETE ACCOUNT AND ALL DATA     " forState:UIControlStateNormal];
    _deleteAccountButton.layer.borderWidth = 1.0f;
    _deleteAccountButton.layer.cornerRadius = 6.0f;
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

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [_passwordField becomeFirstResponder];
    self.navigationController.navigationBar.topItem.title = @"Delete Account";
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
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Password Required" message:@"Enter your password to confirm and delete your account." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        alert.tintColor = [UIColor blackColor];
        [alert show];
        return;
    }
    
    if (![_passwordField.text isEqualToString:[store stringForKey:@"password"]]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Wrong Password" message:@"Sorry, that's the wrong password." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        alert.tintColor = [UIColor blackColor];
        [alert show];
        _passwordField.text = @"";
        return;
    }

    [self.client deleteAccountWithCompletion:^(NSDictionary *responseDict, AFHTTPRequestOperation *response, NSError *error) {
        if (!error) {
            [LBXLogging logMessage:[NSString stringWithFormat:@"Deleted account for %@", [store stringForKey:@"id"]]];
            [LBXMessageBar displaySuccessWithTitle:@"Accounted Deleted" andSubtitle:[NSString stringWithFormat:@"Successfully deleted account for %@", [store stringForKey:@"username"]]];
            [LBXControllerServices removeCredentials];
            [LBXDatabaseManager flushBundlesAndPullList];
            [self.navigationController popViewControllerAnimated:YES];
            
        }
        else {
            [LBXLogging logMessage:[NSString stringWithFormat:@"Error deleting account for %@", [store stringForKey:@"id"]]];
            
            NSString *errorMessage = [NSString new];
            for (NSString *errorKey in responseDict.allKeys) {
                if (((NSArray *)responseDict[errorKey]).count) errorMessage = responseDict[errorKey];
            }
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error Deleting Account" message:[NSString stringWithFormat:@"%@", errorMessage] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alert show];
            
            dispatch_async(dispatch_get_main_queue(),^{
                _passwordField.text = @"";
                [_passwordField becomeFirstResponder];
            });
        }
    }];
}

@end
