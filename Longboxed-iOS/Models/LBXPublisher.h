//
//  LBXPublisher.h
//  Longboxed-iOS
//
//  Created by johnrhickey on 7/6/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RestKit/CoreData.h>

@interface LBXPublisher : NSManagedObject

@property (nonatomic, retain) NSNumber *publisherID;
@property (nonatomic, retain) NSNumber *issueCount;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSNumber *titleCount;
@property (nonatomic, retain) NSString *largeLogoBW;
@property (nonatomic, retain) NSString *mediumLogoBW;
@property (nonatomic, retain) NSString *smallLogoBW;
@property (nonatomic, retain) NSString *largeLogo;
@property (nonatomic, retain) NSString *mediumLogo;
@property (nonatomic, retain) NSString *smallLogo;
@property (nonatomic, retain) NSString *largeSplash;
@property (nonatomic, retain) NSString *mediumSplash;
@property (nonatomic, retain) NSString *smallSplash;
@property (nonatomic, retain) NSString *primaryColor;
@property (nonatomic, retain) NSString *secondaryColor;

@end
