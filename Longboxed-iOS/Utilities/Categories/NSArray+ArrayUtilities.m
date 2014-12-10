//
//  NSArray+ArrayUtilities.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 8/10/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "NSArray+ArrayUtilities.h"
#import "NSDate+DateUtilities.h"
#import "LBXIssue.h"
#import "LBXTitle.h"

@implementation NSArray (ArrayUtilities)

+ (NSArray *)sortedArray:(NSArray *)array basedOffObjectProperty:(NSString *)property
{
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [[NSSortDescriptor alloc] initWithKey:property
                                                 ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    return [array sortedArrayUsingDescriptors:sortDescriptors];
}

// For sorting the titles/issues in the releases view
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
        NSSortDescriptor *descr = [[NSSortDescriptor alloc] initWithKey:@"title.name" ascending:YES];
        NSArray *sortDescriptors = @[descr];
        for (LBXIssue *issue in [array sortedArrayUsingDescriptors:sortDescriptors]) {
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
            NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:weekBundleArray, [formatter stringFromDate:[NSDate getThisWednesdayOfDate:((LBXIssue *)weekBundleArray[0]).releaseDate]], nil];
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

@end
