//
//  LBXLoginViewController.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 6/30/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXLoginViewController.h"
#import "LBXNavigationViewController.h"

#import <UICKeyChainStore.h>
#import <CWStatusBarNotification.h>

@interface LBXLoginViewController ()

@property (nonatomic, strong) IBOutlet UIButton *loginButton;
@property (nonatomic, strong) IBOutlet UITextField *usernameField;
@property (nonatomic, strong) IBOutlet UITextField *passwordField;

@end

@implementation LBXLoginViewController

UICKeyChainStore *store;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        // Custom initialization
        self.title = @"Log In";
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"hamburger-button"] style:UIBarButtonItemStyleBordered target:self.navigationController action:@selector(toggleMenu)];
        [self.navigationItem.rightBarButtonItem setTintColor:[UIColor lightGrayColor]];
        NSDictionary *fontDict = [NSDictionary dictionaryWithObjectsAndKeys:
                    [UIFont fontWithName:@"HelveticaNeue-Thin" size:18.0], NSFontAttributeName, [UIColor blackColor], NSForegroundColorAttributeName, nil];
        [[UIBarButtonItem appearance] setTitleTextAttributes:fontDict forState:UIControlStateNormal];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    store = [UICKeyChainStore keyChainStore];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(IBAction)buttonPressed:(id)sender
{
    UIButton *button = (UIButton *)sender;
    
    CWStatusBarNotification *notification = [CWStatusBarNotification new];
    notification.notificationLabelTextColor = [UIColor whiteColor];
    notification.notificationAnimationInStyle = CWNotificationAnimationStyleTop;
    notification.notificationAnimationOutStyle = CWNotificationAnimationStyleTop;
    
    switch ([button tag])
    {
        // Log in
        case 0:
        {
            [UICKeyChainStore setString:_usernameField.text forKey:@"username"];
            [UICKeyChainStore setString:_passwordField.text forKey:@"password"];
            [store synchronize]; // Write to keychain.
         
            notification.notificationLabelBackgroundColor = [UIColor blueColor];
            [notification displayNotificationWithMessage:@"Logged in!" forDuration:3.0f];
            break;
        }
        // Log out
        case 1:
        {
            [UICKeyChainStore removeItemForKey:@"username"];
            [UICKeyChainStore removeItemForKey:@"password"];
            [store synchronize]; // Write to keychain.
            
            notification.notificationLabelBackgroundColor = [UIColor redColor];
            [notification displayNotificationWithMessage:@"Logged out!" forDuration:3.0f];
        }
    }
}

@end
