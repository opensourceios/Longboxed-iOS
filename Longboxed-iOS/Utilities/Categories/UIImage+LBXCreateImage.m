//
//  UIImage+CreateImage.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 9/30/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "UIImage+LBXCreateImage.h"
#import "PaintCodeImages.h"
#import "UIColor+LBXCustomColors.h"

@implementation UIImage (CreateImage)

+ (UIImage *)defaultCoverImage
{
    return [PaintCodeImages imageOfDefaultCoverWithColor:[UIColor LBXVeryLightGrayColor] background:[UIColor clearColor] width:500 height:750];
}

+ (UIImage *)defaultCoverImageWithWhiteBackground
{
    //    return [PaintCodeImages imageOfDefaultCoverWithColor:[UIColor blackColor] background:[UIColor whiteColor] width:500 height:750];
    return [UIImage imageNamed:@"lb_nocover"];
}

@end
