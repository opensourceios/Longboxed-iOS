//
//  UIFont+customFonts.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 8/4/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "UIFont+LBXCustomFonts.h"
#import "UIFontDescriptor+AvenirNext.h"

@implementation UIFont (LBXCustomFonts)

static const NSString *fontFace = @"AvenirNext";

+ (UIFont *)menuFont
{
    return [UIFont fontWithName:[NSString stringWithFormat:@"%@-Regular", fontFace] size:20];
}

+ (UIFont *)navTitleFont
{
    return [UIFont menuFont];
}

+ (UIFont *)navSubtitleFont
{
    return [UIFont fontWithName:[NSString stringWithFormat:@"%@-Regular", fontFace] size:17];
}

+ (UIFont *)segmentedControlFont
{
    return [UIFont fontWithName:[NSString stringWithFormat:@"%@-Regular", fontFace] size:13];
}

+ (UIFont *)searchFont
{
    return [UIFont fontWithName:[NSString stringWithFormat:@"%@-Regular", fontFace] size:16];
}

+ (UIFont *)searchCancelFont
{
    return [UIFont fontWithName:[NSString stringWithFormat:@"%@-Regular", fontFace] size:17];
}

+ (UIFont *)searchPlaceholderFont
{
    return [UIFont fontWithName:[NSString stringWithFormat:@"%@-Regular", fontFace] size:14];
}

+ (UIFont *)noResultsFont
{
    return [UIFont fontWithName:[NSString stringWithFormat:@"%@-Regular", fontFace] size:24];
}

// Pull List View

+ (UIFont *)collectionTitleFontUltraLight
{
    return [UIFont fontWithName:[NSString stringWithFormat:@"%@Condensed-UltraLight", fontFace] size:42];
}

+ (UIFont *)comicsViewFontUltraLight
{
    return [UIFont fontWithName:[NSString stringWithFormat:@"%@-UltraLight", fontFace] size:52];
}

+ (UIFont *)collectionTitleFontRegular
{
    return [UIFont fontWithName:[NSString stringWithFormat:@"%@Condensed-Regular", fontFace] size:36];
}

+ (UIFont *)collectionSubtitleFont
{
    return [UIFont fontWithName:[NSString stringWithFormat:@"%@-Regular", fontFace] size:12];
}

+ (UIFont *)SVProgressHUDFont
{
    return [UIFont fontWithName:[NSString stringWithFormat:@"%@-Regular", fontFace] size:14];
}

+ (UIFont *)browseTableViewFont
{
    return [UIFont fontWithName:[NSString stringWithFormat:@"%@-Regular", fontFace] size:18];
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

+ (UIFont *)settingsSectionHeaderFont
{
    return [UIFont fontWithName:[NSString stringWithFormat:@"%@-Regular", fontFace] size:14];
}

+ (UIFont *)settingsSectionFooterFont
{
    return [UIFont fontWithName:[NSString stringWithFormat:@"%@-Regular", fontFace] size:12];
}

+ (UIFont *)settingsTableViewFont
{
    return [UIFont fontWithName:[NSString stringWithFormat:@"%@-Regular", fontFace] size:16];
}


// Alert View

+ (UIFont *)alertViewTitleFont
{
    return [UIFont fontWithName:[NSString stringWithFormat:@"%@-Medium", fontFace] size:22];
}

+ (UIFont *)alertViewMessageFont
{
    return [UIFont fontWithName:[NSString stringWithFormat:@"%@-Regular", fontFace] size:16];
}

+ (UIFont *)alertViewMessageFontForCrash
{
    return [UIFont fontWithName:[NSString stringWithFormat:@"%@-Regular", fontFace] size:14];
}

+ (UIFont *)alertViewButtonFont
{
    return [UIFont fontWithName:[NSString stringWithFormat:@"%@-Regular", fontFace] size:18];
}

// Error message

+ (UIFont *)errorMessageFont
{
    return [UIFont fontWithName:[NSString stringWithFormat:@"%@-Medium", fontFace] size:14];
}

// Title Detail View

+ (UIFont *)titleDetailTitleFont
{
    return [UIFont fontWithName:[NSString stringWithFormat:@"%@Condensed-UltraLight", fontFace] size:45];
}

+ (UIFont *)titleDetailPublisherFont
{
    return [UIFont fontWithName:[NSString stringWithFormat:@"%@-Regular", fontFace] size:18];
}

+ (UIFont *)titleDetailSubscribersAndIssuesFont
{
    return [UIFont fontWithName:[NSString stringWithFormat:@"%@-Regular", fontFace] size:12];
}

+ (UIFont *)titleDetailLatestIssueFont
{
    return [UIFont fontWithName:[NSString stringWithFormat:@"%@-Regular", fontFace] size:10];
}

+ (UIFont *)titleDetailAddToPullListFont
{
    return [UIFont fontWithName:[NSString stringWithFormat:@"%@-Regular", fontFace] size:14];
}

// Issue Detail View
+ (UIFont *)issueDetailTitleFont
{
    return [UIFont fontWithName:[NSString stringWithFormat:@"%@Condensed-UltraLight", fontFace] size:42];
}

+ (UIFont *)issueDetailDescriptionFont
{
    return [UIFont fontWithName:[NSString stringWithFormat:@"%@-Regular", fontFace] size:12];
}

+ (UIFont *)actionSheetTitleFont
{
    return [UIFont fontWithName:[NSString stringWithFormat:@"%@-Medium", fontFace] size:16];
}

+ (UIFont *)calendarNumbersFont
{
    return [UIFont fontWithName:[NSString stringWithFormat:@"%@-Regular", fontFace] size:14];
}

+ (UIFont *)calendarMonthsFont
{
    return [UIFont fontWithName:[NSString stringWithFormat:@"%@-Regular", fontFace] size:24];
}

+ (UIFont *)featuredIssueDescriptionFont
{
    return [UIFont fontWithName:[NSString stringWithFormat:@"%@-Regular", fontFace] size:12];
}

+ (UIFont *)defaultPublisherInitialsFont
{
    return [UIFont fontWithName:[NSString stringWithFormat:@"%@-UltraLight", fontFace] size:36];
}

+ (UIFont *)detailPublisherInitialsFont
{
    return [UIFont fontWithName:[NSString stringWithFormat:@"%@-UltraLight", fontFace] size:80];
}

@end
