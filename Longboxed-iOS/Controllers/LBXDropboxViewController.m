//
//  LBXDropboxViewController.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 1/15/15.
//  Copyright (c) 2015 Longboxed. All rights reserved.
//

#import "LBXDropboxViewController.h"
#import "LBXControllerServices.h"
#import <UICKeyChainStore.h>
#import <DropboxSDK/DropboxSDK.h>
#import <SVProgressHUD.h>

@interface LBXDropboxViewController () <DBRestClientDelegate>

@property (nonatomic) DBRestClient *restClient;

@property (nonatomic, strong) IBOutlet UIButton *linkDropboxButton;
@property (nonatomic, strong) IBOutlet UITextField *dropboxPathField;


@end

@implementation LBXDropboxViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Dropbox Path";
    // Do any additional setup after loading the view from its nib.
    NSString *buttonString = ([UICKeyChainStore stringForKey:@"dropboxRoot"]) ? [UICKeyChainStore stringForKey:@"dropboxRoot"] : nil;
    
    if (buttonString) [UICKeyChainStore setString:buttonString forKey:@"dropboxRoot"];
    [[UICKeyChainStore keyChainStore] synchronize]; // Write to keychain.
    
    _dropboxPathField.text = buttonString;
    
    self.restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
    self.restClient.delegate = self;
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    if ([[DBSession sharedSession] isLinked]) [self storePath];
}

- (void)storePath {
    [UICKeyChainStore setString:_dropboxPathField.text forKey:@"dropboxRoot"];
    [[UICKeyChainStore keyChainStore] synchronize]; // Write to keychain.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)buttonPressed:(id)sender {
    UIButton *button = (UIButton *)sender;
    switch ([button tag]) {
        case 0:
            if (![[DBSession sharedSession] isLinked]) {
                [[DBSession sharedSession] linkFromController:self];
                _dropboxPathField.text = @"/Shares/Longboxed Share";
                [self storePath];
            }
            else {
                [[DBSession sharedSession] unlinkAll];
                [[DBSession sharedSession] linkFromController:self];
            }
            break;
        case 1:
            [self storePath];
            [self.restClient loadMetadata:[UICKeyChainStore stringForKey:@"dropboxRoot"]];
            [SVProgressHUD showWithStatus:@"Loading folder contents"];
            break;
    }
}

- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata {
    if (metadata.isDirectory) {
        [SVProgressHUD dismiss];
        NSMutableString *alertString = [NSMutableString new];
        for (DBMetadata *file in metadata.contents) {
            [alertString appendString:[NSString stringWithFormat:@"%@\n", file.filename]];
        }
        if (alertString.length == 0) {
            alertString = [NSMutableString stringWithString:@"No files!"];
        }
        [LBXControllerServices showAlertWithTitle:[UICKeyChainStore stringForKey:@"dropboxRoot"] andMessage:alertString];
    }
}

- (void)restClient:(DBRestClient *)client loadMetadataFailedWithError:(NSError *)error {
    [SVProgressHUD dismiss];
    [SVProgressHUD showErrorWithStatus:@"Unable to load directory contents"];
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
