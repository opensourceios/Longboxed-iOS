//
//  LBXLoginViewController.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 6/30/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXLoginViewController.h"
#import "LBXNavigationViewController.h"
#import "LBXDatabaseManager.h"
#import "LBXClient.h"
#import "LBXMessageBar.h"
#import "LBXEndpoints.h"

#import <UICKeyChainStore.h>
#import <TWMessageBarManager.h>
#import "RestKit/RestKit.h"

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
    // Do any additional setup after loading the view from its nib.
    store = [UICKeyChainStore keyChainStore];
    _usernameField.text = store[@"username"];
    _passwordField.text = store[@"password"];
    [_developmentServerSwitch addTarget:self
                                 action:@selector(stateChanged:)
                       forControlEvents:UIControlEventValueChanged];
    
    [_developmentServerSwitch setOn:YES animated:NO];
    RKResponseDescriptor *responseDescriptor = [RKObjectManager sharedManager].responseDescriptors[0];
    if ([[responseDescriptor.baseURL absoluteString] isEqualToString:@"http://www.longboxed.com"]) {
        [_developmentServerSwitch setOn:NO animated:NO];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)removeCredentials
{
    [UICKeyChainStore removeItemForKey:@"username"];
    [UICKeyChainStore removeItemForKey:@"password"];
    [UICKeyChainStore removeItemForKey:@"id"];
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

            break;
        }
        // Log out
        case 1:
        {
            [self removeCredentials];
            [LBXDatabaseManager flushDatabase];
            [LBXMessageBar successfulLogout];
            _usernameField.text = @"";
            _passwordField.text = @"";
            [_usernameField becomeFirstResponder];
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
