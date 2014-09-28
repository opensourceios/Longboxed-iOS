//
//  PaintCodeImages.h
//  Longboxed-iOS
//
//  Created by Jay Hickey on 9/21/14.
//  Copyright (c) 2014 Jay Hickey. All rights reserved.
//
//  Generated by PaintCode (www.paintcodeapp.com)
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface PaintCodeImages : NSObject

// iOS Controls Customization Outlets
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* plusTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* arrowTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* longboxedLogoTargets;

// Generated Images
+ (UIImage*)imageOfPlusWithColor: (UIColor*)color width: (CGFloat)width;
+ (UIImage*)imageOfArrowWithColor: (UIColor*)color width: (CGFloat)width;
+ (UIImage*)imageOfLongboxedLogoWithColor: (UIColor*)color width: (CGFloat)width;

@end