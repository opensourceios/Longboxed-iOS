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

@interface LBXEmptyViewController ()

@end

@implementation LBXEmptyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    _imageView.image = [PaintCodeImages imageOfLongboxedLogoWithColor:[UIColor LBXVeryLightGrayColor] width:_imageView.frame.size.width];
    _messageLabel.textColor = [UIColor colorWithHex:@"#E0E1E2"];
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
