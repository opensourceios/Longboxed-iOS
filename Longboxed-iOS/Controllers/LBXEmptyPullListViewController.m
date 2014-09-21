//
//  LBXEmptyPullListViewController.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 9/20/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXEmptyPullListViewController.h"
#import "PaintCodeImages.h"

@interface LBXEmptyPullListViewController ()

@end

@implementation LBXEmptyPullListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    _mainImageView.image = [PaintCodeImages imageOfLongboxedLogoWithWidth:_mainImageView.frame.size.width];
    _plusImageView.image = [PaintCodeImages imageOfPlusWithWidth:_plusImageView.frame.size.width];
    _arrowImageView.image = [PaintCodeImages imageOfArrowWithWidth:_arrowImageView.frame.size.width];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLayoutSubviews
{

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
