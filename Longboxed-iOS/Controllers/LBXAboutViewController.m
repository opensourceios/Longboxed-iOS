//
//  LBXAboutViewController.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 1/15/15.
//  Copyright (c) 2015 Longboxed. All rights reserved.
//

#import "LBXAboutViewController.h"
#import <DropboxSDK/DropboxSDK.h>
#import <UICKeyChainStore.h>
#import <SVProgressHUD.h>

@interface LBXAboutViewController () <DBRestClientDelegate>

@property (nonatomic) DBRestClient *restClient;

@property (nonatomic, strong) IBOutlet UIImageView *aboutImageView;

@end

@implementation LBXAboutViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.title = @"About";
    self.restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
    self.restClient.delegate = self;
    if ([UICKeyChainStore stringForKey:@"dropboxRoot"]) {
        [self.restClient loadMetadata:[UICKeyChainStore stringForKey:@"dropboxRoot"]];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata {
    if (metadata.isDirectory) {
        NSLog(@"Folder '%@' contains:", metadata.path);
        for (DBMetadata *file in metadata.contents) {
            if ([file.filename isEqualToString:@"about.png"]) {
                [SVProgressHUD showWithStatus:@"Loading Image"];
                [self.restClient loadFile:file.path intoPath:[NSTemporaryDirectory() stringByAppendingPathComponent:file.filename]];
                
            }
        }
    }
}

- (void)restClient:(DBRestClient *)client loadMetadataFailedWithError:(NSError *)error {
    NSLog(@"Error loading metadata: %@", error);
}

- (void)restClient:(DBRestClient*)client loadedFile:(NSString*)destPath {
    [SVProgressHUD dismiss];
    _aboutImageView.image = [UIImage imageWithContentsOfFile:destPath];
}



@end
