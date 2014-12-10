//
//  LBXLoginViewController.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 12/10/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXLoginViewController.h"
#import "LBXControllerServices.h"
#import "LBXDatabaseManager.h"
#import "LBXClient.h"
#import "LBXUser.h"
#import "LBXLogging.h"
#import "LBXMessageBar.h"
#import "SVModalWebViewController.h"

#import <UICKeyChainStore.h>
#import <TWMessageBarManager.h>
#import <OnePasswordExtension.h>

@interface LBXLoginViewController ()

@property (nonatomic, retain) IBOutlet UIButton *onePasswordButton;
@property (nonatomic, strong) IBOutlet UIButton *loginButton;
@property (nonatomic, strong) IBOutlet UIButton *forgotPasswordButton;
@property (nonatomic, strong) IBOutlet UITextField *usernameField;
@property (nonatomic, strong) IBOutlet UITextField *passwordField;
@property (nonatomic) LBXClient *client;

@end

@implementation LBXLoginViewController

UICKeyChainStore *store;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    // Custom initialization
    store = [UICKeyChainStore keyChainStore];
    _client = [[LBXClient alloc] init];
    
    // Only show the 1Password button if the app is installed
    [self.onePasswordButton setHidden:![[OnePasswordExtension sharedExtension] isAppExtensionAvailable]];
    
    // Do any additional setup after loading the view from its nib.
    store = [UICKeyChainStore keyChainStore];
    _usernameField.text = store[@"username"];
    _passwordField.text = store[@"password"];
    
    // Set the log in button text
    if ([_passwordField.text isEqualToString:@""]) [self setButtonsForLoggedOut];
    else [self setButtonsForLoggedIn];

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [LBXControllerServices setViewWillAppearWhiteNavigationController:self];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (![LBXControllerServices isLoggedIn]) [_usernameField becomeFirstResponder];
    self.navigationController.navigationBar.topItem.title = @"Log In";
}

# pragma mark Private Methods

- (void)login
{
    [LBXControllerServices removeCredentials];
    [LBXDatabaseManager flushBundlesAndPullList];
    [UICKeyChainStore setString:_usernameField.text forKey:@"username"];
    [UICKeyChainStore setString:_passwordField.text forKey:@"password"];
    [store synchronize]; // Write to keychain.
    [self.client fetchLogInWithCompletion:^(LBXUser *user, RKObjectRequestOperation *response, NSError *error) {
        if (response.HTTPRequestOperation.response.statusCode == 200) {
            dispatch_async(dispatch_get_main_queue(),^{
                [UICKeyChainStore setString:[NSString stringWithFormat:@"%@", user.userID] forKey:@"id"];
                [store synchronize];
                [LBXMessageBar successfulLogin];
                [LBXLogging logLogin];
                [self setButtonsForLoggedIn];
            });
        }
        else {
            [LBXLogging logMessage:[NSString stringWithFormat:@"Incorrect log in %@", _usernameField.text]];
            [LBXControllerServices removeCredentials];
            [self setButtonsForLoggedOut];
            [LBXDatabaseManager flushBundlesAndPullList];
            
            dispatch_async(dispatch_get_main_queue(),^{
                [LBXMessageBar incorrectCredentials];
                _passwordField.text = @"";
                [_usernameField becomeFirstResponder];
            });
        }
    }];
}

- (IBAction)buttonPressed:(id)sender
{
    UIButton *button = (UIButton *)sender;
    switch ([button tag])
    {
        // Log in/out
        case 0:
        {
            if ([button.titleLabel.text isEqualToString:@"Log Out"]) {
                [LBXLogging logLogout];
                [LBXControllerServices removeCredentials];
                [LBXDatabaseManager flushBundlesAndPullList];
                [LBXMessageBar successfulLogout];
                _usernameField.text = @"";
                _passwordField.text = @"";
                [_usernameField becomeFirstResponder];
                [self setButtonsForLoggedOut];
            }
            else {
                [self login];
            }
            
            break;
        }
        // 1Password
        case 1:
        {
            [[OnePasswordExtension sharedExtension] findLoginForURLString:@"https://www.longboxed.com" forViewController:self sender:sender completion:^(NSDictionary *loginDict, NSError *error) {
                if (!loginDict) {
                    if (error.code != AppExtensionErrorCodeCancelledByUser) {
                        NSLog(@"Error invoking 1Password App Extension for find login: %@", error);
                    }
                    return;
                }
                _usernameField.text = loginDict[AppExtensionUsernameKey];
                _passwordField.text = loginDict[AppExtensionPasswordKey];
                [_loginButton sendActionsForControlEvents:UIControlEventTouchUpInside];
            }];
            break;
        }
        // Forgot password
        case 2:
        {
            [LBXLogging logMessage:[NSString stringWithFormat:@"Forgot password"]];
            SVModalWebViewController *webViewController = [[SVModalWebViewController alloc] initWithAddress:@"http://longboxed.com/reset"];
            webViewController.modalPresentationStyle = UIModalPresentationPageSheet;
            webViewController.barsTintColor = [UIColor blackColor];
            [self presentViewController:webViewController animated:YES completion:nil];
            break;
            
        }
    }
}

- (void)setButtonsForLoggedIn
{
    [_loginButton setTitle:@"Log Out" forState:UIControlStateNormal];
    _onePasswordButton.hidden = YES;
    _forgotPasswordButton.hidden = YES;
    _usernameField.userInteractionEnabled = NO;
    _passwordField.userInteractionEnabled = NO;
    _usernameField.textColor = [UIColor lightGrayColor];
    _passwordField.textColor = [UIColor lightGrayColor];
}

- (void)setButtonsForLoggedOut
{
    [_loginButton setTitle:@"Log In" forState:UIControlStateNormal];
    _onePasswordButton.hidden = NO;
    _forgotPasswordButton.hidden = NO;
    _usernameField.userInteractionEnabled = YES;
    _passwordField.userInteractionEnabled = YES;
    _usernameField.textColor = [UIColor blackColor];
    _passwordField.textColor = [UIColor blackColor];
}

@end
