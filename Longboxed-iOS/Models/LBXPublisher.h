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

@end
