//
//  LBXTitleServices.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 8/10/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXControllerServices.h"
#import "UIFont+customFonts.h"

#import "NSDate+DateUtilities.h"
#import "UIColor+customColors.h"
#import "SVProgressHUD.h"
#import "PaintCodeImages.h"

#import <UIImageView+AFNetworking.h>
#import <CommonCrypto/CommonDigest.h>

@interface LBXControllerServices ()

@end

@implementation LBXControllerServices

+ (UIImage *)getDefaultCoverImage
{
    return [PaintCodeImages imageOfLongboxedLogoWithColor:[UIColor lightGrayColor] width:100];
}

+ (NSDate *)getLocalDate
{
    return [NSDate dateWithTimeInterval:[[NSTimeZone systemTimeZone] secondsFromGMT] sinceDate:[NSDate date]];
}

+ (NSDate *)getThisWednesdayOfDate:(NSDate *)date
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *componentsDay = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitWeekOfMonth|NSCalendarUnitWeekday fromDate:date];
    [componentsDay setWeekday:4];
    return [calendar dateFromComponents:componentsDay];
}

+ (NSDate *)getNextWednesdayOfDate:(NSDate *)date
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [NSDateComponents new];
    [components setWeekOfMonth:1];
    NSDate *newDate = [calendar dateByAddingComponents:components toDate:[LBXControllerServices getLocalDate] options:0];
    NSDateComponents *componentsDay = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitWeekOfMonth|NSCalendarUnitWeekday fromDate:newDate];
    [componentsDay setWeekday:4];
    return [calendar dateFromComponents:componentsDay];
}



// This is for the pull list view
+ (NSString *)timeSinceLastIssueForTitle:(LBXTitle *)title
{
    LBXIssue *issue = [self closestIssueForTitle:title];
    
    if (issue != nil) {
        return [NSString stringWithFormat:@"%@", [NSDate fuzzyTimeBetweenStartDate:issue.releaseDate andEndDate:[self getLocalDate]]];
    }
    return @"";
}

// This is for the pull list view
+ (LBXIssue *)closestIssueForTitle:(LBXTitle *)title
{
    if ([title.titleID  isEqual: @586]) {
        
    }
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"title.titleID == %@", title.titleID];
    NSArray *issuesArray = [LBXIssue MR_findAllSortedBy:@"releaseDate" ascending:NO withPredicate:predicate];
    
    if (issuesArray.count != 0) {
        
        LBXIssue *newestIssue = issuesArray[0];
        
        if (issuesArray.count > 1) {
            LBXIssue *secondNewestIssue = issuesArray[1];
            // Check if the latest issue is next week and the second latest issue is this week
            
            // If the second newest issues release date is more recent than 4 days ago
            if ([secondNewestIssue.releaseDate timeIntervalSinceDate:[self getLocalDate]] > -4*DAY) {
                return secondNewestIssue;
            }
            return newestIssue;
        }
        return newestIssue;
    }
    return nil;
}

+ (NSString *)localTimeZoneStringWithDate:(NSDate *)date
{
    NSDateFormatter *formatter = [NSDateFormatter new];
    [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    [formatter setDateStyle:NSDateFormatterLongStyle];
    
    NSNumberFormatter *numFormatter = [[NSNumberFormatter alloc] init];
    [numFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [numFormatter setMinimumFractionDigits:2];
    return [formatter stringFromDate:date];
}

+ (NSString *)getSubtitleStringWithTitle:(LBXTitle *)title uppercase:(BOOL)uppercase
{
    NSString *subtitleString = [NSString new];
    switch ([title.subscribers integerValue]) {
        case 1: {
            subtitleString = [NSString stringWithFormat:@"%@ Subscriber", title.subscribers];
            break;
        }
        default: {
            subtitleString = [NSString stringWithFormat:@"%@ Subscribers", title.subscribers];
            break;
        }
    }
    if (uppercase) {
        return subtitleString.uppercaseString;
    }
    return subtitleString;
}

// This is for the publisher list
+ (void)setPublisherCell:(LBXPullListTableViewCell *)cell withTitle:(LBXTitle *)title
{
    cell.titleLabel.text = title.name;
    
    NSString *subtitleString = [self getSubtitleStringWithTitle:title uppercase:YES];
    
    if (title.latestIssue != nil) {
        cell.subtitleLabel.text = subtitleString;
        
        // Get the image from the URL and set it
        [cell.latestIssueImageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:title.latestIssue.coverImage]] placeholderImage:[self getDefaultCoverImage] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
            
            [UIView transitionWithView:cell.imageView
                              duration:0.5f
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:^{[cell.latestIssueImageView setImage:image];}
                            completion:NULL];
            
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
            cell.latestIssueImageView.image = [self getDefaultCoverImage];
        }];
    }
    else if (!title.publisher.name) {
        cell.subtitleLabel.text = [[NSString stringWithFormat:@"Loading..."] uppercaseString];
        cell.latestIssueImageView.image = [self getDefaultCoverImage];
    }
    else if (title.latestIssue.title.issueCount == 0) {
        cell.latestIssueImageView.image = [self getDefaultCoverImage];
        cell.subtitleLabel.text = subtitleString;
    }
    else {
        cell.latestIssueImageView.image = [self getDefaultCoverImage];
        cell.subtitleLabel.text = subtitleString;
    }
}

// This is for the pull list
+ (void)setPullListCell:(LBXPullListTableViewCell *)cell
              withTitle:(LBXTitle *)title
{
    cell.titleLabel.text = title.name;
    if (title.latestIssue) {
        NSString *subtitleString = [NSString stringWithFormat:@"%@  •  %@", title.latestIssue.publisher.name, [LBXControllerServices timeSinceLastIssueForTitle:title]];
        
        cell.subtitleLabel.text = [subtitleString uppercaseString];
        
        // Get the image from the URL and set it
        [cell.latestIssueImageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:title.latestIssue.coverImage]] placeholderImage:[self getDefaultCoverImage] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
            
            [UIView transitionWithView:cell.imageView
                              duration:0.5f
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:^{[cell.latestIssueImageView setImage:image];}
                            completion:NULL];
            
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
            cell.latestIssueImageView.image = [self getDefaultCoverImage];
        }];
    }
    else if (!title.publisher.name) {
        cell.subtitleLabel.text = [[NSString stringWithFormat:@"Loading..."] uppercaseString];
        cell.latestIssueImageView.image = [self getDefaultCoverImage];
    }
    else if (!title.latestIssue) {
        cell.subtitleLabel.text = [[NSString stringWithFormat:@"%@", title.publisher.name] uppercaseString];
        cell.latestIssueImageView.image = [self getDefaultCoverImage];
    }
    else {
        cell.subtitleLabel.text = [[NSString stringWithFormat:@"%@", title.publisher.name] uppercaseString];
        cell.latestIssueImageView.image = [self getDefaultCoverImage];
    }
}

+ (void)darkenCell:(LBXPullListTableViewCell *)cell
{
    // Darken the image
    UIView *overlay = [[UIView alloc] initWithFrame:CGRectMake(0, 0, cell.latestIssueImageView.frame.size.width, cell.latestIssueImageView.frame.size.height*2)];
    [overlay setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.3]];
    [cell.latestIssueImageView addSubview:overlay];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
}

// This is for the adding to the pull list
+ (void)setAddToPullListSearchCell:(LBXPullListTableViewCell *)cell
                         withTitle:(LBXTitle *)title
                       darkenImage:(BOOL)darken
{
    cell.titleLabel.text = title.name;
    if (title.latestIssue) {
        NSString *subtitleString = [NSString stringWithFormat:@"%@  •  %@", title.latestIssue.publisher.name, [LBXControllerServices getSubtitleStringWithTitle:title uppercase:YES]];
        
        cell.subtitleLabel.text = [subtitleString uppercaseString];
        
        // Get the image from the URL and set it
        [cell.latestIssueImageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:title.latestIssue.coverImage]] placeholderImage:[self getDefaultCoverImage] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
            
            [UIView transitionWithView:cell.imageView
                              duration:0.5f
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:^{[cell.latestIssueImageView setImage:image];}
                            completion:NULL];
            
            if (darken) [self darkenCell:cell];
            
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
            cell.latestIssueImageView.image = [self getDefaultCoverImage];
            if (darken) [self darkenCell:cell];
        }];
    }
    else if (!title.publisher.name) {
        cell.subtitleLabel.text = [[NSString stringWithFormat:@"Loading..."] uppercaseString];
        cell.latestIssueImageView.image = [self getDefaultCoverImage];
    }
    else if (!title.latestIssue) {
        cell.subtitleLabel.text = [[NSString stringWithFormat:@"%@", title.publisher.name] uppercaseString];
        cell.latestIssueImageView.image = [self getDefaultCoverImage];
    }
    else {
        cell.subtitleLabel.text = [[NSString stringWithFormat:@"%@", title.publisher.name] uppercaseString];
        cell.latestIssueImageView.image = [self getDefaultCoverImage];
    }
    if (darken) [self darkenCell:cell];
}


// This is for the title view
+ (void)setTitleCell:(LBXPullListTableViewCell *)cell withIssue:(LBXIssue *)issue
{
    NSString *subtitleString = [NSString stringWithFormat:@"%@", [self localTimeZoneStringWithDate:issue.releaseDate]];
    
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"&#?[a-zA-Z0-9z]+;" options:NSRegularExpressionCaseInsensitive error:&error];
    NSString *modifiedTitleString = [regex stringByReplacingMatchesInString:issue.completeTitle options:0 range:NSMakeRange(0, [issue.completeTitle length]) withTemplate:@""];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(issueNumber == %@) AND (title == %@)", issue.issueNumber, issue.title];
    NSArray *initialFind = [LBXIssue MR_findAllSortedBy:@"releaseDate" ascending:NO withPredicate:predicate];
    
    cell.subtitleLabel.text = [NSString stringWithFormat:@"%@  •  %@ variant covers", subtitleString, [NSNumber numberWithLong:initialFind.count - 1]].uppercaseString;
    if (initialFind.count == 1) {
        cell.subtitleLabel.text = [NSString stringWithFormat:@"%@", subtitleString].uppercaseString;
    }
    else if (initialFind.count == 2) {
        cell.subtitleLabel.text = [NSString stringWithFormat:@"%@  •  %@ variant cover", subtitleString, [NSNumber numberWithLong:initialFind.count - 1]].uppercaseString;
    }
    
    cell.titleLabel.text = [NSString stringWithFormat:@"%@", modifiedTitleString];
    
    
    // For issues without a release date
    if ([subtitleString isEqualToString:@"(null)"]) {
        cell.subtitleLabel.text = @"Release Date Unknown";
    }
    
    // Get the image from the URL and set it
    [cell.latestIssueImageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:issue.coverImage]] placeholderImage:[self getDefaultCoverImage] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        
        [UIView transitionWithView:cell.imageView
                          duration:0.5f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{[cell.latestIssueImageView setImage:image];}
                        completion:NULL];
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        cell.latestIssueImageView.image = [self getDefaultCoverImage];
    }];
}

+ (void)setLabel:(UILabel *)textView
      withString:(NSString *)string
            font:(UIFont *)font
  inBoundsOfView:(UIView *)view
{
    textView.font = font;
    
    NSMutableParagraphStyle *textStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    textStyle.lineBreakMode = NSLineBreakByWordWrapping;
    textStyle.alignment = NSTextAlignmentCenter;
    
    NSDictionary *attributes = @{NSFontAttributeName:font, NSParagraphStyleAttributeName: textStyle};
    CGRect bound = [string boundingRectWithSize:CGSizeMake(view.bounds.size.width-30, view.bounds.size.height) options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:nil];
    
    textView.bounds = bound;
    textView.text = string;
    CGFloat width = [string sizeWithAttributes: @{NSFontAttributeName:font}].width;
    textView.numberOfLines = (width > textView.frame.size.width) ? 2 : 1;
    [textView sizeToFit];
}

+ (void)setNumberOfLinesWithLabel:(UILabel *)label
                           string:(NSString *)string
                             font:(UIFont *)font
{
    CGFloat width = [string sizeWithAttributes: @{NSFontAttributeName:font}].width;
    label.numberOfLines = (width > label.frame.size.width) ? 2 : 1;
    [label sizeToFit];
}

+ (void)setSearchBar:(UISearchBar *)searchBar withTextColor:(UIColor *)color
{
    // Set the placeholder text and magnifying glass color
    UIImage *image = [PaintCodeImages imageOfMagnifyingGlassWithColor:color width:24];
    [searchBar setImage:image forSearchBarIcon:UISearchBarIconSearch state:UIControlStateNormal];
    [[UILabel appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:color];
    
    // SearchBar cursor color
    searchBar.tintColor = color;
}

+ (UIImage *)generateImageForPublisher:(LBXPublisher *)publisher size:(CGSize)size
{
    // Set the background color to the gradient
    UIColor *primaryColor;
    if (publisher.primaryColor) {
        primaryColor = [UIColor colorWithHex:publisher.primaryColor];
    }
    else {
        primaryColor = [UIColor lightGrayColor];
    }
    
    UIColor *secondaryColor;
    if (publisher.secondaryColor) {
        secondaryColor = [UIColor colorWithHex:publisher.secondaryColor];
    }
    else {
        secondaryColor = [UIColor lightGrayColor];
    }
    
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    size_t gradientNumberOfLocations = 2;
    CGFloat gradientLocations[2] = { 0.0, 1.0 };
    CGFloat gradientComponents[8] = {CGColorGetComponents(primaryColor.CGColor)[0], CGColorGetComponents(primaryColor.CGColor)[1], CGColorGetComponents(primaryColor.CGColor)[2], 1.0,     // Start color
        CGColorGetComponents(secondaryColor.CGColor)[0], CGColorGetComponents(secondaryColor.CGColor)[1], CGColorGetComponents(secondaryColor.CGColor)[2], 1.0, };  // End color
    CGGradientRef gradient = CGGradientCreateWithColorComponents (colorspace, gradientComponents, gradientLocations, gradientNumberOfLocations);
    CGContextDrawLinearGradient(context, gradient, CGPointMake(0, 0), CGPointMake(0, size.height), 0);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (NSString *)getHashOfImage:(UIImage *)image
{
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    NSData *imageData = [NSData dataWithData:UIImagePNGRepresentation(image)];
    CC_MD5([imageData bytes], (uint)[imageData length], result);
    return [NSString stringWithFormat:
            @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

+ (NSArray *)getPublisherTableViewSectionArrayForArray:(NSArray *)array
{
    NSMutableArray *publishersArray = [NSMutableArray new];
    for (LBXIssue *issue in array) {
        if (![publishersArray containsObject:issue.publisher]) {
            [publishersArray addObject:issue.publisher];
        }
        
    }
    
    NSMutableArray *content = [NSMutableArray new];
    
    // Loop through every publisher
    for (int i = 0; i < [publishersArray count]; i++ ) {
        NSMutableDictionary *letterDict = [NSMutableDictionary new];
        NSMutableArray *letterArray = [NSMutableArray new];
        // Loop through every issue in the issues array
        for (LBXIssue *issue in array) {
            // Check if the issue name begins with the current character
            LBXPublisher *publisher = [publishersArray objectAtIndex:i];
            if ([publisher.name isEqualToString:issue.publisher.name]) {
                // If it does, append it to an array of all the titles
                // for that letter
                [letterArray addObject:issue];
            }
        }
        // Add the letter as the key and the title array as the value
        // and then make it a part of the larger content array
        if (letterArray.count) {
            LBXPublisher *publisher = [publishersArray objectAtIndex:i];
            [letterDict setValue:letterArray forKey:[NSString stringWithFormat:@"%@", publisher.name]];
            [content addObject:letterDict];
        }
    }
    return content;
}

+ (NSArray *)getBundleTableViewSectionArrayForArray:(NSArray *)array
{
    NSMutableArray *keyedBundleArray = [NSMutableArray new];
    for (NSArray *weekBundleArray in array) {
        if (weekBundleArray.count) {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"MMM dd, yyyy"];
            NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:weekBundleArray, [formatter stringFromDate:[self getThisWednesdayOfDate:((LBXIssue *)weekBundleArray[0]).releaseDate]], nil];
            [keyedBundleArray addObject:dict];
        }
    }
    return keyedBundleArray;
}

+ (NSArray *)getAlphabeticalTableViewSectionArrayForArray:(NSArray *)array
{
    static NSString *letters = @"ABCDEFGHIJKLMNOPQRSTUVWXYZ#";
    
    NSMutableArray *content = [NSMutableArray new];
    
    // Loop through every letter of the alphabet
    for (int i = 0; i < [letters length]; i++ ) {
        NSMutableDictionary *letterDict = [NSMutableDictionary new];
        NSMutableArray *letterArray = [NSMutableArray new];
        // Loop through every title in the publisher array
        for (LBXTitle *title in array) {
            // Check if the title name begins with the current character
            if (toupper([letters characterAtIndex:i]) == toupper([title.name characterAtIndex:0])) {
                // If it does, append it to an array of all the titles
                // for that letter
                [letterArray addObject:title];
            }
            if ([letters characterAtIndex:i] == '#' && isdigit([title.name characterAtIndex:0])) {
                [letterArray addObject:title];
            }
        }
        // Add the letter as the key and the title array as the value
        // and then make it a part of the larger content array
        if (letterArray.count) {
            [letterDict setValue:letterArray forKey:[NSString stringWithFormat:@"%c", [letters characterAtIndex:i]]];
            [content addObject:letterDict];
        }
    }
    return content;
}

+ (void)copyImageToPasteboard:(UIImage *)image
{
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    [pasteboard setImage:image];
    [SVProgressHUD setBackgroundColor:[UIColor whiteColor]];
    [SVProgressHUD setWidth:100 andHeight:100];
    [SVProgressHUD showSuccessWithStatus:@"Copied!"];
    [SVProgressHUD setWidth:400 andHeight:400];
}

+ (void)setViewWillAppearWhiteNavigationController:(UIViewController *)viewController
{
    viewController.navigationController.navigationBar.tintColor = [UIColor blackColor];
    [viewController.navigationController.navigationBar.backItem.backBarButtonItem setImageInsets:UIEdgeInsetsMake(40, 40, -40, 40)];
    [viewController.navigationController.navigationBar setBackIndicatorImage:
     [UIImage imageNamed:@"arrow"]];
    [viewController.navigationController.navigationBar setBackIndicatorTransitionMaskImage:
     [UIImage imageNamed:@"arrow"]];
    viewController.navigationController.navigationBar.backItem.title = @" ";
    viewController.navigationController.navigationBar.barStyle = UIBarStyleDefault;
    
    // Make the nav par translucent again
    if (viewController.isBeingPresented || viewController.isMovingToParentViewController) {
        viewController.navigationController.navigationBar.translucent = YES;
        viewController.navigationController.view.backgroundColor = [UIColor whiteColor];
        [viewController.navigationController.navigationBar setBackgroundImage:nil
                                                                forBarMetrics:UIBarMetricsDefault];
    }
}

+ (void)setViewDidAppearWhiteNavigationController:(UIViewController *)viewController
{
    [viewController.navigationController.navigationBar setBackgroundImage:nil
                                                  forBarMetrics:UIBarMetricsDefault];
    
    viewController.navigationController.navigationBar.translucent = YES;
    viewController.navigationController.view.backgroundColor = [UIColor whiteColor];
    viewController.navigationController.navigationBar.topItem.title = @" ";
    
   // viewController.navigationController.navigationBar.barStyle = UIBarStyleDefault;
    viewController.navigationController.navigationBar.shadowImage = nil;
    
    [viewController.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0], NSFontAttributeName : [UIFont navTitleFont]}];
}

+ (void)setViewWillAppearClearNavigationController:(UIViewController *)viewController
{
    
    [viewController.navigationController.navigationBar.backItem.backBarButtonItem setImageInsets:UIEdgeInsetsMake(40, 40, -40, 40)];
    [viewController.navigationController.navigationBar setBackIndicatorImage:
     [UIImage imageNamed:@"arrow"]];
    [viewController.navigationController.navigationBar setBackIndicatorTransitionMaskImage:
     [UIImage imageNamed:@"arrow"]];
    
    if (viewController.isBeingPresented || viewController.isMovingToParentViewController) {
        viewController.navigationController.navigationBar.tintColor = [UIColor whiteColor];
        viewController.navigationController.navigationBar.topItem.title = @" ";
        viewController.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
        [viewController.navigationController.navigationBar setBackgroundImage:[UIImage new]
                                                      forBarMetrics:UIBarMetricsDefault];
        viewController.navigationController.navigationBar.shadowImage = [UIImage new];
    }
//    viewController.navigationController.navigationBar.translucent = YES;
//    viewController.navigationController.view.backgroundColor = [UIColor clearColor];
//    [viewController.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0], NSFontAttributeName : [UIFont navTitleFont]}];
}

+ (void)setViewDidAppearClearNavigationController:(UIViewController *)viewController
{
    if (!viewController.isBeingPresented || !viewController.isMovingToParentViewController) {
        viewController.navigationController.navigationBar.tintColor = [UIColor whiteColor];
        viewController.navigationController.navigationBar.topItem.title = @" ";
        viewController.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
        [viewController.navigationController.navigationBar setBackgroundImage:[UIImage new]
                                                                forBarMetrics:UIBarMetricsDefault];
        viewController.navigationController.navigationBar.shadowImage = [UIImage new];
    }
}

@end
