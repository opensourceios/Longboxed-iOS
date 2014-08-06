//
//  UIFont+customFonts.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 8/4/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "UIFont+customFonts.h"

@implementation UIFont (customFonts)

+ (UIFont *)menuFont
{
    return [UIFont fontWithName:@"AvenirNext-Regular" size:20];
}

+ (UIFont *)navTitleFont
{
    return [UIFont fontWithName:@"AvenirNext-Regular" size:20];
}

+ (UIFont *)searchFont
{
    return [UIFont fontWithName:@"AvenirNext-Regular" size:20];
}

+ (UIFont *)searchCancelFont
{
    return [UIFont fontWithName:@"AvenirNext-Regular" size:18];
}

+ (UIFont *)searchPlaceholderFont
{
    return [UIFont fontWithName:@"AvenirNext-Regular" size:14];
}


+ (UIFont *)noResultsFont
{
    return [UIFont fontWithName:@"AvenirNext-Regular" size:24];
}

+ (UIFont *)collectionTitleFont
{
    return [UIFont fontWithName:@"AvenirNextCondensed-UltraLight" size:36];
}

+ (UIFont *)collectionSubtitleFont
{
    return [UIFont fontWithName:@"AvenirNext-Regular" size:12];
}

+ (UIFont *)pullListTitleFont
{
    return [UIFont fontWithName:@"AvenirNext-Medium" size:20.0];
}

+ (UIFont *)pullListSubtitleFont
{
    return [UIFont fontWithName:@"AvenirNext-UltraLightItalic" size:18.0];
}

@end
