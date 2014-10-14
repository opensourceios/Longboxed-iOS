//
//  LBXEmptyPullListViewController.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 9/20/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXEmptyPullListViewController.h"
#import "PaintCodeImages.h"
#import "SDiPhoneVersion.h"

#import "UIColor+customColors.h"

@interface LBXEmptyPullListViewController ()

@end

@implementation LBXEmptyPullListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    _mainImageView.image = [PaintCodeImages imageOfLongboxedLogoWithColor:[UIColor LBXVeryLightGrayColor] width:_mainImageView.frame.size.width];
    _plusImageView.image = [PaintCodeImages imageOfPlusWithColor:[UIColor LBXVeryLightGrayColor] width:_plusImageView.frame.size.width];
    _arrowImageView.image = [PaintCodeImages imageOfArrowWithColor:[UIColor LBXVeryLightGrayColor] width:_arrowImageView.frame.size.width];
    _titleLabel.textColor = [UIColor colorWithHex:@"#E0E1E2"];
    _subtitleLabel.textColor = [UIColor colorWithHex:@"#E0E1E2"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLayoutSubviews
{
    NSDictionary *viewsDictionary = @{@"arrowImageView":self.arrowImageView};
    NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[arrowImageView]-9-|"
                                                                   options:0
                                                                   metrics:nil
                                                                     views:viewsDictionary];
    
    // To align the empty view arrow below the plus button on iPhone 6 Plus
    if ([SDiPhoneVersion deviceVersion] == iPhone6Plus) {
        constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[arrowImageView]-12-|"
                                                              options:0
                                                              metrics:nil
                                                                views:viewsDictionary];
    }
    [self.view addConstraints:constraints];
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
