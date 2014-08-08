//
//  UIFont+customFonts.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 8/4/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "UIFont+customFonts.h"
#import "UIFontDescriptor+AvenirNext.h"

@implementation UIFont (customFonts)

+ (UIFont *)menuFont
{
    return [UIFont fontWithName:@"AvenirNext-Regular" size:20];
}

+ (UIFont *)navTitleFont
{
    return [UIFont menuFont];
}

+ (UIFont *)searchFont
{
    return [UIFont fontWithName:@"AvenirNext-Regular" size:20];
}

+ (UIFont *)searchCancelFont
{
    return [UIFont fontWithName:@"AvenirNext-Regular" size:16];
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
    // Set to 17, should be 18
    return [UIFont fontWithDescriptor:[UIFontDescriptor preferredAvenirNextMediumFontDescriptorWithTextStyle:UIFontTextStyleHeadline] size: 0];
}

+ (UIFont *)pullListSubtitleFont
{
    return [UIFont fontWithDescriptor:[UIFontDescriptor preferredAvenirNextCondensedMediumFontDescriptorWithTextStyle:UIFontTextStyleCaption2] size: 0];
}

@end
