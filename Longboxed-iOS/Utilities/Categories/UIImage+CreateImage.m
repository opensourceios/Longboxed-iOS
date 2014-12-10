//
//  UIImage+CreateImage.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 9/30/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "UIImage+CreateImage.h"
#import "PaintCodeImages.h"
#import "UIColor+customColors.h"

@implementation UIImage (CreateImage)

+ (UIImage *)singlePixelImageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)imageWithColor:(UIColor *)color rect:(CGRect)rect {
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

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
