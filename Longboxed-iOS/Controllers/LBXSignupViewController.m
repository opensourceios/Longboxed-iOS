//
//  LBXSignupViewController.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 12/10/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXSignupViewController.h"
#import "LBXDatabaseManager.h"
#import "LBXLogging.h"
#import "LBXControllerServices.h"
#import "LBXClient.h"
#import "LBXAppDelegate.h"

#import "UIFont+LBXCustomFonts.h"

#import <UICKeyChainStore.h>
#import <OnePasswordExtension.h>
#import <AYVibrantButton.h>
#import <SVProgressHUD.h>
#import <BSKeyboardControls.h>

@interface LBXSignupViewController () <BSKeyboardControlsDelegate, UITextFieldDelegate, UITextViewDelegate>

@property (nonatomic, strong) IBOutlet UIButton *signupButton;
@property (nonatomic, strong) IBOutlet UITextField *usernameField;
@property (nonatomic, strong) IBOutlet UITextField *passwordField;
@property (nonatomic) LBXClient *client;
@property (nonatomic, strong) BSKeyboardControls *keyboardControls;

@end

@implementation LBXSignupViewController

UICKeyChainStore *store;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    store = [UICKeyChainStore keyChainStore];
    _client = [[LBXClient alloc] init];
    
    [_signupButton setTitle:@"                                                           " forState:UIControlStateNormal];

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
    AYVibrantButton *invertButton = [[AYVibrantButton alloc] initWithFrame:_signupButton.frame style:AYVibrantButtonStyleInvert];
    invertButton.vibrancyEffect = nil;
    invertButton.backgroundColor = [UIColor blackColor];
    invertButton.text = @"CREATE FREE ACCOUNT";
    invertButton.font = _signupButton.titleLabel.font;
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
        [button addTarget:self action:@selector(saveLoginTo1Password:) forControlEvents:UIControlEventTouchDown];
        
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
    [_usernameField becomeFirstResponder];
    self.navigationController.navigationBar.topItem.title = @"Sign Up";
}

- (void)dismissKeyboard {
    [_usernameField resignFirstResponder];
    [_passwordField resignFirstResponder];
}

- (IBAction)buttonPressed:(id)sender
{
    UIButton *button = (UIButton *)sender;
    switch ([button tag])
    {
        case 0:
            [self signup];
            break;
        case 1:
            [LBXControllerServices presentWebViewOverViewController:self withTitle:@"Privacy Policy" URL:[NSURL URLWithString:@"https://longboxed.com/privacy"]];
            break;
    }
}

- (IBAction)saveLoginTo1Password:(id)sender {
    NSDictionary *newLoginDetails = @{
                                      AppExtensionTitleKey: @"Longboxed",
                                      AppExtensionUsernameKey: _usernameField.text ? : @"",
                                      AppExtensionPasswordKey: _passwordField.text ? : @"",
                                      AppExtensionNotesKey: @"Saved with the Longboxed iOS app",
                                      };
    
    // Password generation options are optional, but are very handy in case you have strict rules about password lengths
    NSDictionary *passwordGenerationOptions = @{
                                                AppExtensionGeneratedPasswordMinLengthKey: @(6),
                                                AppExtensionGeneratedPasswordMaxLengthKey: @(50),
                                                };
    
    [[OnePasswordExtension sharedExtension] storeLoginForURLString:@"https://www.longboxed.com" loginDetails:newLoginDetails passwordGenerationOptions:passwordGenerationOptions forViewController:self sender:sender completion:^(NSDictionary *loginDict, NSError *error) {
        
        if (!loginDict) {
            if (error.code != AppExtensionErrorCodeCancelledByUser) {
                NSLog(@"Failed to use 1Password App Extension to save a new Login: %@", error);
            }
            return;
        }
        
        _usernameField.text = loginDict[AppExtensionUsernameKey] ? : @"";
        _passwordField.text = loginDict[AppExtensionPasswordKey] ? : @"";
    }];
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

- (void)signup
{
    if (![_usernameField.text length]) {
        [LBXControllerServices showAlertWithTitle:@"Email Required" andMessage:@"Please enter an email address."];
        return;
    }
    
    else if (![_passwordField.text length]) {
        [LBXControllerServices showAlertWithTitle:@"Password Required" andMessage:@"Please enter a Password."];
        return;
    }
    
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeBlack];
    
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
            [SVProgressHUD dismiss];
            
            NSString *errorMessage = [NSString new];
            for (NSString *errorKey in responseDict.allKeys) {
                if (((NSArray *)responseDict[errorKey]).count) errorMessage = responseDict[errorKey][0];
            }
            
            [LBXControllerServices showAlertWithTitle:@"Error Signing Up" andMessage:[NSString stringWithFormat:@"%@", errorMessage]];

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
                [SVProgressHUD showSuccessWithStatus:@"Registration Successful!"];
                [LBXLogging logLogin];
                
                // Dismiss if presented modally (no back button title)
                if (!self.navigationController.navigationBar.backItem.title) {
                    [self.view endEditing:YES];
                    [(LBXAppDelegate *)[[UIApplication sharedApplication] delegate] handleOnboardingCompletion];
                }
                else [self.navigationController popViewControllerAnimated:YES];
            });
        }
        else {
            [LBXLogging logMessage:[NSString stringWithFormat:@"Unsuccessful log in for %@", _usernameField.text]];
            [LBXControllerServices removeCredentials];
            [LBXDatabaseManager flushBundlesAndPullList];
            [SVProgressHUD showSuccessWithStatus:@"Registration Error"];
        }
    }];
}

- (void)donePressed
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

@end
