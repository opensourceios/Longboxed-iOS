//
//  LBXLoginViewController.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 6/30/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXLoginViewController.h"
#import "LBXNavigationDropDownViewController.h"
#import "LBXClient.h"
#import "PaperButton.h"

#import <POP/POP.h>
#import <UICKeyChainStore.h>
#import <TWMessageBarManager.h>

@interface LBXLoginViewController ()

@property (nonatomic, strong) IBOutlet UIButton *loginButton;
@property (nonatomic, strong) IBOutlet UITextField *usernameField;
@property (nonatomic, strong) IBOutlet UITextField *passwordField;

@property (nonatomic) LBXClient *client;

@end

@implementation LBXLoginViewController

UICKeyChainStore *store;
PaperButton *button;

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


-(IBAction)buttonPressed:(id)sender
{
    UIButton *button = (UIButton *)sender;

    
    switch ([button tag])
    {
        // Log in
        case 0:
        {
            [UICKeyChainStore setString:_usernameField.text forKey:@"username"];
            [UICKeyChainStore setString:_passwordField.text forKey:@"password"];
            [store synchronize]; // Write to keychain.
            [self.client fetchLogInWithCompletion:^(id json, NSURLResponse *response, NSError *error) {
                NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
                int responseStatusCode = (int)[httpResponse statusCode];
                if (responseStatusCode == 200) {
                    dispatch_async(dispatch_get_main_queue(),^{
                        [UICKeyChainStore setString:[NSString stringWithFormat:@"%@",json[@"id"]] forKey:@"id"];
                        [store synchronize];
                        [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"Log In Successful"
                                                                   description:@"Logged in successfully."
                                                                          type:TWMessageBarMessageTypeSuccess];
                    });
                }
                else {
                    [self removeCredentials];
                    
                    dispatch_async(dispatch_get_main_queue(),^{
                        [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"Incorrect Credentials"
                                                                   description:@"Your username or password is incorrect."
                                                                          type:TWMessageBarMessageTypeError];
                        _usernameField.text = @"";
                        _passwordField.text = @"";
                        [_usernameField becomeFirstResponder];
                    });
                }
            }];
            

            break;
        }
        // Log out
        case 1:
        {
            [self removeCredentials];
            [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"Logged Out"
                                                           description:@"Successfully logged out."
                                                                  type:TWMessageBarMessageTypeError];
            _usernameField.text = @"";
            _passwordField.text = @"";
            [_usernameField becomeFirstResponder];
        }
    }
}

@end
