//
//  LBXCustomURLViewController.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 3/13/15.
//  Copyright (c) 2015 Longboxed. All rights reserved.
//

#import "LBXCustomURLViewController.h"
#import "RestKit/RestKit.h"
#import <UICKeyChainStore.h>
#import <SVProgressHUD.h>
#import "LBXEndpoints.h"
#import "LBXDatabaseManager.h"
#import "LBXLogging.h"
#import "LBXClient.h"
#import "LBXControllerServices.h"

@interface LBXCustomURLViewController () <UITextFieldDelegate>

@property (nonatomic) IBOutlet UITextField *textField;
@property (nonatomic) IBOutlet UIButton *stagingURLButton;
@property (nonatomic) IBOutlet UIButton *productionURLButton;

@end

@implementation LBXCustomURLViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self.textField becomeFirstResponder];
    self.textField.delegate = self;
    self.textField.text = [UICKeyChainStore stringForKey:@"baseURLString"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.navigationController.navigationBar.topItem.title = @"Development Server";
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self setURLWithString:self.textField.text];
}

# pragma mark Private Methods

- (IBAction)buttonPressed:(id)sender {
    switch ([sender tag]) {
        // Production
        case 0:
            self.textField.text = [[LBXEndpoints productionURL] absoluteString];
            break;
        case 1:
            self.textField.text = [[LBXEndpoints stagingURL] absoluteString];
            break;
        default:
            break;
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)setURLWithString:(NSString *)urlString {
    for (RKResponseDescriptor *descriptor in [RKObjectManager sharedManager].responseDescriptors) {
        descriptor.baseURL = [NSURL URLWithString:urlString];
    }
    [[RKObjectManager sharedManager] setHTTPClient:[AFHTTPClient clientWithBaseURL:[NSURL URLWithString:urlString]]];
    RKObjectManager.sharedManager.HTTPClient.allowsInvalidSSLCertificate = YES;
    [UICKeyChainStore setString:urlString forKey:@"baseURLString"];
    [self login];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    [textField resignFirstResponder];
   
    
    return YES;
}

- (void)login
{
    LBXClient *client = [LBXClient new];
    [LBXControllerServices showLoadingWithDimBackground:NO];
    [LBXDatabaseManager flushBundlesAndPullList];
    [client fetchLogInWithCompletion:^(LBXUser *user, RKObjectRequestOperation *response, NSError *error) {
        if (response.HTTPRequestOperation.response.statusCode == 200) {
            dispatch_async(dispatch_get_main_queue(),^{
                [LBXLogging logMessage:[NSString stringWithFormat:@"Successful dev toggle log in %@", [[UICKeyChainStore keyChainStore] stringForKey:@"username"]]];
                [LBXControllerServices showSuccessHUDWithTitle:@"Logged In!" dimBackground:NO];
                [LBXLogging logLogin];
            });
        }
        else {
            [LBXLogging logMessage:[NSString stringWithFormat:@"Unsuccessful log in for %@", [[UICKeyChainStore keyChainStore] stringForKey:@"username"]]];
            [LBXControllerServices removeCredentials];
            [LBXDatabaseManager flushBundlesAndPullList];
        }
    }];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
