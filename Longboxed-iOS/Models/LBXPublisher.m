//
//  LBXPublisher.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 7/6/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXPublisher.h"

@implementation LBXPublisher

@dynamic publisherID;
@dynamic issueCount;
@dynamic name;
@dynamic titleCount;
@dynamic largeLogoBW;
@dynamic mediumLogoBW;
@dynamic smallLogoBW;
@dynamic largeLogo;
@dynamic mediumLogo;
@dynamic smallLogo;
@dynamic largeSplash;
@dynamic mediumSplash;
@dynamic smallSplash;
@dynamic primaryColor;
@dynamic secondaryColor;

- (NSString *)description
{
    return [NSString stringWithFormat:@"Publisher: %@\nID: %@\ntitleCount: %@\nIssue Count: %@", self.name, self.publisherID, self.titleCount, self.issueCount];
}


@end
