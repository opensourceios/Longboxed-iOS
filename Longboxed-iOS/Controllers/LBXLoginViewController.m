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

#import "UIFont+LBXCustomFonts.h"

#import <UICKeyChainStore.h>
#import <OnePasswordExtension.h>
#import <AYVibrantButton.h>
#import <SVProgressHUD.h>

@interface LBXLoginViewController ()

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
    
    // Do any additional setup after loading the view from its nib.
    store = [UICKeyChainStore keyChainStore];
    _usernameField.text = store[@"username"];
    _passwordField.text = store[@"password"];
    
    // Set the log in button text
    if ([_passwordField.text isEqualToString:@""]) [self setButtonsForLoggedOut];
    else [self setButtonsForLoggedIn];
    
    [_loginButton setTitle:@"                         " forState:UIControlStateNormal];
    
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
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (![LBXControllerServices isLoggedIn]) [_usernameField becomeFirstResponder];
    self.navigationController.navigationBar.topItem.title = @"Log In";
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
    [store synchronize]; // Write to keychain.
    [self.client fetchLogInWithCompletion:^(LBXUser *user, RKObjectRequestOperation *response, NSError *error) {
        if (response.HTTPRequestOperation.response.statusCode == 200) {
            dispatch_async(dispatch_get_main_queue(),^{
                [UICKeyChainStore setString:[NSString stringWithFormat:@"%@", user.userID] forKey:@"id"];
                [store synchronize];
                [LBXLogging logLogin];
                [self setButtonsForLoggedIn];
                [self.navigationController popViewControllerAnimated:YES];
                [SVProgressHUD showSuccessWithStatus:@"Logged In!"];
            });
        }
        else {
            [LBXLogging logMessage:[NSString stringWithFormat:@"Incorrect log in %@", _usernameField.text]];
            [LBXControllerServices removeCredentials];
            [self setButtonsForLoggedOut];
            [LBXDatabaseManager flushBundlesAndPullList];
            
            dispatch_async(dispatch_get_main_queue(),^{
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
            
            UIViewController *forgotViewController = [UIViewController new];
            WKWebView *webView = [[WKWebView alloc] initWithFrame:self.view.frame];
            UIView *view = [[UIView alloc] initWithFrame:self.view.frame];
            view.backgroundColor = [UIColor whiteColor];
            forgotViewController.view = view;
            [view addSubview:webView];
            UINavigationController *navigationController =
            [[UINavigationController alloc] initWithRootViewController:forgotViewController];
            
            UIBarButtonItem *actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(donePressed)];
            UILabel *label = [UILabel new];
            label.text = @"Reset Password";
            label.font = [UIFont navTitleFont];
            [label sizeToFit];
            forgotViewController.navigationItem.titleView = label;
            forgotViewController.navigationItem.rightBarButtonItem = actionButton;
            
            NSURLRequest *request = [[NSURLRequest alloc] initWithURL: [NSURL URLWithString:@"http://longboxed.com/reset-ios"] cachePolicy: NSURLRequestUseProtocolCachePolicy timeoutInterval:20];
            [webView loadRequest: request];
            
            //now present this navigation controller modally
            [self presentViewController:navigationController
                               animated:YES
                             completion:^{
                             }];
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
