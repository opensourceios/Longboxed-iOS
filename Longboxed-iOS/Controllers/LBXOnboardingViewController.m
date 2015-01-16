//
//  LBXOnboardingViewController.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 1/15/15.
//  Copyright (c) 2015 Longboxed. All rights reserved.
//

#import "LBXOnboardingViewController.h"
#import <DropboxSDK/DropboxSDK.h>
#import <UICKeyChainStore.h>
#import <SVProgressHUD.h>

@interface LBXOnboardingViewController () <DBRestClientDelegate>

@property (nonatomic, retain) IBOutlet UIScrollView *scrollView;
@property (nonatomic) DBRestClient *restClient;

@end

@implementation LBXOnboardingViewController

int imageCount = 0;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"longboxed_full"]];
    
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

- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata {
    if (metadata.isDirectory) {
        imageCount = 0;
        NSMutableArray *mutableArray = [NSMutableArray arrayWithArray:metadata.contents];
        NSSortDescriptor* sortByName = [NSSortDescriptor sortDescriptorWithKey:@"filename" ascending:YES];
        [mutableArray sortUsingDescriptors:[NSArray arrayWithObject:sortByName]];
        for (DBMetadata *file in mutableArray) {
            if ([file.filename containsString:@"onboarding"]) {
                [SVProgressHUD showWithStatus:@"Loading Image(s)"];
                [self.restClient loadFile:file.path intoPath:[NSTemporaryDirectory() stringByAppendingPathComponent:file.filename]];
                imageCount++;
            }
        }
        self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * imageCount, self.scrollView.frame.size.height);
    }
}

- (void)restClient:(DBRestClient *)client loadMetadataFailedWithError:(NSError *)error {
    NSLog(@"Error loading metadata: %@", error);
}

- (void)restClient:(DBRestClient*)client loadedFile:(NSString*)destPath {
    NSString *fileName = [[destPath lastPathComponent] stringByDeletingPathExtension];
    
    // Get the number from the file name
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"([0-9]+)" options:NSRegularExpressionCaseInsensitive error:&error];
    NSTextCheckingResult* result = [regex firstMatchInString:fileName options:0 range:NSMakeRange(0, [fileName length])];
    NSRange groupOne = [result rangeAtIndex:1];
    int num = [[fileName substringWithRange:groupOne] intValue] - 1;
    
    UIImage *image = [UIImage imageWithContentsOfFile:destPath];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.frame.size.width * num, 0, self.view.frame.size.width, self.view.frame.size.height)];
    imageView.image = image;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.scrollView addSubview:imageView];
                              
    [SVProgressHUD dismiss];
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
