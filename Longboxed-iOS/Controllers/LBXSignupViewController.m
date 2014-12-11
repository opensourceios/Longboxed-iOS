//
//  LBXSignupViewController.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 12/10/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXSignupViewController.h"
#import "LBXMessageBar.h"
#import "LBXDatabaseManager.h"
#import "LBXLogging.h"
#import "LBXControllerServices.h"
#import "LBXClient.h"

#import "UIFont+customFonts.h"

#import <UICKeyChainStore.h>

@interface LBXSignupViewController ()

@property (nonatomic, strong) IBOutlet UIButton *signupButton;
@property (nonatomic, strong) IBOutlet UITextField *usernameField;
@property (nonatomic, strong) IBOutlet UITextField *passwordField;
@property (nonatomic) LBXClient *client;

@end

@implementation LBXSignupViewController

UICKeyChainStore *store;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    store = [UICKeyChainStore keyChainStore];
    _client = [[LBXClient alloc] init];
    
    [_signupButton setTitle:@"     CREATE FREE ACCOUNT     " forState:UIControlStateNormal];
    _signupButton.layer.borderWidth = 1.0f;
    _signupButton.layer.cornerRadius = 6.0f;
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
    [_usernameField becomeFirstResponder];
    self.navigationController.navigationBar.topItem.title = @"Sign Up";
}

- (IBAction)buttonPressed:(id)sender
{
    UIButton *button = (UIButton *)sender;
    switch ([button tag])
    {
        case 0:
            [self signup];
            break;
    }
}

# pragma mark Private Methods

- (void)signup
{
    if (![_usernameField.text length]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Email Required" message:@"Please enter an email address." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        alert.tintColor = [UIColor blackColor];
        [alert show];
        return;
    }
    else if (![_passwordField.text length]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Password Required" message:@"Please enter a Password." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        alert.tintColor = [UIColor blackColor];
        [alert show];
        return;
    }
    
    [LBXControllerServices removeCredentials];
    [self.client registerWithEmail:_usernameField.text password:_passwordField.text passwordConfirm:_passwordField.text withCompletion:^(NSDictionary *responseDict, AFHTTPRequestOperation *response, NSError *error) {
        if (!error) {
            [UICKeyChainStore setString:_usernameField.text forKey:@"username"];
            [UICKeyChainStore setString:_passwordField.text forKey:@"password"];
            [self login];
        }
        else {
            [LBXLogging logMessage:[NSString stringWithFormat:@"Error signing up user %@", _usernameField.text]];
            [LBXControllerServices removeCredentials];
            [LBXDatabaseManager flushBundlesAndPullList];
            
            NSString *errorMessage = [NSString new];
            for (NSString *errorKey in responseDict.allKeys) {
                if (((NSArray *)responseDict[errorKey]).count) errorMessage = responseDict[errorKey];
            }
        
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error Signing Up" message:[NSString stringWithFormat:@"%@", errorMessage] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alert show];
            
            dispatch_async(dispatch_get_main_queue(),^{
                _passwordField.text = @"";
                [_usernameField becomeFirstResponder];
            });
        }
    }];
}

- (void)login
{
    [LBXDatabaseManager flushBundlesAndPullList];
    [self.client fetchLogInWithCompletion:^(LBXUser *user, RKObjectRequestOperation *response, NSError *error) {
        if (response.HTTPRequestOperation.response.statusCode == 200) {
            dispatch_async(dispatch_get_main_queue(),^{
                [UICKeyChainStore setString:[NSString stringWithFormat:@"%@", user.userID] forKey:@"id"];
                [store synchronize];
                [LBXMessageBar displaySuccessWithTitle:@"Registration Successful" andSubtitle:@"Successfully created account"];
                [LBXLogging logLogin];
                [self.navigationController popViewControllerAnimated:YES];
            });
        }
        else {
            [LBXLogging logMessage:[NSString stringWithFormat:@"Unsuccessful log in for %@", _usernameField.text]];
            [LBXControllerServices removeCredentials];
            [LBXDatabaseManager flushBundlesAndPullList];
            
            [LBXMessageBar displayErrorWithTitle:@"Registration Error" andSubtitle:@"Unable to create account"];
        }
    }];
}

@end
