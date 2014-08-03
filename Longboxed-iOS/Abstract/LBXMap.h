//
//  LBXMapper.h
//  Longboxed-iOS
//
//  Created by johnrhickey on 7/8/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RestKit.h>

@interface LBXMap : NSObject

@property (strong, nonatomic) RKManagedObjectStore *managedObjectStore;

- (RKEntityMapping *)bundleMapping;
- (RKEntityMapping *)userMapping;
- (RKEntityMapping *)titleMapping;
- (RKEntityMapping *)pullListMapping;
- (RKEntityMapping *)publisherMapping;
- (RKEntityMapping *)issueMapping;
- (RKEntityMapping *)paginationMapping;

@end
