//
//  LBXAboutViewController.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 1/15/15.
//  Copyright (c) 2015 Longboxed. All rights reserved.
//

#import "LBXAboutViewController.h"
#import "PaintCodeImages.h"
#import "UIColor+LBXCustomColors.h"
#import "UIFont+LBXCustomFonts.h"

#import <UICKeyChainStore.h>
#import <SVProgressHUD.h>
#import <TTTAttributedLabel.h>
#import <WebKit/WebKit.h>

@interface LBXAboutViewController () <TTTAttributedLabelDelegate>

@property (nonatomic, strong) IBOutlet UIImageView *iconImageView;
@property (nonatomic, strong) IBOutlet UILabel *versionLabel;
@property (nonatomic, strong) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) IBOutlet TTTAttributedLabel *footerLabel;

@end

@implementation LBXAboutViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.title = @"About";
    
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *version = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    NSString *buildNumber = [infoDictionary objectForKey:@"CFBundleVersion"];
    
    _versionLabel.text = [NSString stringWithFormat:@"Longboxed %@",
                        version];
    
    _footerLabel.enabledTextCheckingTypes = NSTextCheckingTypeLink;
    _footerLabel.delegate = self;
    _footerLabel.text = [NSString stringWithFormat:@"Longboxed %@ (%@)\nBy Tim Bueno and Jay Hickey", version, buildNumber];
    NSRange range = [_footerLabel.text rangeOfString:@"Tim Bueno"];
    [_footerLabel addLinkToURL:[NSURL URLWithString:@"http://twitter.com/timbueno/"] withRange:range];
    NSRange range2 = [_footerLabel.text rangeOfString:@"Jay Hickey"];
    [_footerLabel addLinkToURL:[NSURL URLWithString:@"http://twitter.com/jayhickey/"] withRange:range2];
    NSArray *keys = [[NSArray alloc] initWithObjects:(id)kCTForegroundColorAttributeName,(id)kCTUnderlineStyleAttributeName
                     , nil];
    NSArray *objects = [[NSArray alloc] initWithObjects:[UIColor blackColor],[NSNumber numberWithInt:kCTUnderlineStyleNone], nil];
    NSDictionary *linkAttributes = [[NSDictionary alloc] initWithObjects:objects forKeys:keys];
    
    _footerLabel.linkAttributes = linkAttributes;
    self.iconImageView.image = [PaintCodeImages imageOfLongboxedLogoWithColor:[UIColor LBXVeryLightGrayColor] width:self.view.frame.size.width - 32];
    _scrollView.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height);
}

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    UIViewController *linkViewController = [UIViewController new];
    WKWebView *webView = [[WKWebView alloc] initWithFrame:self.view.frame];
    UIView *view = [[UIView alloc] initWithFrame:self.view.frame];
    view.backgroundColor = [UIColor whiteColor];
    linkViewController.view = view;
    [view addSubview:webView];
    UINavigationController *navigationController =
    [[UINavigationController alloc] initWithRootViewController:linkViewController];
    
    UIBarButtonItem *actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(donePressed)];
    UILabel *alabel = [UILabel new];
    alabel.text = @"Twitter";
    label.font = [UIFont navTitleFont];
    [alabel sizeToFit];
    linkViewController.navigationItem.titleView = alabel;
    linkViewController.navigationItem.rightBarButtonItem = actionButton;
    
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url cachePolicy: NSURLRequestUseProtocolCachePolicy timeoutInterval:20];
    [webView loadRequest: request];
    
    //now present this navigation controller modally
    [self presentViewController:navigationController
                       animated:YES
                     completion:^{
                     }];
}

- (void)donePressed
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewWillLayoutSubviews {
    _scrollView.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height);
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



@end
