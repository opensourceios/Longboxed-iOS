//
//  LBXLoginViewController.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 6/30/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXLoginViewController.h"
#import "LBXDashboardViewController.h"
#import "LBXDatabaseManager.h"
#import "LBXClient.h"
#import "LBXMessageBar.h"
#import "LBXEndpoints.h"
#import "LBXLogging.h"

#import <UICKeyChainStore.h>
#import <TWMessageBarManager.h>
#import <OnePasswordExtension.h>
#import "RestKit/RestKit.h"

#import "UIFont+customFonts.h"

@interface LBXLoginViewController ()

@property (nonatomic, strong) IBOutlet UIButton *loginButton;
@property (nonatomic, strong) IBOutlet UITextField *usernameField;
@property (nonatomic, strong) IBOutlet UITextField *passwordField;
@property (nonatomic, strong) IBOutlet UISwitch *developmentServerSwitch;

@property (nonatomic) LBXClient *client;

@end

@implementation LBXLoginViewController

UICKeyChainStore *store;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        // Custom initialization
        _client = [[LBXClient alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Only show the 1Password button if the app is installed
    [self.onePasswordButton setHidden:![[OnePasswordExtension sharedExtension] isAppExtensionAvailable]];
    
    // Do any additional setup after loading the view from its nib.
    store = [UICKeyChainStore keyChainStore];
    _usernameField.text = store[@"username"];
    _passwordField.text = store[@"password"];
    [_developmentServerSwitch addTarget:self
                                 action:@selector(stateChanged:)
                       forControlEvents:UIControlEventValueChanged];
    
    UIBarButtonItem *actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(donePressed)];
    self.navigationItem.rightBarButtonItem = actionButton;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [_developmentServerSwitch setOn:YES animated:NO];
    RKResponseDescriptor *responseDescriptor = [RKObjectManager sharedManager].responseDescriptors[0];
    if ([[responseDescriptor.baseURL absoluteString] isEqualToString:[[LBXEndpoints productionURL] absoluteString]]) {
        [_developmentServerSwitch setOn:NO animated:NO];
    }
    [self.navigationItem setHidesBackButton:YES animated:YES];
}

- (void)viewWillLayoutSubviews
{
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0], NSFontAttributeName : [UIFont navTitleFont]}];
    self.navigationController.navigationBar.topItem.title = @"Settings";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)donePressed
{
    [self.navigationController pushViewController:[LBXDashboardViewController new] animated:YES];
}

- (void)removeCredentials
{
    [UICKeyChainStore removeAllItems];
    [store synchronize]; // Write to keychain.
}

// UISwitch
- (void)stateChanged:(UISwitch *)switchState
{
    // Use staging server
    if ([switchState isOn]) {
        // Set the response descriptors and the shared manager to the new base URL
        for (RKResponseDescriptor *descriptor in [RKObjectManager sharedManager].responseDescriptors) {
            descriptor.baseURL = [LBXEndpoints stagingURL];
        }
        [[RKObjectManager sharedManager] setHTTPClient:[AFHTTPClient clientWithBaseURL:[LBXEndpoints stagingURL]]];
        [UICKeyChainStore setString:[[LBXEndpoints stagingURL] absoluteString] forKey:@"baseURLString"];
        [store synchronize];
        
        [self login];
    }
    // Use production server
    else {
        // Set the response descriptors and the shared manager to the new base URL
        for (RKResponseDescriptor *descriptor in [RKObjectManager sharedManager].responseDescriptors) {
            descriptor.baseURL = [LBXEndpoints productionURL];
        }
        [[RKObjectManager sharedManager] setHTTPClient:[AFHTTPClient clientWithBaseURL:[LBXEndpoints productionURL]]];
        [UICKeyChainStore setString:[[LBXEndpoints productionURL] absoluteString] forKey:@"baseURLString"];
        [store synchronize];
        
        [self login];
    }
}

- (IBAction)buttonPressed:(id)sender
{
    UIButton *button = (UIButton *)sender;
    switch ([button tag])
    {
        // Log in
        case 0:
        {
            [self login];
            [self dismissViewControllerAnimated:YES completion:nil];

            break;
        }
        // Log out
        case 1:
        {
            [LBXLogging logLogout];
            [self removeCredentials];
            [LBXDatabaseManager flushDatabase];
            [LBXMessageBar successfulLogout];
            _usernameField.text = @"";
            _passwordField.text = @"";
            [_usernameField becomeFirstResponder];
            
            break;
        }
        // 1Password
        case 2:
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
    }
}

# pragma mark Private Methods
- (void)login
{
    [self removeCredentials];
    [LBXDatabaseManager flushDatabase];
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
            });
        }
        else {
            [self removeCredentials];
            [LBXDatabaseManager flushDatabase];
            
            dispatch_async(dispatch_get_main_queue(),^{
                [LBXMessageBar incorrectCredentials];
                _passwordField.text = @"";
                [_usernameField becomeFirstResponder];
            });
        }
    }];
}

@end
