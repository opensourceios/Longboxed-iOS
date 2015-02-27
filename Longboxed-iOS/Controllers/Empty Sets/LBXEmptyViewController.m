//
//  LBXEmptyBundleViewController.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 2/3/15.
//  Copyright (c) 2015 Longboxed. All rights reserved.
//

#import "LBXEmptyViewController.h"
#import "PaintCodeImages.h"
#import "UIColor+LBXCustomColors.h"
#import "SDiPhoneVersion.h"

@interface LBXEmptyViewController ()

@end

@implementation LBXEmptyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Load the open source credits json file
    NSString *path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Quotes.json"];
    NSArray *quotesArray = [NSArray new];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        quotesArray = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:path]
                                                          options:kNilOptions
                                                            error:nil][@"quotes"];
    }
    
    NSUInteger randomIndex = arc4random() % [quotesArray count];
    
    // Do any additional setup after loading the view from its nib.
    _imageView.image = [PaintCodeImages imageOfLongboxedLogoWithColor:[UIColor LBXVeryLightGrayColor] width:_imageView.frame.size.width];
    _quoteLabel.textColor = [UIColor colorWithHex:@"#E0E1E2"];
    _authorLabel.textColor = [UIColor colorWithHex:@"#E0E1E2"];
    _quoteLabel.text = quotesArray[randomIndex][@"quote"];
    
    UIFont *authorFont = [UIFont fontWithName:@"AvenirNext-Regular" size:16.0];
    NSDictionary *authorDict = [NSDictionary dictionaryWithObject:authorFont forKey:NSFontAttributeName];
    NSMutableAttributedString *aAttrString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@, ", quotesArray[randomIndex][@"author"]] attributes:authorDict];
    
    
    NSString *inIssueString = quotesArray[randomIndex][@"issue"];
    UIFont *issueFont = [UIFont fontWithName:@"AvenirNext-Italic" size:16.0];
    NSDictionary *issueDict = [NSDictionary dictionaryWithObject:issueFont forKey:NSFontAttributeName];
    NSMutableAttributedString *vAttrString = [[NSMutableAttributedString alloc]initWithString: inIssueString attributes:issueDict];
    
    [aAttrString appendAttributedString:vAttrString];
    
    _authorLabel.attributedText = aAttrString;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLayoutSubviews
{
    // If there is a segmented control (Releases view), hide the "nothing here yet text"
    for (UIView *view in self.view.superview.superview.subviews) {
        if ([view isKindOfClass:[UIView class]]) {
            for (UIView *subview in view.subviews) {
                // Just for iPhone 4
                if ([subview isKindOfClass:[UISegmentedControl class]] && [SDiPhoneVersion deviceSize] < 2) {
                    _nothingHereYetLabel.text = @"";
                    _nothingHereYetLabel.hidden = YES;
                }
            }
        }
    }
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
