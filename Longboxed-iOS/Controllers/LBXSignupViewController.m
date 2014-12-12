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
#import <OnePasswordExtension.h>

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
    
    __weak typeof (self) miniMe = self;
    
    [[OnePasswordExtension sharedExtension] storeLoginForURLString:@"https://www.longboxed.com" loginDetails:newLoginDetails passwordGenerationOptions:passwordGenerationOptions forViewController:self sender:sender completion:^(NSDictionary *loginDict, NSError *error) {
        
        if (!loginDict) {
            if (error.code != AppExtensionErrorCodeCancelledByUser) {
                NSLog(@"Failed to use 1Password App Extension to save a new Login: %@", error);
            }
            return;
        }
        
        __strong typeof(self) strongMe = miniMe;
        
        _usernameField.text = loginDict[AppExtensionUsernameKey] ? : @"";
        _passwordField.text = loginDict[AppExtensionPasswordKey] ? : @"";
    }];
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
