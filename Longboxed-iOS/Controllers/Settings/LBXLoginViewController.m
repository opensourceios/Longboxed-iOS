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
#import "LBXAppDelegate.h"

#import "UIFont+LBXCustomFonts.h"

#import <UICKeyChainStore.h>
#import <OnePasswordExtension.h>
#import <AYVibrantButton.h>
#import <SVProgressHUD.h>
#import <BSKeyboardControls.h>

@interface LBXLoginViewController () <BSKeyboardControlsDelegate, UITextFieldDelegate, UITextViewDelegate>

@property (nonatomic, strong) IBOutlet UIButton *loginButton;
@property (nonatomic, strong) IBOutlet UIButton *forgotPasswordButton;
@property (nonatomic, strong) IBOutlet UITextField *usernameField;
@property (nonatomic, strong) IBOutlet UITextField *passwordField;
@property (nonatomic) LBXClient *client;
@property (nonatomic, strong) BSKeyboardControls *keyboardControls;

@end

@implementation LBXLoginViewController

UICKeyChainStore *store;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    // Custom initialization
    store = [UICKeyChainStore keyChainStore];
    _client = [[LBXClient alloc] init];
    
    // Do any additional setup after loading the view from its nib.
    store = [UICKeyChainStore keyChainStore];
    _usernameField.text = store[@"username"];
    _passwordField.text = store[@"password"];
    
    // Set the log in button text
    if ([_passwordField.text isEqualToString:@""]) [self setButtonsForLoggedOut];
    else [self setButtonsForLoggedIn];
    
    [_loginButton setTitle:@"                         " forState:UIControlStateNormal];
    
    // Add the ability to dismiss the keyboard
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
    
    // Setup the textfields for BSKeyboardControls
    NSArray *fields = @[self.usernameField, self.passwordField];
    [self setKeyboardControls:[[BSKeyboardControls alloc] initWithFields:fields]];
    self.keyboardControls.barTintColor = [UIColor blackColor];
    [self.keyboardControls setDelegate:self];
    self.usernameField.delegate = self;
    self.passwordField.delegate = self;

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [LBXControllerServices setViewWillAppearWhiteNavigationController:self];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0], NSFontAttributeName : [UIFont navTitleFont]}];
    [[UITextField appearanceWhenContainedIn:[self class], nil] setFont:[UIFont settingsTableViewFont]];
    [[UITextField appearance] setTintColor:[UIColor blackColor]];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    AYVibrantButton *invertButton = [[AYVibrantButton alloc] initWithFrame:_loginButton.frame style:AYVibrantButtonStyleInvert];
    invertButton.vibrancyEffect = nil;
    invertButton.backgroundColor = [UIColor blackColor];
    invertButton.text = @"LOG IN";
    invertButton.font = _loginButton.titleLabel.font;
    [invertButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    invertButton.tag = 0;
    
    // Only add the button once (this method gets called multiple times)
    BOOL needsAdded = YES;
    for (UIView *view in self.view.subviews) {
        if ([view isKindOfClass:[AYVibrantButton class]]) needsAdded = NO;
    }
    if (needsAdded) [self.view addSubview:invertButton];
    
    if ([[OnePasswordExtension sharedExtension] isAppExtensionAvailable]) {
        UIImage *image = [UIImage imageNamed:@"onepassword-button"];
        CGRect frame = CGRectMake(0, 0, image.size.width, image.size.height);
        //init a normal UIButton using that image
        UIButton* button = [[UIButton alloc] initWithFrame:frame];
        [button setBackgroundImage:image forState:UIControlStateNormal];
        [button addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchDown];
        
        UIBarButtonItem *anotherButton = [[UIBarButtonItem alloc] initWithCustomView:button];
        
        button.tag = 1;
        self.navigationItem.rightBarButtonItem = anotherButton;
    }
    
    // Add cancel button if presented modally (no back button title)
    if (!self.navigationController.navigationBar.backItem.title) {
        UIBarButtonItem *actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(donePressed)];
        self.navigationItem.leftBarButtonItem = actionButton;
    }
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (![LBXControllerServices isLoggedIn]) [_usernameField becomeFirstResponder];
    self.navigationController.navigationBar.topItem.title = @"Log In";
}

# pragma mark BSKeyboardControls Delegate Methods

- (void)keyboardControlsDonePressed:(BSKeyboardControls *)keyboardControls
{
    [keyboardControls.activeField resignFirstResponder];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self.keyboardControls setActiveField:textField];
}

# pragma mark Private Methods

- (void)dismissKeyboard {
    [_usernameField resignFirstResponder];
    [_passwordField resignFirstResponder];
}


- (void)login
{
    [LBXControllerServices removeCredentials];
    [LBXDatabaseManager flushBundlesAndPullList];
    [UICKeyChainStore setString:_usernameField.text forKey:@"username"];
    [UICKeyChainStore setString:_passwordField.text forKey:@"password"];
    [self.client fetchLogInWithCompletion:^(LBXUser *user, RKObjectRequestOperation *response, NSError *error) {
        if (response.HTTPRequestOperation.response.statusCode == 200) {
            dispatch_async(dispatch_get_main_queue(),^{
                [UICKeyChainStore setString:[NSString stringWithFormat:@"%@", user.userID] forKey:@"id"];
                [LBXLogging logLogin];
                [self setButtonsForLoggedIn];
                // Dismiss if presented modally (no back button title)
                if (!self.navigationController.navigationBar.backItem.title) {
                    [self.view endEditing:YES];
                    [(LBXAppDelegate *)[[UIApplication sharedApplication] delegate] handleOnboardingCompletion];
                }
                else [self.navigationController popViewControllerAnimated:YES];
                [SVProgressHUD showSuccessWithStatus:@"Logged In!"];
                
                [[NSNotificationCenter defaultCenter]
                 postNotificationName:@"reloadDashboard"
                 object:self];
            });
        }
        else {
            [LBXLogging logMessage:[NSString stringWithFormat:@"Incorrect log in %@", _usernameField.text]];
            [LBXControllerServices removeCredentials];
            [self setButtonsForLoggedOut];
            [LBXDatabaseManager flushBundlesAndPullList];
            
            dispatch_async(dispatch_get_main_queue(),^{
                [SVProgressHUD setForegroundColor: [UIColor blackColor]];
                [SVProgressHUD setBackgroundColor: [UIColor whiteColor]];
                [SVProgressHUD showErrorWithStatus:@"Incorrect Credentials"];
                _passwordField.text = @"";
                [_passwordField becomeFirstResponder];
            });
        }
    }];
}

- (IBAction)buttonPressed:(id)sender
{
    UIButton *button = (UIButton *)sender;
    switch ([button tag])
    {
        // Log in
        case 0:
        {
            [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeBlack];
            [self login];
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
            [LBXControllerServices presentWebViewOverViewController:self withTitle:@"Reset Password" URL:[NSURL URLWithString:@"https://longboxed.com/reset"]];
            break;
        }
    }
}

- (void)setButtonsForLoggedIn
{
    _loginButton.hidden = YES;
    _forgotPasswordButton.hidden = YES;
    _usernameField.userInteractionEnabled = NO;
    _passwordField.userInteractionEnabled = NO;
    _usernameField.textColor = [UIColor lightGrayColor];
    _passwordField.textColor = [UIColor lightGrayColor];
}

- (void)setButtonsForLoggedOut
{
    _forgotPasswordButton.hidden = NO;
    _usernameField.userInteractionEnabled = YES;
    _passwordField.userInteractionEnabled = YES;
    _usernameField.textColor = [UIColor blackColor];
    _passwordField.textColor = [UIColor blackColor];
}

- (void)donePressed
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

@end
